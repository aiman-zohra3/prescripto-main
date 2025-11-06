#!/bin/bash

# AWS Deployment Script for Prescripto
# Usage: ./deploy.sh <region> <aws-account-id>

set -e

REGION=${1:-us-east-1}
AWS_ACCOUNT_ID=${2}
IMAGE_TAG=${3:-latest}

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: AWS Account ID is required"
    echo "Usage: ./deploy.sh <region> <aws-account-id> [image-tag]"
    exit 1
fi

echo "🚀 Starting AWS Deployment..."
echo "Region: $REGION"
echo "Account ID: $AWS_ACCOUNT_ID"
echo "Image Tag: $IMAGE_TAG"

# ECR Repository names
BACKEND_REPO="prescripto-backend"
FRONTEND_REPO="prescripto-frontend"
ADMIN_REPO="prescripto-admin"

# Create ECR repositories if they don't exist
echo "📦 Creating ECR repositories..."
aws ecr describe-repositories --repository-names $BACKEND_REPO --region $REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $BACKEND_REPO --region $REGION

aws ecr describe-repositories --repository-names $FRONTEND_REPO --region $REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $FRONTEND_REPO --region $REGION

aws ecr describe-repositories --repository-names $ADMIN_REPO --region $REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $ADMIN_REPO --region $REGION

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push backend
echo "🏗️  Building and pushing backend..."
cd backend
docker build -t $BACKEND_REPO:$IMAGE_TAG .
docker tag $BACKEND_REPO:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$BACKEND_REPO:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$BACKEND_REPO:$IMAGE_TAG
cd ..

# Build and push frontend
echo "🏗️  Building and pushing frontend..."
cd clientside
docker build -t $FRONTEND_REPO:$IMAGE_TAG .
docker tag $FRONTEND_REPO:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$FRONTEND_REPO:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$FRONTEND_REPO:$IMAGE_TAG
cd ..

# Build and push admin
echo "🏗️  Building and pushing admin..."
cd admin
docker build -t $ADMIN_REPO:$IMAGE_TAG .
docker tag $ADMIN_REPO:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ADMIN_REPO:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ADMIN_REPO:$IMAGE_TAG
cd ..

echo "✅ Images pushed successfully!"

# Update task definitions
echo "📝 Updating task definitions..."
sed "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g; s/YOUR_REGION/$REGION/g" aws/ecs-task-definition-backend.json > /tmp/task-backend.json
sed "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g; s/YOUR_REGION/$REGION/g" aws/ecs-task-definition-frontend.json > /tmp/task-frontend.json

aws ecs register-task-definition --cli-input-json file:///tmp/task-backend.json --region $REGION
aws ecs register-task-definition --cli-input-json file:///tmp/task-frontend.json --region $REGION

echo "✅ Task definitions registered!"

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Create ECS cluster: aws ecs create-cluster --cluster-name prescripto-cluster --region $REGION"
echo "2. Create Application Load Balancer and target groups"
echo "3. Create ECS services using the task definitions"
echo "4. Set up secrets in AWS Secrets Manager"

