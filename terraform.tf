terraform {
  backend "gcs" {
    bucket = "expert-fishstick-tfstate"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_project_service" "service" {
  for_each = toset(var.apis)
  service  = "${each.key}.googleapis.com"
}

data "archive_file" "back" {
  source_dir  = "back"
  output_path = "tmp/back.zip"
  type        = "zip"
}

resource "random_pet" "back" {}

resource "google_storage_bucket" "back" {
  force_destroy = true
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 1
    }
  }
  location = var.region
  name     = "back-${random_pet.back.id}"
}



resource "google_storage_bucket_object" "back" {
  bucket = google_storage_bucket.back.name
  name   = data.archive_file.back.output_md5
  source = data.archive_file.back.output_path
}

resource "google_service_account" "back" {
  account_id = "back-runner"
}

resource "google_cloudfunctions2_function" "back" {
  build_config {
    entry_point = "EntryPoint"
    runtime     = "go120"
    source {
      storage_source {
        bucket = google_storage_bucket.back.name
        object = google_storage_bucket_object.back.name
      }
    }
  }
  location = var.region
  name     = "back"
  service_config {
    service_account_email = google_service_account.back.email
  }
}

resource "google_artifact_registry_repository" "registry" {
  format        = "DOCKER"
  repository_id = "registry"
}

resource "google_service_account" "front" {
  account_id = "front-runner"
}

resource "google_cloud_run_v2_service" "front" {
  location = var.region
  name     = "front"
  template {
    containers {
      env {
        name  = "BACK_URL"
        value = google_cloudfunctions2_function.back.service_config[0].uri
      }
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
    service_account = google_service_account.front.email
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_v2_service.front.location
  project     = google_cloud_run_v2_service.front.project
  service     = google_cloud_run_v2_service.front.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloudbuild_trigger" "build" {
  filename = "cloudbuild.yaml"
  github {
    owner = "hsmtkk"
    name  = var.project
    push {
      branch = "main"
    }
  }
}

output "front_uri" {
  value = google_cloud_run_v2_service.front.uri
}