# EC2 Setup Guide for Jenkins CI/CD Pipeline

This guide will walk you through setting up Jenkins on AWS EC2 and configuring it to build your Prescripto application using Docker.

## Prerequisites

- AWS Account with EC2 access
- Basic knowledge of Linux commands
- GitHub repository URL: https://github.com/aiman-zohra3/prescripto-main

## Step 1: Launch EC2 Instance

### 1.1 Create EC2 Instance
1. Log in to AWS Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Configure instance:
   - **Name**: Jenkins-Server
   - **AMI**: Amazon Linux 2023 (or Ubuntu 22.04 LTS)
   - **Instance Type**: t2.medium (minimum recommended for Jenkins)
   - **Key Pair**: Create or select an existing key pair
   - **Security Group**: Create a new security group with the following rules:
     - **SSH (22)**: Your IP
     - **HTTP (80)**: 0.0.0.0/0
     - **HTTPS (443)**: 0.0.0.0/0
     - **Jenkins (8080)**: 0.0.0.0/0 (or restrict to your IP)
     - **Custom TCP (5000, 6000, 6001)**: 0.0.0.0/0 (for your application)
   - **Storage**: 20 GB minimum
5. Click "Launch Instance"

### 1.2 Connect to EC2 Instance

**For Windows (PowerShell):**
```powershell
# Change to your key pair directory
cd C:\Users\HP\.ssh

# Connect to EC2 instance (replace with your instance public IP)
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

**For Linux/Mac:**
```bash
chmod 400 your-key-pair.pem
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

**Note**: Replace `ec2-user` with `ubuntu` if using Ubuntu AMI.

## Step 2: Update System and Install Required Packages

### For Amazon Linux 2023:
```bash
sudo yum update -y
sudo yum install -y git wget unzip
```

### For Ubuntu 22.04:
```bash
sudo apt-get update
sudo apt-get install -y git wget unzip curl
```

## Step 3: Install Docker

### For Amazon Linux 2023:
```bash
# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### For Ubuntu 22.04:
```bash
# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

**Important**: Log out and log back in for group changes to take effect:
```bash
exit
# Then reconnect via SSH
```

## Step 4: Install Jenkins

### For Amazon Linux 2023:
```bash
# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Java 17 (required for Jenkins)
sudo yum install -y java-17-amazon-corretto-headless

# Install Jenkins
sudo yum install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

### For Ubuntu 22.04:
```bash
# Install Java 17
sudo apt-get install -y openjdk-17-jre

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

## Step 5: Configure Jenkins

### 5.1 Get Jenkins Initial Admin Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Copy this password for the next step.

### 5.2 Access Jenkins Web Interface
1. Open your browser and navigate to: `http://3.110.123.222:8080`
2. Enter the initial admin password from Step 5.1
3. Click "Install suggested plugins"
4. Wait for plugin installation to complete
5. Create an admin user account
6. Configure Jenkins URL (use default: `http://YOUR_EC2_PUBLIC_IP:8080`)
7. Click "Save and Finish"

### 5.3 Install Required Jenkins Plugins
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click on the **Available** tab
3. Search and install the following plugins:
   - **Git Plugin** (usually pre-installed)
   - **Pipeline Plugin** (usually pre-installed)
   - **Docker Pipeline Plugin**
   - **Docker Plugin**
   - **Docker Compose Build Step Plugin**
4. Click **Install without restart** or **Download now and install after restart**
5. Restart Jenkins if prompted:
   ```bash
   sudo systemctl restart jenkins
   ```

### 5.4 Configure Docker for Jenkins
```bash
# Add Jenkins user to docker group
sudo usermod -a -G docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

## Step 6: Upload Project to EC2 (Option 1 - Using SCP)

### From Windows (PowerShell):
```powershell
# Navigate to your project directory
cd C:\Users\HP\Documents\DevOps\prescripto-main\prescripto-main

# Upload the entire project to EC2
scp -i C:\Users\HP\.ssh\your-key-pair.pem -r . ec2-user@YOUR_EC2_PUBLIC_IP:/home/ec2-user/prescripto-main
```

### From Linux/Mac:
```bash
# Navigate to your project directory
cd /path/to/prescripto-main

# Upload the entire project to EC2
scp -i ~/.ssh/your-key-pair.pem -r . ec2-user@YOUR_EC2_PUBLIC_IP:/home/ec2-user/prescripto-main
```

## Step 6: Alternative - Clone from GitHub on EC2

### SSH into EC2 and clone repository:
```bash
# Connect to EC2
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Create project directory
mkdir -p ~/prescripto-main
cd ~/prescripto-main

# Clone repository
git clone https://github.com/aiman-zohra3/prescripto-main.git .

# Or if the repository is in a subdirectory:
git clone https://github.com/aiman-zohra3/prescripto-main.git temp
mv temp/* temp/.* . 2>/dev/null || true
rmdir temp
```

## Step 7: Configure Jenkins Pipeline

### 7.1 Create New Pipeline Job
1. In Jenkins, click **New Item**
2. Enter item name: `prescripto-pipeline`
3. Select **Pipeline**
4. Click **OK**

### 7.2 Configure Pipeline
1. Scroll down to **Pipeline** section
2. **Definition**: Select **Pipeline script from SCM**
3. **SCM**: Select **Git**
4. **Repository URL**: `https://github.com/aiman-zohra3/prescripto-main.git`
5. **Branch Specifier**: `*/main`
6. **Script Path**: `Jenkinsfile`
7. Click **Save**

### 7.3 Build the Pipeline
1. Click **Build Now** on your pipeline job
2. Monitor the build progress in the console output
3. Check if all stages complete successfully

## Step 8: Verify Application

### Check running containers:
```bash
docker ps
docker-compose ps
```

### Check application logs:
```bash
cd ~/prescripto-main
docker-compose logs backend
docker-compose logs client
docker-compose logs admin
```

### Access Application:
- **Backend**: `http://YOUR_EC2_PUBLIC_IP:5000`
- **Client**: `http://YOUR_EC2_PUBLIC_IP:6000`
- **Admin**: `http://YOUR_EC2_PUBLIC_IP:6001`

## Step 9: Configure Backend Environment Variables

### Create backend .env file:
```bash
cd ~/prescripto-main/backend
nano .env
```

### Add required environment variables (example):
```env
PORT=4000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

### Save and exit (Ctrl+X, then Y, then Enter)

## Troubleshooting

### Jenkins cannot access Docker:
```bash
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### Permission denied errors:
```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod -R 755 /var/lib/jenkins
```

### Docker Compose not found:
```bash
# Verify installation
which docker-compose
docker-compose --version

# If not found, reinstall
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Port already in use:
```bash
# Check what's using the port
sudo netstat -tulpn | grep :8080
# Or
sudo lsof -i :8080

# Kill the process if needed
sudo kill -9 <PID>
```

### View Jenkins logs:
```bash
sudo tail -f /var/log/jenkins/jenkins.log
```

## Useful Commands

### Start/Stop Jenkins:
```bash
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins
sudo systemctl status jenkins
```

### Start/Stop Docker containers:
```bash
cd ~/prescripto-main
docker-compose up -d
docker-compose down
docker-compose restart
```

### View container logs:
```bash
docker-compose logs -f
docker-compose logs -f backend
docker-compose logs -f client
docker-compose logs -f admin
```

### Clean up Docker:
```bash
docker system prune -a
docker volume prune
```

## Security Best Practices

1. **Restrict Jenkins port (8080)** to your IP only in security group
2. **Use HTTPS** for Jenkins (consider setting up Nginx reverse proxy)
3. **Keep Jenkins updated**: Regularly update Jenkins and plugins
4. **Use strong passwords** for Jenkins admin account
5. **Regular backups**: Backup Jenkins configuration regularly
6. **Monitor logs**: Regularly check Jenkins and application logs

## Next Steps

1. Set up automated builds on Git push (webhook)
2. Add testing stage to pipeline
3. Add deployment stage to pipeline
4. Set up monitoring and alerts
5. Configure backup strategy

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

---

**Note**: Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 instance public IP address throughout this guide.


