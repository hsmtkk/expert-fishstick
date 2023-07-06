terraform {
    backend "s3" {
      bucket = "expert-fishstick"
      key = "terraform.tfstate"
      region = "ap-northeast-1"
    }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = var.region
  default_tags {
    tags = {
      "project" = var.project
    }
  }
}
