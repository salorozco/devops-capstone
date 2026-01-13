#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?missing AWS_REGION}"
: "${ECS_CLUSTER:?missing ECS_CLUSTER}"
: "${BACKEND_SERVICE:?missing BACKEND_SERVICE}"
: "${FRONTEND_SERVICE:?missing FRONTEND_SERVICE}"

aws ecs update-service --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --service "$BACKEND_SERVICE" \
  --desired-count 1

aws ecs update-service --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --service "$FRONTEND_SERVICE" \
  --desired-count 1
