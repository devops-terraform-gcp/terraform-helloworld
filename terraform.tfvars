# project  = "cellular-dream-342220"
project  = "terraform-env-100"
image    = "gcr.io/terraform-env-100/app"
region   = "us-east4"
location = "us-east4"
zone     = "us-east4-a"
name     = "Terraform Project"
gcp_service_list = [
  "iam.googleapis.com",
  "containerregistry.googleapis.com",
  "artifactregistry.googleapis.com",
  "compute.googleapis.com",
  "run.googleapis.com"
]