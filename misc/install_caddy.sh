#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CADDY_VERSION="${CADDY_VERSION:-latest}"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/caddy"
DATA_DIR="/var/lib/caddy"
LOG_DIR="/var/log/caddy"
CADDY_USER="caddy"
CADDY_GROUP="caddy"

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect OS and architecture
detect_system() {
    echo_info "Detecting system..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        armv6l)
            ARCH="armv6"
            ;;
        *)
            echo_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    echo_info "Detected: $OS / $ARCH"
}

# Get latest version from GitHub
get_latest_version() {
    if [ "$CADDY_VERSION" = "latest" ]; then
        echo_info "Fetching latest Caddy version..."
        CADDY_VERSION=$(curl -s https://api.github.com/repos/caddyserver/caddy/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [ -z "$CADDY_VERSION" ]; then
            echo_error "Failed to fetch latest version"
            exit 1
        fi
        echo_info "Latest version: $CADDY_VERSION"
    fi
}

# Download Caddy
download_caddy() {
    echo_info "Downloading Caddy v${CADDY_VERSION}..."
    
    DOWNLOAD_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_${OS}_${ARCH}.tar.gz"
    
    echo_info "URL: $DOWNLOAD_URL"
    
    # Download to temp directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    if ! curl -L "$DOWNLOAD_URL" -o caddy.tar.gz; then
        echo_error "Failed to download Caddy"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    echo_info "Extracting archive..."
    tar -xzf caddy.tar.gz
    
    if [ ! -f "caddy" ]; then
        echo_error "Caddy binary not found in archive"
        rm -rf "$TMP_DIR"
        exit 1
    fi
}

# Install Caddy binary
install_caddy() {
    echo_info "Installing Caddy to $INSTALL_DIR..."
    
    # Stop Caddy if it's running
    if systemctl is-active --quiet caddy 2>/dev/null; then
        echo_info "Stopping existing Caddy service..."
        systemctl stop caddy
    fi
    
    # Backup existing binary if present
    if [ -f "$INSTALL_DIR/caddy" ]; then
        echo_info "Backing up existing Caddy binary..."
        mv "$INSTALL_DIR/caddy" "$INSTALL_DIR/caddy.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Install the binary
    mv caddy "$INSTALL_DIR/caddy"
    chmod +x "$INSTALL_DIR/caddy"
    
    # Set capabilities for binding to privileged ports
    setcap 'cap_net_bind_service=+ep' "$INSTALL_DIR/caddy"
    
    # Clean up
    cd /
    rm -rf "$TMP_DIR"
    
    echo_info "Caddy binary installed"
}

# Create Caddy user and directories
setup_directories() {
    echo_info "Setting up directories and user..."
    
    # Create user if it doesn't exist
    if ! id -u $CADDY_USER &> /dev/null; then
        useradd --system --home /var/lib/caddy --shell /usr/sbin/nologin $CADDY_USER
        echo_info "Created user: $CADDY_USER"
    fi
    
    # Create directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOG_DIR"
    
    # Set ownership
    chown -R $CADDY_USER:$CADDY_GROUP "$DATA_DIR"
    chown -R $CADDY_USER:$CADDY_GROUP "$LOG_DIR"
    
    # Create default Caddyfile if it doesn't exist
    if [ ! -f "$CONFIG_DIR/Caddyfile" ]; then
        cat > "$CONFIG_DIR/Caddyfile" << 'EOF'
# Default Caddyfile
# Replace with your actual configuration

# Simple HTTP server
:80 {
    respond "Caddy is running!"
}

# HTTPS example (automatic HTTPS)
# example.com {
#     root * /var/www/html
#     file_server
# }

# Reverse proxy example
# api.example.com {
#     reverse_proxy localhost:8080
# }
EOF
        chown $CADDY_USER:$CADDY_GROUP "$CONFIG_DIR/Caddyfile"
        echo_info "Created default Caddyfile at $CONFIG_DIR/Caddyfile"
    fi
}

# Create systemd service
setup_systemd() {
    echo_info "Setting up systemd service..."
    
    cat > /etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=$CADDY_USER
Group=$CADDY_GROUP
ExecStart=$INSTALL_DIR/caddy run --environ --config $CONFIG_DIR/Caddyfile
ExecReload=$INSTALL_DIR/caddy reload --config $CONFIG_DIR/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Restart policy
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable caddy
    
    echo_info "Systemd service created and enabled"
}

# Verify installation
verify_installation() {
    echo_info "Verifying installation..."
    
    if ! command -v caddy &> /dev/null; then
        echo_error "Caddy installation failed - command not found"
        exit 1
    fi
    
    INSTALLED_VERSION=$(caddy version)
    echo_info "Installed: $INSTALLED_VERSION"
    
    # Validate Caddyfile
    echo_info "Validating Caddyfile..."
    if caddy validate --config "$CONFIG_DIR/Caddyfile" 2>/dev/null; then
        echo_info "✓ Caddyfile is valid"
    else
        echo_warn "Caddyfile validation failed (this is OK for first install)"
    fi
}

# Show firewall instructions
show_firewall_info() {
    echo ""
    echo_warn "Firewall Configuration:"
    echo "  If you're using a firewall, allow HTTP/HTTPS traffic:"
    echo ""
    
    # Check which firewall is available
    if command -v ufw &> /dev/null; then
        echo "  For UFW:"
        echo "    sudo ufw allow 80/tcp"
        echo "    sudo ufw allow 443/tcp"
    elif command -v firewall-cmd &> /dev/null; then
        echo "  For firewalld:"
        echo "    sudo firewall-cmd --permanent --add-service=http"
        echo "    sudo firewall-cmd --permanent --add-service=https"
        echo "    sudo firewall-cmd --reload"
    else
        echo "  Allow TCP ports: 80, 443"
    fi
    echo ""
}

# Main installation function
main() {
    echo_info "Starting Caddy installation..."
    echo ""
    
    check_root
    detect_system
    get_latest_version
    download_caddy
    install_caddy
    setup_directories
    setup_systemd
    verify_installation
    
    echo ""
    echo_info "=========================================="
    echo_info "Caddy installation completed successfully!"
    echo_info "=========================================="
    echo ""
    echo_info "Next steps:"
    echo ""
    echo "  1. Edit the Caddyfile:"
    echo "     nano $CONFIG_DIR/Caddyfile"
    echo ""
    echo "  2. Start Caddy:"
    echo "     systemctl start caddy"
    echo ""
    echo "  3. Check status:"
    echo "     systemctl status caddy"
    echo ""
    echo "  4. View logs:"
    echo "     journalctl -u caddy -f"
    echo ""
    echo "  5. Reload configuration:"
    echo "     systemctl reload caddy"
    echo ""
    
    show_firewall_info
    
    echo_info "Configuration file: $CONFIG_DIR/Caddyfile"
    echo_info "Data directory: $DATA_DIR"
    echo_info "Documentation: https://caddyserver.com/docs/"
    echo ""
}

# Run main function
main
