# PowerShell Script to Upload Project to EC2
# Usage: .\upload-to-ec2.ps1 -EC2IP "YOUR_EC2_IP" -KeyPath "C:\path\to\key.pem"

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2IP,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    
    [Parameter(Mandatory=$false)]
    [string]$User = "ec2-user",
    
    [Parameter(Mandatory=$false)]
    [string]$RemotePath = "/home/ec2-user/prescripto-main"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Uploading Project to EC2" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if key file exists
if (-not (Test-Path $KeyPath)) {
    Write-Host "Error: Key file not found at $KeyPath" -ForegroundColor Red
    exit 1
}

# Get current directory (project root)
$ProjectPath = Get-Location

Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "EC2 IP: $EC2IP" -ForegroundColor Yellow
Write-Host "Remote Path: $RemotePath" -ForegroundColor Yellow
Write-Host ""

# Exclude unnecessary files and directories
$ExcludePatterns = @(
    "node_modules",
    ".git",
    ".vscode",
    ".idea",
    "*.log",
    ".env",
    "dist",
    "build"
)

Write-Host "Creating temporary directory structure..." -ForegroundColor Green

# Create a temporary directory for upload
$TempDir = Join-Path $env:TEMP "prescripto-upload"
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Copy files excluding patterns
Write-Host "Copying files (excluding node_modules, .git, etc.)..." -ForegroundColor Green
Get-ChildItem -Path $ProjectPath -Recurse | Where-Object {
    $relativePath = $_.FullName.Substring($ProjectPath.Length + 1)
    $shouldExclude = $false
    foreach ($pattern in $ExcludePatterns) {
        if ($relativePath -like "*$pattern*") {
            $shouldExclude = $true
            break
        }
    }
    return -not $shouldExclude
} | ForEach-Object {
    $destPath = $_.FullName.Replace($ProjectPath, $TempDir)
    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item $_.FullName -Destination $destPath -Force
}

Write-Host "Files prepared for upload." -ForegroundColor Green
Write-Host ""

# Upload using SCP
Write-Host "Uploading to EC2..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

# Use scp command (requires OpenSSH client on Windows)
$scpCommand = "scp -i `"$KeyPath`" -r `"$TempDir\*`" ${User}@${EC2IP}:${RemotePath}"

try {
    # Create remote directory if it doesn't exist
    Write-Host "Creating remote directory..." -ForegroundColor Green
    $sshCommand = "ssh -i `"$KeyPath`" ${User}@${EC2IP} `"mkdir -p ${RemotePath}`""
    Invoke-Expression $sshCommand
    
    # Upload files
    Write-Host "Uploading files..." -ForegroundColor Green
    Invoke-Expression $scpCommand
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Upload completed successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. SSH into EC2: ssh -i `"$KeyPath`" ${User}@${EC2IP}" -ForegroundColor Yellow
    Write-Host "2. Navigate to project: cd $RemotePath" -ForegroundColor Yellow
    Write-Host "3. Create .env file in backend directory" -ForegroundColor Yellow
    Write-Host "4. Run: docker-compose up -d" -ForegroundColor Yellow
    Write-Host ""
} catch {
    Write-Host "Error during upload: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual upload alternative:" -ForegroundColor Yellow
    Write-Host "1. Use WinSCP or FileZilla to connect to EC2" -ForegroundColor Yellow
    Write-Host "2. Upload the project folder manually" -ForegroundColor Yellow
    Write-Host ""
}

# Clean up temporary directory
Write-Host "Cleaning up temporary files..." -ForegroundColor Green
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done!" -ForegroundColor Green

