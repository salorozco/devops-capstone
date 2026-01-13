#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-us-east-1}"

PIPELINE_STACK="${2:-devops-capstone-cicd-stack}"
CODEBUILD_STACK="${3:-devops-capstone-codebuild-stack}"
ECS_STACK="${4:-devops-capstone-ecs-stack}"
IAM_STACK="${5:-devops-capstone-iam}"

# WARNING: only empty this if it's a dedicated lab bucket
PIPELINE_BUCKET="${6:-sal-codebuild23}"

echo "Region: $REGION"
echo "IAM stack: $IAM_STACK"
echo "ECS stack: $ECS_STACK"
echo "CodeBuild stack: $CODEBUILD_STACK"
echo "Pipeline stack: $PIPELINE_STACK"
echo "Artifacts bucket: $PIPELINE_BUCKET"
echo

echo "== Delete Pipeline stack (stop future runs) =="
aws cloudformation delete-stack --stack-name "$PIPELINE_STACK" --region "$REGION" || true
aws cloudformation wait stack-delete-complete --stack-name "$PIPELINE_STACK" --region "$REGION" || true
echo

echo "== Delete ECS stack =="
aws cloudformation delete-stack --stack-name "$ECS_STACK" --region "$REGION" || true
aws cloudformation wait stack-delete-complete --stack-name "$ECS_STACK" --region "$REGION" || true
echo

echo "== Delete CodeBuild stack =="
aws cloudformation delete-stack --stack-name "$CODEBUILD_STACK" --region "$REGION" || true
aws cloudformation wait stack-delete-complete --stack-name "$CODEBUILD_STACK" --region "$REGION" || true
echo

echo "== Clean ECR images (so repo deletion won't fail) =="
for REPO in devops-capstone-frontend devops-capstone-backend; do
  if aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1; then
    echo "Cleaning repo: $REPO"
    IDS=$(aws ecr list-images --repository-name "$REPO" --region "$REGION" --query 'imageIds[*]' --output json)
    if [[ "$IDS" != "[]" ]]; then
      aws ecr batch-delete-image --repository-name "$REPO" --region "$REGION" --image-ids "$IDS" >/dev/null || true
    fi

    echo "Deleting repo: $REPO"
    aws ecr delete-repository --repository-name "$REPO" --force --region "$REGION" || true
  else
    echo "Repo not found (ok): $REPO"
  fi
done
echo

echo "== Empty pipeline artifact bucket (only if dedicated) =="
if aws s3api head-bucket --bucket "$PIPELINE_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  aws s3 rm "s3://$PIPELINE_BUCKET" --recursive --region "$REGION" || true
else
  echo "Bucket not found (ok): $PIPELINE_BUCKET"
fi
echo

echo "== Delete IAM stack (roles/policies) =="
aws cloudformation delete-stack --stack-name "$IAM_STACK" --region "$REGION" || true
aws cloudformation wait stack-delete-complete --stack-name "$IAM_STACK" --region "$REGION" || true
echo

echo "All stacks deleted."
