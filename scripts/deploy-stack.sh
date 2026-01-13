#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"

IAM_STACK="devops-capstone-iam"
IAM_TEMPLATE="infra/99-iam/iam-roles-template.yml"

PIPELINE_STACK="devops-capstone-cicd-stack"
PIPELINE_TEMPLATE="infra/00-pipeline/codepipeline-template.yml"

# --- inputs you already know ---
PIPELINE_BUCKET="sal-codebuild23"
GIT_CONNECTION_ARN="arn:aws:codeconnections:us-east-1:343437023511:connection/1cf2f931-6dfe-48f5-acf3-83556f3fca1b"
GIT_FULL_REPO_ID="salorozco/devops-capstone"
GIT_BRANCH="main"

ECS_CLUSTER_NAME="devops-capstone-cluster"
FRONTEND_SERVICE_NAME="frontend-service"
BACKEND_SERVICE_NAME="backend-service"

SUBNET_IDS="subnet-0a9b44affc4c6b24b,subnet-0ef030642df2209ef"
SECURITY_GROUP_IDS="sg-047652fe66d8e0b1f"

# --- sanity checks ---
[[ -f "$IAM_TEMPLATE" ]] || { echo "Missing $IAM_TEMPLATE"; exit 1; }
[[ -f "$PIPELINE_TEMPLATE" ]] || { echo "Missing $PIPELINE_TEMPLATE"; exit 1; }

echo "Validating templates..."
aws cloudformation validate-template --template-body "file://$IAM_TEMPLATE" --region "$REGION" > /dev/null
aws cloudformation validate-template --template-body "file://$PIPELINE_TEMPLATE" --region "$REGION" > /dev/null

# --- 1) deploy IAM bootstrap ---
echo "Deploying IAM stack: $IAM_STACK"
aws cloudformation deploy \
  --stack-name "$IAM_STACK" \
  --template-file "$IAM_TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION"

# --- 2) read IAM outputs ---
echo "Reading IAM outputs..."
CODEPIPELINE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name "$IAM_STACK" --region "$REGION" --query "Stacks[0].Outputs[?OutputKey=='CodePipelineRoleArn'].OutputValue" --output text)"
CODEBUILD_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name "$IAM_STACK" --region "$REGION" --query "Stacks[0].Outputs[?OutputKey=='CodeBuildRoleArn'].OutputValue" --output text)"
CLOUDFORMATION_EXEC_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name "$IAM_STACK" --region "$REGION" --query "Stacks[0].Outputs[?OutputKey=='CloudFormationExecutionRoleArn'].OutputValue" --output text)"
ECS_TASK_EXEC_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name "$IAM_STACK" --region "$REGION" --query "Stacks[0].Outputs[?OutputKey=='EcsTaskExecutionRoleArn'].OutputValue" --output text)"

echo "CodePipelineRoleArn: $CODEPIPELINE_ROLE_ARN"
echo "CodeBuildRoleArn: $CODEBUILD_ROLE_ARN"
echo "CloudFormationExecutionRoleArn: $CLOUDFORMATION_EXEC_ROLE_ARN"
echo "EcsTaskExecutionRoleArn: $ECS_TASK_EXEC_ROLE_ARN"

# --- 3) deploy pipeline stack ---
echo "Deploying pipeline stack: $PIPELINE_STACK"
aws cloudformation deploy \
  --stack-name "$PIPELINE_STACK" \
  --template-file "$PIPELINE_TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION" \
  --parameter-overrides \
      CodePipelineRoleArn="$CODEPIPELINE_ROLE_ARN" \
      PipelineBucket="$PIPELINE_BUCKET" \
      GitConnectionArn="$GIT_CONNECTION_ARN" \
      GitFullRepoId="$GIT_FULL_REPO_ID" \
      GitBranch="$GIT_BRANCH" \
      CloudFormationExecutionRoleArn="$CLOUDFORMATION_EXEC_ROLE_ARN" \
      CodeBuildServiceRoleArn="$CODEBUILD_ROLE_ARN" \
      EcsClusterName="$ECS_CLUSTER_NAME" \
      FrontendServiceName="$FRONTEND_SERVICE_NAME" \
      BackendServiceName="$BACKEND_SERVICE_NAME" \
      SubnetIds="$SUBNET_IDS" \
      SecurityGroupIds="$SECURITY_GROUP_IDS"

echo "Done. Pipeline stack outputs:"
aws cloudformation describe-stacks \
  --stack-name "$PIPELINE_STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table
