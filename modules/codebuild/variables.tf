variable "app_name" {
  type = string
}

variable "tf_locking_table" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "s3_logging_bucket_name" {
  type = string
}

variable "codepipeline_artifacts_bucket" {
  type = string
}

variable "codebuild_role" {
  type = string
}
