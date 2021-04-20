#!/usr/bin/env bash

set -e
set -x # uncomment this line for more debug

function create_state_bucket() {
  local bucket_name="${1}"
  local bucket_region="${2}"

  # Create bucket
  if [[ "${bucket_region}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${bucket_name}"
  else
    aws s3api create-bucket \
      --bucket "${bucket_name}" \
      --create-bucket-configuration LocationConstraint="${bucket_region}"
  fi

  # Enable Versioning
  aws s3api put-bucket-versioning \
    --bucket "${bucket_name}" \
    --versioning-configuration Status=Enabled

  # Add default encryption
  aws s3api put-bucket-encryption \
    --bucket "${bucket_name}" \
    --server-side-encryption-configuration \
      '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
}

function create_locking_table() {
  local table_name="${1}"
  aws dynamodb create-table \
    --attribute-definitions \
    --table-name "${table_name}" \
    --billing-mode "PAY_PER_REQUEST" \
    --attribute-definitions "AttributeName=LockID,AttributeType=S" \
    --key-schema "AttributeName=LockID,KeyType=HASH"
}

create_state_bucket 'ops-tf-poc' 'sa-east-1'
#create_locking_table "TerraformLocks"
