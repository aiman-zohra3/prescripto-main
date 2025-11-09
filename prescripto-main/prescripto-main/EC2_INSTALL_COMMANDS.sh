#!/bin/bash

# EC2 Setup Script for Jenkins CI/CD Pipeline
# This script automates the installation of Docker, Docker Compose, and Jenkins on EC2

set -e  # Exit on error

echo "=========================================="
echo "EC2 Setup Script for Jenkins CI/CD"
echo "=========================================="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS"

# Function to install on Amazon Linux
install_amazon_linux() {
    echo "Installing on Amazon Linux..."
    
    # Update system
    echo "Updating system packages..."
    sudo yum update -y
    sudo yum install -y git wget unzip curl
    
    # Install Docker
    echo "Installing Docker..."
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
    
    # Install Docker Compose
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Install Java 17
    echo "Installing Java 17..."
    sudo yum install -y java-17-amazon-corretto-headless
    
    # Install Jenkins
    echo "Installing Jenkins..."
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Add Jenkins to docker group
    sudo usermod -a -G docker jenkins
    
    echo "Installation completed for Amazon Linux!"
}

# Function to install on Ubuntu
install_ubuntu() {
    echo "Installing on Ubuntu..."
    
    # Update system
    echo "Updating system packages..."
    sudo apt-get update
    sudo apt-get install -y git wget unzip curl
    
    # Install Docker
    echo "Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ubuntu
    
    # Install Docker Compose
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Install Java 17
    echo "Installing Java 17..."
    sudo apt-get install -y openjdk-17-jre
    
    # Install Jenkins
    echo "Installing Jenkins..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Add Jenkins to docker group
    sudo usermod -a -G docker jenkins
    
    echo "Installation completed for Ubuntu!"
}

# Main installation logic
if [[ "$OS" == "amzn" ]] || [[ "$OS" == "amazon" ]]; then
    install_amazon_linux
elif [[ "$OS" == "ubuntu" ]]; then
    install_ubuntu
else
    echo "Unsupported OS: $OS"
    echo "Please install manually using the EC2_SETUP_GUIDE.md"
    exit 1
fi

# Verify installations
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo "Docker version:"
docker --version

echo "Docker Compose version:"
docker-compose --version

echo "Java version:"
java -version

echo "Jenkins status:"
sudo systemctl status jenkins --no-pager | head -5

echo ""
echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo "✓ Docker installed"
echo "✓ Docker Compose installed"
echo "✓ Java 17 installed"
echo "✓ Jenkins installed and started"
echo ""
echo "Next steps:"
echo "1. Get Jenkins initial admin password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "2. Access Jenkins at: http://YOUR_EC2_PUBLIC_IP:8080"
echo ""
echo "3. Install Jenkins plugins:"
echo "   - Git Plugin"
echo "   - Pipeline Plugin"
echo "   - Docker Pipeline Plugin"
echo "   - Docker Plugin"
echo "   - Docker Compose Build Step Plugin"
echo ""
echo "4. Restart Jenkins:"
echo "   sudo systemctl restart jenkins"
echo ""
echo "5. Clone your repository:"
echo "   git clone https://github.com/aiman-zohra3/prescripto-main.git"
echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="

# Display Jenkins initial admin password
echo ""
echo "Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword


