#!/usr/bin/env bash

set -e
#set -x # uncomment for debug

DEVTOOLS_ACCT="999248946243"
DEV_ACCT="100554757653"
HOM_ACCT="416653772306"
PROD_ACCT="123358174549"

function get_tf_backend() {
  local stack_name="${1}"
  local outputs="$(aws cloudformation describe-stacks --stack-name "${stack_name}" --query 'Stacks[0].Outputs')"
  state_bucket="$(echo $outputs | jq -r '.[] | select(.OutputKey=="StateBucket") | .OutputValue')"
  lock_table="$(echo $outputs | jq -r '.[] | select(.OutputKey=="TFRemoteLockTable") | .OutputValue')"
  artifact_bucket="$(echo $outputs | jq -r '.[] | select(.OutputKey=="PipelineArtifactsBucket") | .OutputValue')"
  log_bucket="$(echo $outputs | jq -r '.[] | select(.OutputKey=="LogBucket") | .OutputValue')"
  kms_arn="$(echo $outputs | jq -r '.[] | select(.OutputKey=="DeploymentKey") | .OutputValue')"
  kms_id="$(echo $outputs | jq -r '.[] | select(.OutputKey=="ArtifactsKeyId") | .OutputValue')"
  codebuild_role="$(echo $outputs | jq -r '.[] | select(.OutputKey=="CodebuildRole") | .OutputValue')"
  pipeline_role="$(echo $outputs | jq -r '.[] | select(.OutputKey=="CodepipelineRole") | .OutputValue')"
  cwe_role="$(echo $outputs | jq -r '.[] | select(.OutputKey=="CloudwatchEventRole") | .OutputValue')"
}

function tf_init() {
  local app_name="${1}"
  local devops_stack="${2}"
  local aws_region="${3}"
  local terraform_version="${4}"
  local dev_account_id="${5}"
  local hom_account_id="${6}"
  local prod_account_id="${7}"
  local repo_name="${8}"

  get_tf_backend $devops_stack
  terraform init \
    -input=false \
    -var "tf_state_bucket=${state_bucket}" \
    -var "tf_locking_table=${lock_table}" \
    -var "app_name=${app_name}" \
    -var "repo_name=${repo_name}" \
    -var "terraform_version=${terraform_version}" \
    -var "dev_account_id=${dev_account_id}" \
    -var "hom_account_id=${hom_account_id}" \
    -var "prod_account_id=${prod_account_id}" \
    -var "codebuild_role=${codebuild_role}" \
    -var "s3_logging_bucket_name=${log_bucket}" \
    -var "codepipeline_artifacts_bucket=${artifact_bucket}" \
    -backend-config="bucket=${state_bucket}" \
    -backend-config="key=prereq-pipelines/${app_name}" \
    -backend-config="region=${aws_region}" \
    -backend-config="dynamodb_table=${lock_table}"
}

function tf_plan() {
  local app_name="${1}"
  local devops_stack="${2}"
  local aws_region="${3}"
  local terraform_version="${4}"
  local dev_account_id="${5}"
  local hom_account_id="${6}"
  local prod_account_id="${7}"
  local repo_name="${8}"

  get_tf_backend $devops_stack

  terraform plan \
    -input=false \
    -var "tf_state_bucket=${state_bucket}" \
    -var "tf_locking_table=${lock_table}" \
    -var "app_name=${app_name}" \
    -var "repo_name=${repo_name}" \
    -var "terraform_version=${terraform_version}" \
    -var "dev_account_id=${dev_account_id}" \
    -var "hom_account_id=${hom_account_id}" \
    -var "prod_account_id=${prod_account_id}" \
    -var "codebuild_role=${codebuild_role}" \
    -var "s3_logging_bucket_name=${log_bucket}" \
    -var "codepipeline_artifacts_bucket=${artifact_bucket}" \
    -var "codepipeline_role=${pipeline_role}" \
    -var "artifacts_key_id=${kms_id}" \
    -var "cwe_role=${cwe_role}" \
    -out "pipeline.tfplan"
}

function tf_apply() {
  local app_name="${1}"
  local devops_stack="${2}"
  local aws_region="${3}"
  
  get_tf_backend $devops_stack

  terraform apply \
    -input=false \
    pipeline.tfplan
}

tf_init "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}"
tf_plan "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}"
tf_apply "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}"
