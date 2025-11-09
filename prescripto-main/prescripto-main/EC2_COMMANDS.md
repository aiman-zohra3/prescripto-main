# EC2 Setup Commands - Complete Reference

This file contains all the commands you need to run on your EC2 instance to set up Jenkins CI/CD.

## 🔧 Initial Setup (Run on EC2)

### 1. Connect to EC2 Instance
```bash
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### 2. Update System (Amazon Linux)
```bash
sudo yum update -y
sudo yum install -y git wget unzip curl
```

### 3. Install Docker
```bash
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

### 4. Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### 5. Install Java 17
```bash
sudo yum install -y java-17-amazon-corretto-headless
java -version
```

### 6. Install Jenkins
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 7. Configure Jenkins for Docker
```bash
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### 8. Get Jenkins Initial Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 9. Log out and log back in (for docker group to take effect)
```bash
exit
# Then reconnect
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

## 📦 Upload Project to EC2

### Option 1: Clone from GitHub
```bash
cd ~
git clone https://github.com/aiman-zohra3/prescripto-main.git
cd prescripto-main
```

### Option 2: Upload via SCP (from your local machine)
```bash
# From Windows PowerShell
cd C:\Users\HP\Documents\DevOps\prescripto-main\prescripto-main
scp -i C:\Users\HP\.ssh\your-key-pair.pem -r . ec2-user@YOUR_EC2_PUBLIC_IP:/home/ec2-user/prescripto-main
```

## 🔐 Configure Environment Variables

### 1. Update docker-compose.yml with your EC2 IP
```bash
cd ~/prescripto-main
nano docker-compose.yml
# Replace YOUR_EC2_PUBLIC_IP with your actual EC2 public IP
# Save and exit (Ctrl+X, Y, Enter)
```

### 2. Create backend/.env file
```bash
cd ~/prescripto-main/backend
nano .env
```

Add the following (replace with your actual values):
```env
PORT=4000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

Save and exit (Ctrl+X, Y, Enter)

## 🚀 Test Docker Compose (Optional)

### Start containers manually
```bash
cd ~/prescripto-main
docker-compose up -d
```

### Check status
```bash
docker-compose ps
docker ps
```

### View logs
```bash
docker-compose logs -f
```

### Stop containers
```bash
docker-compose down
```

## 🌐 Configure Jenkins Web Interface

### 1. Access Jenkins
Open browser: `http://YOUR_EC2_PUBLIC_IP:8080`

### 2. Install Plugins
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Install the following plugins:
   - Git Plugin
   - Pipeline Plugin
   - Docker Pipeline Plugin
   - Docker Plugin
   - Docker Compose Build Step Plugin

### 3. Create Pipeline Job
1. Click **New Item**
2. Name: `prescripto-pipeline`
3. Select **Pipeline**
4. Click **OK**
5. Scroll to **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/aiman-zohra3/prescripto-main.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
6. Click **Save**

### 4. Run Pipeline
1. Click **Build Now**
2. Monitor build progress
3. Check console output for any errors

## 🔍 Verification Commands

### Check Docker
```bash
docker --version
docker-compose --version
docker ps
```

### Check Jenkins
```bash
sudo systemctl status jenkins
sudo systemctl is-enabled jenkins
```

### Check Java
```bash
java -version
```

### Check containers
```bash
docker ps
docker-compose ps
```

### Check application logs
```bash
cd ~/prescripto-main
docker-compose logs backend
docker-compose logs client
docker-compose logs admin
```

### Test application endpoints
```bash
curl http://localhost:5000
curl http://localhost:6000
curl http://localhost:6001
```

## 🛠️ Maintenance Commands

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### View Jenkins logs
```bash
sudo tail -f /var/log/jenkins/jenkins.log
```

### Restart Docker
```bash
sudo systemctl restart docker
```

### Restart containers
```bash
cd ~/prescripto-main
docker-compose restart
```

### Stop all containers
```bash
cd ~/prescripto-main
docker-compose down
```

### Start all containers
```bash
cd ~/prescripto-main
docker-compose up -d
```

### Clean up Docker
```bash
docker system prune -a
docker volume prune
```

## 🐛 Troubleshooting Commands

### Check port usage
```bash
sudo netstat -tulpn | grep :8080
sudo lsof -i :8080
```

### Check container status
```bash
docker ps -a
docker-compose ps
```

### View container logs
```bash
docker logs prescripto-backend-ci
docker logs prescripto-client-ci
docker logs prescripto-admin-ci
```

### Check Docker group membership
```bash
groups
groups jenkins
```

### Fix permissions
```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod -R 755 /var/lib/jenkins
```

### Re-add user to docker group
```bash
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
# Log out and log back in
```

## 📊 Monitoring Commands

### Check system resources
```bash
free -h
df -h
top
```

### Check Docker resources
```bash
docker stats
docker system df
```

### Check Jenkins build history
```bash
# Via web interface or
ls -la /var/lib/jenkins/jobs/prescripto-pipeline/builds/
```

## 🔄 Update Project

### Pull latest changes from GitHub
```bash
cd ~/prescripto-main
git pull origin main
```

### Restart containers after update
```bash
docker-compose down
docker-compose up -d
```

## 📝 Quick Reference

### Most Common Commands
```bash
# Start application
cd ~/prescripto-main && docker-compose up -d

# Stop application
cd ~/prescripto-main && docker-compose down

# View logs
cd ~/prescripto-main && docker-compose logs -f

# Restart Jenkins
sudo systemctl restart jenkins

# Check status
docker-compose ps
sudo systemctl status jenkins
```

## ✅ Verification Checklist

Run these commands to verify everything is set up correctly:

```bash
# 1. Check Docker
docker --version && docker-compose --version

# 2. Check Jenkins
sudo systemctl status jenkins | grep active

# 3. Check Java
java -version

# 4. Check containers (after starting)
docker-compose ps

# 5. Check application (after starting)
curl -I http://localhost:5000
curl -I http://localhost:6000
curl -I http://localhost:6001
```

---

**Note**: Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 instance public IP address in all commands and configurations.

