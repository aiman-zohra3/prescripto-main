# Quick Reference Guide - Jenkins CI/CD Setup

## 🚀 Quick Start Commands

### 1. Connect to EC2 Instance

**Windows (PowerShell):**
```powershell
ssh -i C:\Users\HP\.ssh\your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

**Linux/Mac:**
```bash
ssh -i ~/.ssh/your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### 2. Run Automated Installation Script

```bash
# Download and run the installation script
wget https://raw.githubusercontent.com/aiman-zohra3/prescripto-main/main/EC2_INSTALL_COMMANDS.sh
chmod +x EC2_INSTALL_COMMANDS.sh
./EC2_INSTALL_COMMANDS.sh
```

### 3. Get Jenkins Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 4. Access Jenkins

Open in browser: `http://YOUR_EC2_PUBLIC_IP:8080`

### 5. Upload Project to EC2

**Option A: Using PowerShell Script (Windows)**
```powershell
.\upload-to-ec2.ps1 -EC2IP "YOUR_EC2_PUBLIC_IP" -KeyPath "C:\path\to\key.pem"
```

**Option B: Using SCP (Windows PowerShell)**
```powershell
cd C:\Users\HP\Documents\DevOps\prescripto-main\prescripto-main
scp -i C:\Users\HP\.ssh\your-key-pair.pem -r . ec2-user@YOUR_EC2_PUBLIC_IP:/home/ec2-user/prescripto-main
```

**Option C: Clone from GitHub on EC2**
```bash
ssh -i your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
cd ~
git clone https://github.com/aiman-zohra3/prescripto-main.git
cd prescripto-main
```

## 📋 Installation Commands (Manual)

### Install Docker (Amazon Linux)
```bash
sudo yum update -y
sudo yum install -y docker git wget unzip curl
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

### Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### Install Java 17 (Amazon Linux)
```bash
sudo yum install -y java-17-amazon-corretto-headless
java -version
```

### Install Jenkins (Amazon Linux)
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### Install Docker (Ubuntu)
```bash
sudo apt-get update
sudo apt-get install -y docker.io git wget unzip curl
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ubuntu
```

### Install Java 17 (Ubuntu)
```bash
sudo apt-get install -y openjdk-17-jre
java -version
```

### Install Jenkins (Ubuntu)
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

## 🔧 Jenkins Configuration

### Required Plugins
1. Git Plugin (usually pre-installed)
2. Pipeline Plugin (usually pre-installed)
3. Docker Pipeline Plugin
4. Docker Plugin
5. Docker Compose Build Step Plugin

### Create Pipeline Job
1. Jenkins → New Item
2. Name: `prescripto-pipeline`
3. Type: Pipeline
4. Pipeline → Definition: Pipeline script from SCM
5. SCM: Git
6. Repository URL: `https://github.com/aiman-zohra3/prescripto-main.git`
7. Branch: `*/main`
8. Script Path: `Jenkinsfile`
9. Save

## 🐳 Docker Commands

### Start Application
```bash
cd ~/prescripto-main
docker-compose up -d
```

### Stop Application
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f backend
docker-compose logs -f client
docker-compose logs -f admin
```

### Check Status
```bash
docker-compose ps
docker ps
```

### Restart Containers
```bash
docker-compose restart
```

### Rebuild and Start
```bash
docker-compose down
docker-compose up -d --build
```

## 🔍 Verification Commands

### Check Docker Installation
```bash
docker --version
docker-compose --version
docker ps
```

### Check Jenkins Status
```bash
sudo systemctl status jenkins
sudo systemctl is-enabled jenkins
```

### Check Java Installation
```bash
java -version
```

### Check Network Connectivity
```bash
curl http://localhost:8080
curl http://localhost:5000
curl http://localhost:6000
curl http://localhost:6001
```

## 🛠️ Troubleshooting Commands

### View Jenkins Logs
```bash
sudo tail -f /var/log/jenkins/jenkins.log
```

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### Check Port Usage
```bash
sudo netstat -tulpn | grep :8080
sudo lsof -i :8080
```

### Fix Docker Permissions
```bash
sudo usermod -a -G docker jenkins
sudo usermod -a -G docker $USER
sudo systemctl restart jenkins
# Log out and log back in for user group changes
```

### Clean Docker System
```bash
docker system prune -a
docker volume prune
docker-compose down -v
```

### Check Container Logs
```bash
docker logs prescripto-backend-ci
docker logs prescripto-client-ci
docker logs prescripto-admin-ci
```

## 📁 Project Structure

```
prescripto-main/
├── backend/          # Backend service
│   └── .env         # Backend environment variables
├── clientside/       # Client frontend
├── admin/           # Admin frontend
├── docker-compose.yml
└── Jenkinsfile      # Jenkins pipeline script
```

## 🌐 Application URLs

After deployment, access your application at:
- **Backend API**: `http://YOUR_EC2_PUBLIC_IP:5000`
- **Client Frontend**: `http://YOUR_EC2_PUBLIC_IP:6000`
- **Admin Frontend**: `http://YOUR_EC2_PUBLIC_IP:6001`
- **Jenkins**: `http://YOUR_EC2_PUBLIC_IP:8080`

## 🔐 Security Group Rules

Ensure your EC2 security group has these rules:
- **SSH (22)**: Your IP only
- **HTTP (80)**: 0.0.0.0/0 (optional)
- **HTTPS (443)**: 0.0.0.0/0 (optional)
- **Jenkins (8080)**: Your IP or 0.0.0.0/0
- **Backend (5000)**: 0.0.0.0/0
- **Client (6000)**: 0.0.0.0/0
- **Admin (6001)**: 0.0.0.0/0

## 📝 Environment Variables

Create `backend/.env` file:
```bash
cd ~/prescripto-main/backend
nano .env
```

Required variables:
```env
PORT=4000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

## 🔄 Pipeline Stages

The Jenkins pipeline includes:
1. **Checkout**: Clone code from GitHub
2. **Clean Up**: Remove previous builds
3. **Build with Docker**: Build application containers
4. **Start Containers**: Start all services
5. **Verify Build**: Check container status
6. **Health Check**: Verify all containers are running

## 📚 Useful Links

- Jenkins: http://YOUR_EC2_PUBLIC_IP:8080
- GitHub Repo: https://github.com/aiman-zohra3/prescripto-main
- Docker Docs: https://docs.docker.com/
- Jenkins Docs: https://www.jenkins.io/doc/

## ⚡ Quick Troubleshooting

### Jenkins won't start
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

### Docker permission denied
```bash
sudo usermod -a -G docker $USER
newgrp docker
```

### Port already in use
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

### Containers not starting
```bash
docker-compose logs
docker-compose down
docker-compose up -d
```

---

**Remember**: Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 instance public IP address!


