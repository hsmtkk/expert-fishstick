terraform {
  backend "s3" {
    bucket = "expert-fishstick"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "project" = var.project
    }
  }
}

resource "aws_dynamodb_table" "dynamodb" {
  attribute {
    name = "id"
    type = "N"
  }
  hash_key = "id"
  name = "${var.project}-dynamodb"
  read_capacity = 1
  write_capacity = 1
}

resource "aws_apprunner_service" "apprunner" {
  service_name = "${var.project}-apprunner"
  source_configuration {
    code_repository {
      code_configuration {
        configuration_source = "REPOSITORY"
      }
      repository_url = "https://github.com/hsmtkk/expert-fishstick.git"
    }
  }
}