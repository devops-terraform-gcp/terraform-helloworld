data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

resource "google_project" "my_project" {
  name            = var.name
  project_id      = "${var.project}-${random_id.unique.hex}"
  billing_account = data.google_billing_account.acct.id
}

resource "google_project_service" "gcp_services" {
  count                      = length(var.gcp_service_list)
  project                    = "${var.project}-${random_id.unique.hex}"
  service                    = var.gcp_service_list[count.index]
  disable_dependent_services = true
}

resource "terraform_data" "run_script" {
  provisioner "local-exec" {
    command = "/bin/bash docker-build.sh"
    environment = {
      "env" = "${random_id.unique.hex}"
    }
  }
  depends_on = [
    google_project_service.gcp_services
  ]
}

resource "random_id" "unique" {
  byte_length = 3
}

# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
  depends_on         = [terraform_data.run_script]
}

resource "google_cloud_run_service" "webapp" {
  name     = "${var.project}-${random_id.unique.hex}"
  location = var.location

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}-${random_id.unique.hex}/app"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.run_api]
}

# Allow unauthenticated users to invoke the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.webapp.name
  location = google_cloud_run_service.webapp.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project  = google_cloud_run_service.webapp.project
}

resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "Terraform Alert New Policy"
  combiner     = "OR"
  conditions {
    display_name = "test new condition"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/disk/write_bytes_count\" AND resource.type=\"gce_instance\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  user_labels = {
    foo = "bar"
  }
}


resource "google_monitoring_uptime_check_config" "https" {
  display_name = "Terraform New Uptime Check"
  timeout      = "60s"

  http_check { #/terraform-env-100/app
    path         = "/${var.project}-${random_id.unique.hex}/app"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "${var.project}-${random_id.unique.hex}"
      host       = "gcr.io"
    }
  }

  content_matchers {
    content = "example"
  }
}

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "Demo Dashboard",
  "gridLayout": {
    "widgets": [
      {
        "blank": {}
      }
    ]
  }
}

EOF
}

output "url" {
  value = google_cloud_run_service.webapp.status[0].url
}
