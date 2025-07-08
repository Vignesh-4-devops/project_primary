#!/bin/bash

# Ansible Dependencies Installation Script
# This script installs Ansible and required dependencies on macOS and Ubuntu/Debian systems

set -e  # Exit on any error

echo "🚀 Installing Ansible and dependencies..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
print_status "Detected OS: $OS"

# Check if running as root (skip for macOS)
if [[ "$OS" != "macos" && $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Install based on OS
if [[ "$OS" == "macos" ]]; then
    print_status "Installing Ansible on macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_error "Homebrew is required but not installed. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Install Ansible via Homebrew
    brew install ansible
    
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    print_status "Installing Ansible on Ubuntu/Debian..."
    
    # Update package list (ignore repository errors)
    print_status "Updating package list..."
    sudo apt update || true
    
    # Install required system packages
    print_status "Installing system dependencies..."
    sudo apt install -y software-properties-common
    
    # Add Ansible PPA for latest version
    print_status "Adding Ansible PPA..."
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    
    # Install Ansible
    print_status "Installing Ansible..."
    sudo apt install -y ansible || {
        print_error "Failed to install Ansible via PPA. Trying alternative method..."
        sudo apt install -y software-properties-common
        sudo apt-add-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
    }
    
else
    print_error "Unsupported operating system: $OS"
    print_error "This script supports macOS and Ubuntu/Debian systems."
    exit 1
fi

# Verify installation
if command_exists ansible; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    print_success "Ansible installed successfully: $ANSIBLE_VERSION"
else
    print_error "Ansible installation failed"
    exit 1
fi

print_success "Installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure your inventory file (hosts)"
echo "2. Set up SSH keys for passwordless authentication"
echo "3. Test connection: ansible all -i hosts -m ping"
echo ""
echo "For more information, see the README.md file." 