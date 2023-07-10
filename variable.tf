variable "region" {
  type    = string
  default = "us-central1"
}

variable "project" {
  type    = string
  default = "expert-fishstick"
}

variable "apis" {
  type    = list(string)
  default = ["artifactregistry", "cloudbuild", "cloudfunctions", "firestore", "run"]
}