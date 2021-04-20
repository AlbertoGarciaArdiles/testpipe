variable "app_name" {
  type = string
}

variable "repo_name" {
  type = string
}

variable "terraform_version" {
  type = string
}

variable "dev_account_id" {
  type = string
}

variable "hom_account_id" {
  type = string
}

variable "prod_account_id" {
  type = string
}

variable "codepipeline_role" {
  type = string
}

variable "cwe_role" {
  type = string
}

variable "codepipeline_artifacts_bucket" {
  type = string
}

variable "codebuild_project_name" {
  type = string
}

variable "artifacts_key_id" {
  type = string
}

variable "tf_locking_table" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}
