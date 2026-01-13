#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="devops-capstone-cicd-stack"
TEMPLATE_FILE="infra/00-pipeline/codepipeline-template.yml"
REGION="us-east-1"

# Ensure template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: Template file '$TEMPLATE_FILE' not found!"
  exit 1
fi

CODEPIPELINE_ROLE_ARN="arn:aws:iam::343437023511:role/codepipeline-service-role"
CLOUDFORMATION_EXEC_ROLE_ARN="arn:aws:iam::343437023511:role/cloudformation-service-role"
PIPELINE_BUCKET="sal-codebuild23"

GIT_CONNECTION_ARN="arn:aws:codeconnections:us-east-1:343437023511:connection/5ce5d9cf-5b56-4162-9b85-3a6be644b3bd"
GIT_FULL_REPO_ID="salorozco/devops-capstone"
GIT_BRANCH="main"

ECS_CLUSTER_NAME="devops-capstone-cluster"
FRONTEND_SERVICE_NAME="frontend-service"
BACKEND_SERVICE_NAME="backend-service"

# Replace with your actual subnet IDs and security group IDs
SUBNET_IDS="subnet-0a9b44affc4c6b24b,subnet-0ef030642df2209ef"
SECURITY_GROUP_IDS="sg-047652fe66d8e0b1f"

echo "Validating CloudFormation template: $TEMPLATE_FILE"
aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" --region "$REGION" > /dev/null

echo "Deploying stack..."
aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION" \
  --parameter-overrides \
      CodePipelineRoleArn="$CODEPIPELINE_ROLE_ARN" \
      PipelineBucket="$PIPELINE_BUCKET" \
      GitConnectionArn="$GIT_CONNECTION_ARN" \
      GitFullRepoId="$GIT_FULL_REPO_ID" \
      GitBranch="$GIT_BRANCH" \
      CloudFormationExecutionRoleArn="$CLOUDFORMATION_EXEC_ROLE_ARN" \
      EcsClusterName="$ECS_CLUSTER_NAME" \
      FrontendServiceName="$FRONTEND_SERVICE_NAME" \
      BackendServiceName="$BACKEND_SERVICE_NAME" \
      SubnetIds="$SUBNET_IDS" \
      SecurityGroupIds="$SECURITY_GROUP_IDS"

echo "Stack deployment finished. Outputs:"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table
