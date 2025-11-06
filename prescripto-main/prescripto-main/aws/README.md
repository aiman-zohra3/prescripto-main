# AWS Deployment Guide for Prescripto

This guide will help you deploy the Prescripto application to AWS using ECS (Elastic Container Service) with Fargate.

## Prerequisites

1. **AWS CLI** installed and configured
   ```bash
   aws --version
   aws configure
   ```

2. **Docker** installed and running
   ```bash
   docker --version
   ```

3. **AWS Account** with appropriate permissions:
   - ECS (Elastic Container Service)
   - ECR (Elastic Container Registry)
   - VPC and Networking
   - Application Load Balancer
   - Secrets Manager
   - CloudWatch Logs
   - IAM

4. **MongoDB Atlas** account (or MongoDB instance)
   - You're already using MongoDB Atlas, so make sure you have the connection string

## Architecture

- **Backend**: Node.js/Express API running on ECS Fargate
- **Frontend**: React app served via Nginx on ECS Fargate
- **Admin**: React admin panel (optional, can be deployed similarly)
- **MongoDB**: Using MongoDB Atlas (cloud)
- **Load Balancer**: Application Load Balancer for routing traffic
- **Secrets**: AWS Secrets Manager for sensitive configuration

## Quick Start

### Option 1: Using Deployment Scripts (Recommended)

#### For Linux/Mac:
```bash
chmod +x aws/deploy.sh
./aws/deploy.sh us-east-1 YOUR_AWS_ACCOUNT_ID
```

#### For Windows PowerShell:
```powershell
.\aws\deploy.ps1 -Region us-east-1 -AwsAccountId YOUR_AWS_ACCOUNT_ID
```

### Option 2: Manual Deployment

#### Step 1: Create ECR Repositories

```bash
# Set your variables
REGION=us-east-1
AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID

# Create repositories
aws ecr create-repository --repository-name prescripto-backend --region $REGION
aws ecr create-repository --repository-name prescripto-frontend --region $REGION
aws ecr create-repository --repository-name prescripto-admin --region $REGION
```

#### Step 2: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push backend
cd backend
docker build -t prescripto-backend .
docker tag prescripto-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prescripto-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prescripto-backend:latest
cd ..

# Build and push frontend
cd clientside
docker build -t prescripto-frontend .
docker tag prescripto-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prescripto-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prescripto-frontend:latest
cd ..
```

#### Step 3: Store Secrets in AWS Secrets Manager

```bash
# MongoDB URI
aws secretsmanager create-secret \
  --name prescripto/mongodb-uri \
  --secret-string "mongodb+srv://username:password@cluster.mongodb.net/prescripto" \
  --region $REGION

# Cloudinary credentials (if using)
aws secretsmanager create-secret \
  --name prescripto/cloudinary-cloud-name \
  --secret-string "your-cloud-name" \
  --region $REGION

aws secretsmanager create-secret \
  --name prescripto/cloudinary-api-key \
  --secret-string "your-api-key" \
  --region $REGION

aws secretsmanager create-secret \
  --name prescripto/cloudinary-api-secret \
  --secret-string "your-api-secret" \
  --region $REGION

# JWT Secret
aws secretsmanager create-secret \
  --name prescripto/jwt-secret \
  --secret-string "your-jwt-secret-key" \
  --region $REGION
```

#### Step 4: Update Task Definitions

Edit the task definition files and replace:
- `YOUR_AWS_ACCOUNT_ID` with your AWS account ID
- `YOUR_REGION` with your AWS region

Then register the task definitions:

```bash
aws ecs register-task-definition \
  --cli-input-json file://aws/ecs-task-definition-backend.json \
  --region $REGION

aws ecs register-task-definition \
  --cli-input-json file://aws/ecs-task-definition-frontend.json \
  --region $REGION
```

#### Step 5: Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name prescripto-cluster \
  --region $REGION
```

#### Step 6: Deploy Using CloudFormation (Recommended)

Create a parameters file `aws/parameters.json`:

```json
[
  {
    "ParameterKey": "AwsAccountId",
    "ParameterValue": "YOUR_AWS_ACCOUNT_ID"
  },
  {
    "ParameterKey": "Region",
    "ParameterValue": "us-east-1"
  },
  {
    "ParameterKey": "VpcId",
    "ParameterValue": "vpc-xxxxxxxx"
  },
  {
    "ParameterKey": "SubnetIds",
    "ParameterValue": "subnet-xxxxxx,subnet-yyyyyy"
  },
  {
    "ParameterKey": "MongoDBUri",
    "ParameterValue": "mongodb+srv://..."
  },
  {
    "ParameterKey": "CloudinaryCloudName",
    "ParameterValue": "your-cloud-name"
  },
  {
    "ParameterKey": "CloudinaryApiKey",
    "ParameterValue": "your-api-key"
  },
  {
    "ParameterKey": "CloudinaryApiSecret",
    "ParameterValue": "your-api-secret"
  },
  {
    "ParameterKey": "JwtSecret",
    "ParameterValue": "your-jwt-secret"
  }
]
```

Deploy the stack:

```bash
aws cloudformation create-stack \
  --stack-name prescripto-stack \
  --template-body file://aws/cloudformation-template.yaml \
  --parameters file://aws/parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION
```

### Option 3: Using AWS Console

1. **Create ECR Repositories**
   - Go to ECR → Create repository
   - Create: `prescripto-backend`, `prescripto-frontend`, `prescripto-admin`

2. **Push Images**
   - Follow the push commands shown in ECR repository

3. **Create Secrets**
   - Go to Secrets Manager → Store a new secret
   - Create secrets for: MongoDB URI, Cloudinary credentials, JWT secret

4. **Create ECS Cluster**
   - Go to ECS → Clusters → Create cluster
   - Choose Fargate, name it `prescripto-cluster`

5. **Create Task Definitions**
   - Go to ECS → Task definitions → Create new
   - Use the JSON files in `aws/` directory as reference
   - Update image URIs and secrets ARNs

6. **Create Services**
   - In your cluster, create services
   - Select your task definitions
   - Configure load balancer (create ALB if needed)

## Configuration

### Environment Variables

The backend requires these environment variables (stored in Secrets Manager):

- `MONGODB_URI`: MongoDB connection string
- `CLOUDINARY_CLOUD_NAME`: Cloudinary cloud name
- `CLOUDINARY_API_KEY`: Cloudinary API key
- `CLOUDINARY_API_SECRET`: Cloudinary API secret
- `JWT_SECRET`: Secret key for JWT tokens

### Ports

- **Backend**: 4000 (internal), exposed via ALB
- **Frontend**: 80 (Nginx), exposed via ALB
- **Load Balancer**: 80 (HTTP), 443 (HTTPS - configure SSL certificate)

### MongoDB Atlas Configuration

1. Go to MongoDB Atlas → Network Access
2. Add AWS IP ranges or allow access from anywhere (0.0.0.0/0) for testing
3. Use the connection string in Secrets Manager

## Cost Estimation

Approximate monthly costs (varies by region and usage):

- **ECS Fargate**: ~$30-50 (2 tasks × $0.04/hour × 730 hours)
- **Application Load Balancer**: ~$16-20/month
- **ECR**: ~$0.10/month per GB stored
- **CloudWatch Logs**: ~$0.50/month (7-day retention)
- **Secrets Manager**: ~$0.40/month per secret
- **Data Transfer**: Variable

**Total**: ~$50-80/month for basic setup

## Scaling

### Manual Scaling

```bash
aws ecs update-service \
  --cluster prescripto-cluster \
  --service prescripto-backend-service \
  --desired-count 4 \
  --region $REGION
```

### Auto Scaling

Create auto-scaling configuration:

```bash
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/prescripto-cluster/prescripto-backend-service \
  --min-capacity 2 \
  --max-capacity 10 \
  --region $REGION
```

## Monitoring

- **CloudWatch Logs**: View logs for each service
- **ECS Service Metrics**: CPU, memory usage
- **ALB Metrics**: Request count, response times

## Troubleshooting

### Check service status
```bash
aws ecs describe-services \
  --cluster prescripto-cluster \
  --services prescripto-backend-service \
  --region $REGION
```

### View logs
```bash
aws logs tail /ecs/prescripto-backend --follow --region $REGION
```

### Check task status
```bash
aws ecs list-tasks \
  --cluster prescripto-cluster \
  --service-name prescripto-backend-service \
  --region $REGION
```

### Common Issues

1. **Tasks not starting**: Check security groups, subnets, and IAM roles
2. **Cannot connect to MongoDB**: Verify network access in MongoDB Atlas
3. **503 errors**: Check if tasks are healthy and running
4. **Image pull errors**: Verify ECR permissions and image URI

## Security Best Practices

1. Use HTTPS with SSL certificate (ACM)
2. Restrict security group rules
3. Use private subnets for ECS tasks
4. Rotate secrets regularly
5. Enable CloudTrail for audit logging
6. Use VPC endpoints for AWS services

## Next Steps

1. Set up custom domain with Route 53
2. Configure SSL certificate with ACM
3. Set up CloudFront for CDN
4. Configure auto-scaling policies
5. Set up CI/CD pipeline (GitHub Actions, CodePipeline)

## Support

For issues or questions:
- Check AWS CloudWatch logs
- Review ECS service events
- Verify task definitions and service configurations

