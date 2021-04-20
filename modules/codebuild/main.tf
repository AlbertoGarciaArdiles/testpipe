provider "aws" {
  version = "~> 3.0"
}

data "aws_s3_bucket" "logging_bucket" {
  bucket = var.s3_logging_bucket_name
}

data "aws_iam_role" "codebuild" {
  name = var.codebuild_role
}

resource "aws_codebuild_project" "build_project" {
  name = var.app_name
  service_role = data.aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.app_name}/codebuild"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${data.aws_s3_bucket.logging_bucket.id}/${var.app_name}/codebuild"
    }
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image = "aws/codebuild/standard:5.0"
    type = "LINUX_CONTAINER"

    environment_variable {
      name = "TF_IN_AUTOMATION"
      value = "yes"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
output "codebuild_project" {
  value = aws_codebuild_project.build_project
}
