terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "google" {
  project = "${var.project}-${random_id.unique.hex}"
  region  = var.region
  zone    = var.zone
}
