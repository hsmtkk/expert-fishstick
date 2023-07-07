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

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_codebuild_project" "codebuild" {
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"
  }
  name         = "${var.project}-codebuild"
  service_role = aws_iam_role.codebuild.arn
  source {
    type     = "GITHUB"
    location = "https://github.com/hsmtkk/expert-fishstick.git"
  }
}

resource "aws_codebuild_webhook" "codebuild" {
  project_name = aws_codebuild_project.codebuild.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
    filter {
      type    = "BASE_REF"
      pattern = "master"
    }
  }
}

resource "aws_dynamodb_table" "dynamodb" {
  name           = "${var.project}-dynamodb"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"
  attribute {
    name = "id"
    type = "N"
  }
}


data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

data "archive_file" "lambda" {
  output_path = "tmp/lambda.zip"
  source_dir  = "lambda-dummy"
  type        = "zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.lambda.output_path
  function_name = "${var.project}-lambda"
  handler       = data.archive_file.lambda.source_dir
  role          = aws_iam_role.lambda.arn
  runtime       = "go1.x"
}

resource "aws_ecr_repository" "registry" {
  name = "${var.project}-registry"
}

data "aws_iam_policy_document" "apprunner" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com", "tasks.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apprunner" {
  name               = "${var.project}-apprunner"
  assume_role_policy = data.aws_iam_policy_document.apprunner.json
}

resource "aws_iam_role_policy_attachment" "apprunner" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
  role       = aws_iam_role.apprunner.name
}

resource "aws_apprunner_service" "apprunner" {
  service_name = "${var.project}-apprunner"
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner.arn
    }
    auto_deployments_enabled = true
    image_repository {
      image_identifier      = "${aws_ecr_repository.registry.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }
}

/*
resource "aws_codebuild_project" "build" {
  name         = "build"
  service_role = ""
}
*/