terraform {
  required_version = ">= 0.13.2"

  backend "s3" {}
}

provider "aws" {
  version = ">= 3.0"
}

data "aws_caller_identity" "current" {}

module "codebuild" {
  source = "./modules/codebuild"

  app_name = var.app_name
  codebuild_role = var.codebuild_role
  codepipeline_artifacts_bucket = var.codepipeline_artifacts_bucket
  s3_logging_bucket_name = var.s3_logging_bucket_name
  tf_locking_table = var.tf_locking_table
  tf_state_bucket = var.tf_state_bucket
}

module "codepipeline" {
  source = "./modules/codepipeline"
  
  app_name = var.app_name
  repo_name = var.repo_name
  terraform_version = var.terraform_version
  dev_account_id = var.dev_account_id
  hom_account_id = var.hom_account_id
  prod_account_id = var.prod_account_id
  artifacts_key_id = var.artifacts_key_id
  codepipeline_role = var.codepipeline_role
  cwe_role = var.cwe_role
  codebuild_project_name = module.codebuild.codebuild_project.name
  codepipeline_artifacts_bucket = var.codepipeline_artifacts_bucket
  tf_locking_table = var.tf_locking_table
  tf_state_bucket = var.tf_state_bucket
}
