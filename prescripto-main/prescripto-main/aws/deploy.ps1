# AWS Deployment Script for Prescripto (PowerShell)
# Usage: .\deploy.ps1 -Region <region> -AwsAccountId <aws-account-id> [-ImageTag <tag>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$true)]
    [string]$AwsAccountId,
    
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting AWS Deployment..." -ForegroundColor Green
Write-Host "Region: $Region"
Write-Host "Account ID: $AwsAccountId"
Write-Host "Image Tag: $ImageTag"

# ECR Repository names
$BackendRepo = "prescripto-backend"
$FrontendRepo = "prescripto-frontend"
$AdminRepo = "prescripto-admin"

# Create ECR repositories if they don't exist
Write-Host "📦 Creating ECR repositories..." -ForegroundColor Cyan
try {
    aws ecr describe-repositories --repository-names $BackendRepo --region $Region 2>$null
} catch {
    aws ecr create-repository --repository-name $BackendRepo --region $Region
}

try {
    aws ecr describe-repositories --repository-names $FrontendRepo --region $Region 2>$null
} catch {
    aws ecr create-repository --repository-name $FrontendRepo --region $Region
}

try {
    aws ecr describe-repositories --repository-names $AdminRepo --region $Region 2>$null
} catch {
    aws ecr create-repository --repository-name $AdminRepo --region $Region
}

# Login to ECR
Write-Host "🔐 Logging into ECR..." -ForegroundColor Cyan
$ecrPassword = aws ecr get-login-password --region $Region
$ecrPassword | docker login --username AWS --password-stdin "$AwsAccountId.dkr.ecr.$Region.amazonaws.com"

# Build and push backend
Write-Host "🏗️  Building and pushing backend..." -ForegroundColor Cyan
Set-Location backend
docker build -t "$BackendRepo`:$ImageTag" .
docker tag "$BackendRepo`:$ImageTag" "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$BackendRepo`:$ImageTag"
docker push "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$BackendRepo`:$ImageTag"
Set-Location ..

# Build and push frontend
Write-Host "🏗️  Building and pushing frontend..." -ForegroundColor Cyan
Set-Location clientside
docker build -t "$FrontendRepo`:$ImageTag" .
docker tag "$FrontendRepo`:$ImageTag" "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$FrontendRepo`:$ImageTag"
docker push "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$FrontendRepo`:$ImageTag"
Set-Location ..

# Build and push admin
Write-Host "🏗️  Building and pushing admin..." -ForegroundColor Cyan
Set-Location admin
docker build -t "$AdminRepo`:$ImageTag" .
docker tag "$AdminRepo`:$ImageTag" "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$AdminRepo`:$ImageTag"
docker push "$AwsAccountId.dkr.ecr.$Region.amazonaws.com/$AdminRepo`:$ImageTag"
Set-Location ..

Write-Host "✅ Images pushed successfully!" -ForegroundColor Green

# Update and register task definitions
Write-Host "📝 Updating task definitions..." -ForegroundColor Cyan

$backendTaskDef = Get-Content "aws/ecs-task-definition-backend.json" -Raw
$backendTaskDef = $backendTaskDef -replace "YOUR_AWS_ACCOUNT_ID", $AwsAccountId
$backendTaskDef = $backendTaskDef -replace "YOUR_REGION", $Region
$backendTaskDef | Out-File -FilePath "$env:TEMP\task-backend.json" -Encoding utf8

$frontendTaskDef = Get-Content "aws/ecs-task-definition-frontend.json" -Raw
$frontendTaskDef = $frontendTaskDef -replace "YOUR_AWS_ACCOUNT_ID", $AwsAccountId
$frontendTaskDef = $frontendTaskDef -replace "YOUR_REGION", $Region
$frontendTaskDef | Out-File -FilePath "$env:TEMP\task-frontend.json" -Encoding utf8

aws ecs register-task-definition --cli-input-json "file://$env:TEMP\task-backend.json" --region $Region
aws ecs register-task-definition --cli-input-json "file://$env:TEMP\task-frontend.json" --region $Region

Write-Host "✅ Task definitions registered!" -ForegroundColor Green

Write-Host "🎉 Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Create ECS cluster: aws ecs create-cluster --cluster-name prescripto-cluster --region $Region"
Write-Host "2. Create Application Load Balancer and target groups"
Write-Host "3. Create ECS services using the task definitions"
Write-Host "4. Set up secrets in AWS Secrets Manager"

