data "aws_iam_role" "codepipeline" {
  name = var.codepipeline_role
}

data "aws_kms_key" "artifacts_key" {
  key_id = var.artifacts_key_id
}

data "aws_iam_role" "cwe" {
  name = var.cwe_role
}

resource "aws_codecommit_repository" "infrastructure_repo" {
  repository_name = var.repo_name
  description     = "A mirror repository for the Gitlab Repo of the same name"

  tags = {
    Application = var.repo_name
  }
}

resource "aws_codepipeline" "tf_pipeline" {
  name = "${var.app_name}-app-infra-pipeline"
  role_arn = data.aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.codepipeline_artifacts_bucket
    type = "S3"
    encryption_key {
      id = data.aws_kms_key.artifacts_key.key_id
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      category = "Source"
      name = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["SourceCode"]
      configuration = {
        PollForSourceChanges = false
        RepositoryName = aws_codecommit_repository.infrastructure_repo.repository_name
        BranchName = "master"
      }
    }
  }

  stage {
    name = "DeployDev-Plan"

    action {
      name             = "DeployDev-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceCode"]
      output_artifacts = ["DevPlan"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },          
          {
            name = "TF_ACTION"
            value = "plan"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "dev"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.dev_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }

  stage {
    name = "DeployDev-Apply"

    action {
      name             = "DeployDev-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceCode"]
      output_artifacts = ["DevApply"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },          
          {
            name = "TF_ACTION"
            value = "apply"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "dev"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.dev_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }

  stage {
    name = "ManualApprovalForHom-Plan"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "DeployHom-Plan"

    action {
      name             = "DeployHom-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["DevApply"]
      output_artifacts = ["HomPlan"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },          
          {
            name = "TF_ACTION"
            value = "plan"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "hom"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.hom_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }

  stage {
    name = "ManualApprovalForHom-Apply"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "DeployHom-Apply"

    action {
      name             = "DeployHom-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["HomPlan"]
      output_artifacts = ["HomApply"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },          
          {
            name = "TF_ACTION"
            value = "apply"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "hom"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.hom_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }

  stage {
    name = "ManualApprovalForProd-Plan"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "DeployProd-Plan"

    action {
      name             = "DeployProd-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["HomApply"]
      output_artifacts = ["ProdPlan"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },
          {
            name = "TF_ACTION"
            value = "plan"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "prod"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.prod_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }

  stage {
    name = "ManualApprovalForProd-Apply"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "DeployProd-Apply"

    action {
      name             = "DeployProd-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["ProdPlan"]
      output_artifacts = ["ProdApply"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
        EnvironmentVariables = jsonencode([
          {
            name = "APP_NAME"
            value = var.app_name
          },
          {
            name = "TF_ACTION"
            value = "apply"
          },
          {
            name = "TF_VERSION"
            value = var.terraform_version
          },
          {
            name = "ENV_NAME"
            value = "prod"
          },
          {
            name = "DEST_ACCOUNT"
            value = var.prod_account_id
          },
          {
            name = "TF_BACKEND_REGION"
            value = "sa-east-1"
          },
          {
            name = "TF_LOCKING_TABLE"
            value = var.tf_locking_table
          },
          {
            name = "TF_STATE_BUCKET"
            value =  var.tf_state_bucket
          }
        ])
      }
    }
  }
}


resource "aws_cloudwatch_event_rule" "source_changed_rule" {
  name_prefix = var.app_name
  event_pattern = <<EOF
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.infrastructure_repo.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "master"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "cwe_pipeline_target" {
  arn = aws_codepipeline.tf_pipeline.arn
  rule = aws_cloudwatch_event_rule.source_changed_rule.name
  role_arn = data.aws_iam_role.cwe.arn
}
