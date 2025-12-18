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

# Cloudflare DNS module
CF_MODULE="github.com/caddy-dns/cloudflare"

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
        *)
            echo_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    echo_info "Detected: $OS / $ARCH"
}

# Get latest Go version
get_latest_go_version() {
    echo_info "Fetching latest Go version..."
    
    # Try to get version from official Go website
    local version=$(curl -fsSL "https://go.dev/VERSION?m=text" 2>/dev/null | head -n 1)
    
    if [ -z "$version" ]; then
        echo_warn "Failed to fetch latest version, using fallback version 1.23.4"
        echo "1.23.4"
        return
    fi
    
    # Remove 'go' prefix if present (e.g., "go1.23.4" -> "1.23.4")
    version=${version#go}
    
    echo_info "Latest Go version: $version"
    echo "$version"
}

# Check if Go is installed (needed for xcaddy)
check_go() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        echo_info "Go is already installed: $GO_VERSION"
        return 0
    else
        echo_warn "Go is not installed. Installing Go..."
        install_go
    fi
}

# Install Go
install_go() {
    GO_VERSION=$(get_latest_go_version)
    GO_DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    
    echo_info "Downloading Go ${GO_VERSION}..."
    echo_info "Download URL: $GO_DOWNLOAD_URL"
    
    if ! curl -fSL "$GO_DOWNLOAD_URL" -o /tmp/go.tar.gz; then
        echo_error "Failed to download Go from $GO_DOWNLOAD_URL"
        echo_error "Please check your internet connection or the URL"
        exit 1
    fi
    
    # Verify download
    if [ ! -f /tmp/go.tar.gz ] || [ ! -s /tmp/go.tar.gz ]; then
        echo_error "Downloaded file is missing or empty"
        exit 1
    fi
    
    echo_info "Installing Go..."
    rm -rf /usr/local/go
    
    if ! tar -C /usr/local -xzf /tmp/go.tar.gz; then
        echo_error "Failed to extract Go archive"
        rm /tmp/go.tar.gz
        exit 1
    fi
    
    rm /tmp/go.tar.gz
    
    # Add Go to PATH
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    # Add to profile
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        echo 'export GOPATH=$HOME/go' >> /etc/profile
        echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile
    fi
    
    # Verify installation
    if ! /usr/local/go/bin/go version; then
        echo_error "Go installation verification failed"
        exit 1
    fi
    
    echo_info "Go installed successfully: $(/usr/local/go/bin/go version)"
}

# Install xcaddy
install_xcaddy() {
    echo_info "Installing xcaddy..."
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    # Create Go binary directory if it doesn't exist
    mkdir -p "$GOPATH/bin"
    
    echo_info "Running: go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest"
    if ! go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest; then
        echo_error "Failed to install xcaddy"
        echo_error "This might be due to network issues or Go configuration problems"
        exit 1
    fi
    
    # Copy xcaddy to /usr/local/bin if it's not there
    if [ -f "$GOPATH/bin/xcaddy" ]; then
        cp "$GOPATH/bin/xcaddy" /usr/local/bin/
        chmod +x /usr/local/bin/xcaddy
        echo_info "xcaddy copied to /usr/local/bin/"
    else
        echo_error "xcaddy binary not found at $GOPATH/bin/xcaddy"
        exit 1
    fi
    
    echo_info "xcaddy installed successfully: $(xcaddy version)"
}

# Build Caddy with Cloudflare DNS module
build_caddy() {
    echo_info "Building Caddy with Cloudflare DNS support..."
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    cd /tmp
    
    # Clean up any previous build
    rm -f /tmp/caddy
    
    echo_info "This may take a few minutes..."
    if [ "$CADDY_VERSION" = "latest" ]; then
        if ! xcaddy build --with "$CF_MODULE"; then
            echo_error "Failed to build Caddy with xcaddy"
            echo_error "Check the output above for specific error messages"
            exit 1
        fi
    else
        if ! xcaddy build "$CADDY_VERSION" --with "$CF_MODULE"; then
            echo_error "Failed to build Caddy version $CADDY_VERSION"
            echo_error "Check the output above for specific error messages"
            exit 1
        fi
    fi
    
    # Verify the binary was created
    if [ ! -f /tmp/caddy ]; then
        echo_error "Caddy binary was not created at /tmp/caddy"
        exit 1
    fi
    
    echo_info "Caddy built successfully"
}

# Install Caddy binary
install_caddy() {
    echo_info "Installing Caddy to $INSTALL_DIR..."
    
    # Stop Caddy if it's running
    if systemctl is-active --quiet caddy; then
        echo_info "Stopping existing Caddy service..."
        systemctl stop caddy
    fi
    
    # Install the binary
    mv /tmp/caddy "$INSTALL_DIR/caddy"
    chmod +x "$INSTALL_DIR/caddy"
    
    # Set capabilities for binding to privileged ports
    setcap 'cap_net_bind_service=+ep' "$INSTALL_DIR/caddy"
    
    echo_info "Caddy binary installed"
}

# Create Caddy user and directories
setup_directories() {
    echo_info "Setting up directories and user..."
    
    # Create user
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

# Example with Cloudflare DNS challenge:
# example.com {
#     tls {
#         dns cloudflare {env.CLOUDFLARE_API_TOKEN}
#     }
#     respond "Hello from Caddy!"
# }

:80 {
    respond "Caddy is running!"
}
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

# Environment file for secrets (optional)
EnvironmentFile=-/etc/caddy/caddy.env

[Install]
WantedBy=multi-user.target
EOF
    
    # Create environment file template
    if [ ! -f "$CONFIG_DIR/caddy.env" ]; then
        cat > "$CONFIG_DIR/caddy.env" << 'EOF'
# Caddy environment variables
# Add your Cloudflare API token here:
# CLOUDFLARE_API_TOKEN=your_token_here
EOF
        chmod 600 "$CONFIG_DIR/caddy.env"
        chown $CADDY_USER:$CADDY_GROUP "$CONFIG_DIR/caddy.env"
        echo_info "Created environment file template at $CONFIG_DIR/caddy.env"
    fi
    
    systemctl daemon-reload
    systemctl enable caddy
    
    echo_info "Systemd service created and enabled"
}

# Verify installation
verify_installation() {
    echo_info "Verifying installation..."
    
    if ! command -v caddy &> /dev/null; then
        echo_error "Caddy installation failed"
        exit 1
    fi
    
    INSTALLED_VERSION=$(caddy version)
    echo_info "Installed: $INSTALLED_VERSION"
    
    # Check if Cloudflare module is available
    if caddy list-modules | grep -q "dns.providers.cloudflare"; then
        echo_info "✓ Cloudflare DNS module is available"
    else
        echo_warn "Cloudflare DNS module not found in module list"
    fi
}

# Main installation function
main() {
    echo_info "Starting Caddy installation with Cloudflare DNS support..."
    
    check_root
    detect_system
    check_go
    install_xcaddy
    build_caddy
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
    echo "  1. Add your Cloudflare API token to: $CONFIG_DIR/caddy.env"
    echo "     CLOUDFLARE_API_TOKEN=your_token_here"
    echo ""
    echo "  2. Configure your Caddyfile at: $CONFIG_DIR/Caddyfile"
    echo "     Example:"
    echo "     example.com {"
    echo "         tls {"
    echo "             dns cloudflare {env.CLOUDFLARE_API_TOKEN}"
    echo "         }"
    echo "         reverse_proxy localhost:8080"
    echo "     }"
    echo ""
    echo "  3. Start Caddy:"
    echo "     systemctl start caddy"
    echo ""
    echo "  4. Check status:"
    echo "     systemctl status caddy"
    echo ""
    echo "  5. View logs:"
    echo "     journalctl -u caddy -f"
    echo ""
}

# Run main function
main
