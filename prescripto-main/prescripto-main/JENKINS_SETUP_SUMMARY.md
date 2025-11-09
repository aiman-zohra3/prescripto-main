# Jenkins CI/CD Setup Summary

This document provides a complete summary of the Jenkins CI/CD setup for the Prescripto application.

## 📋 What Has Been Done

### 1. Modified Docker Compose Configuration
- ✅ Changed from Dockerfile builds to volume-based mounts
- ✅ Updated port numbers:
  - Backend: `5000` (was 4000)
  - Client: `6000` (was 5173)
  - Admin: `6001` (was 5174)
- ✅ Updated container names:
  - `prescripto-backend-ci` (was prescripto-backend)
  - `prescripto-client-ci` (was prescripto-client)
  - `prescripto-admin-ci` (was prescripto-admin)

### 2. Created Jenkins Pipeline
- ✅ Created `Jenkinsfile` with complete CI/CD pipeline
- ✅ Pipeline includes:
  - Code checkout from GitHub
  - Clean up previous builds
  - Build with Docker Compose
  - Start containers
  - Verify build
  - Health checks

### 3. Created Documentation
- ✅ `EC2_SETUP_GUIDE.md` - Complete setup guide
- ✅ `EC2_INSTALL_COMMANDS.sh` - Automated installation script
- ✅ `QUICK_REFERENCE.md` - Quick command reference
- ✅ `upload-to-ec2.ps1` - PowerShell script for Windows uploads

## 🚀 Quick Start

### Step 1: Launch EC2 Instance
1. Launch Amazon Linux 2023 or Ubuntu 22.04 instance
2. Configure security group (ports: 22, 8080, 5000, 6000, 6001)
3. Connect via SSH

### Step 2: Install Dependencies
```bash
# Option A: Automated installation
wget https://raw.githubusercontent.com/aiman-zohra3/prescripto-main/main/EC2_INSTALL_COMMANDS.sh
chmod +x EC2_INSTALL_COMMANDS.sh
./EC2_INSTALL_COMMANDS.sh

# Option B: Manual installation (see EC2_SETUP_GUIDE.md)
```

### Step 3: Configure Jenkins
1. Access Jenkins: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Get initial password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Install suggested plugins
4. Install required plugins:
   - Git Plugin
   - Pipeline Plugin
   - Docker Pipeline Plugin
   - Docker Plugin
   - Docker Compose Build Step Plugin

### Step 4: Upload Project
```bash
# Option A: Clone from GitHub
git clone https://github.com/aiman-zohra3/prescripto-main.git
cd prescripto-main

# Option B: Upload via SCP (see upload-to-ec2.ps1)
```

### Step 5: Configure Pipeline
1. Jenkins → New Item → Pipeline
2. Name: `prescripto-pipeline`
3. Pipeline → Pipeline script from SCM
4. Repository: `https://github.com/aiman-zohra3/prescripto-main.git`
5. Branch: `*/main`
6. Script Path: `Jenkinsfile`

### Step 6: Update Environment Variables
```bash
# Update docker-compose.yml with your EC2 IP
nano docker-compose.yml
# Replace YOUR_EC2_PUBLIC_IP with actual IP

# Create backend/.env file
cd backend
nano .env
# Add required environment variables
```

### Step 7: Run Pipeline
1. Click "Build Now" in Jenkins
2. Monitor build progress
3. Verify application is running

## 📁 File Structure

```
prescripto-main/
├── docker-compose.yml          # Modified: Uses volumes, new ports
├── Jenkinsfile                 # New: CI/CD pipeline
├── EC2_SETUP_GUIDE.md          # New: Complete setup guide
├── EC2_INSTALL_COMMANDS.sh     # New: Automated installation
├── QUICK_REFERENCE.md          # New: Quick commands
├── upload-to-ec2.ps1           # New: Windows upload script
├── JENKINS_SETUP_SUMMARY.md    # This file
├── backend/
│   └── .env                    # Required: Environment variables
├── clientside/
└── admin/
```

## 🔧 Configuration Changes

### Docker Compose Changes
- **Before**: Used `build: ./backend` with Dockerfiles
- **After**: Uses `image: node:20-alpine` with volumes
- **Ports**: Changed to 5000, 6000, 6001
- **Containers**: Renamed with `-ci` suffix

### Jenkins Pipeline
- Fetches code from GitHub automatically
- Builds application using Docker Compose
- Starts all containers
- Verifies build success
- Performs health checks

## 🌐 Access Points

After successful deployment:
- **Jenkins**: `http://YOUR_EC2_PUBLIC_IP:8080`
- **Backend API**: `http://YOUR_EC2_PUBLIC_IP:5000`
- **Client Frontend**: `http://YOUR_EC2_PUBLIC_IP:6000`
- **Admin Frontend**: `http://YOUR_EC2_PUBLIC_IP:6001`

## 🔐 Security Group Configuration

Ensure your EC2 security group allows:
- **SSH (22)**: Your IP only
- **Jenkins (8080)**: Your IP or 0.0.0.0/0
- **Backend (5000)**: 0.0.0.0/0
- **Client (6000)**: 0.0.0.0/0
- **Admin (6001)**: 0.0.0.0/0

## 📝 Required Environment Variables

Create `backend/.env` file with:
```env
PORT=4000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

## 🔄 Pipeline Workflow

1. **Checkout**: Clone code from GitHub
2. **Clean Up**: Remove previous builds and containers
3. **Build**: Build application with Docker Compose
4. **Start**: Start all containers
5. **Verify**: Check container status
6. **Health Check**: Verify all containers are running

## 🐛 Troubleshooting

### Common Issues

1. **Jenkins cannot access Docker**
   ```bash
   sudo usermod -a -G docker jenkins
   sudo systemctl restart jenkins
   ```

2. **Port already in use**
   ```bash
   sudo lsof -i :8080
   sudo kill -9 <PID>
   ```

3. **Containers not starting**
   ```bash
   docker-compose logs
   docker-compose down
   docker-compose up -d
   ```

4. **Permission denied**
   ```bash
   sudo chown -R jenkins:jenkins /var/lib/jenkins
   sudo chmod -R 755 /var/lib/jenkins
   ```

## 📚 Additional Resources

- **Complete Guide**: See `EC2_SETUP_GUIDE.md`
- **Quick Commands**: See `QUICK_REFERENCE.md`
- **Jenkins Docs**: https://www.jenkins.io/doc/
- **Docker Docs**: https://docs.docker.com/

## ✅ Checklist

- [ ] EC2 instance launched
- [ ] Security group configured
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] Jenkins installed
- [ ] Jenkins plugins installed
- [ ] Project uploaded to EC2
- [ ] Pipeline configured in Jenkins
- [ ] Environment variables configured
- [ ] Pipeline runs successfully
- [ ] Application accessible

## 🎯 Next Steps

1. Set up automated builds on Git push (webhook)
2. Add testing stage to pipeline
3. Add deployment stage to pipeline
4. Set up monitoring and alerts
5. Configure backup strategy
6. Set up HTTPS with Nginx reverse proxy

## 📞 Support

For issues or questions:
1. Check `EC2_SETUP_GUIDE.md` for detailed instructions
2. Check `QUICK_REFERENCE.md` for common commands
3. Review Jenkins and Docker logs
4. Verify security group configuration
5. Check environment variables

---

**Note**: Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 instance public IP address throughout all configuration files and documentation.


