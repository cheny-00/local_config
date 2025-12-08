#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
YAZI_VERSION="${YAZI_VERSION:-latest}"
INSTALL_DIR="/usr/local/bin"

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
    
    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo_error "This script only supports Linux systems"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            echo_error "Unsupported architecture: $ARCH"
            echo_error "Supported architectures: x86_64, aarch64"
            exit 1
            ;;
    esac
    
    echo_info "Detected: Linux / $ARCH"
}

# Get latest version from GitHub
get_latest_version() {
    if [ "$YAZI_VERSION" = "latest" ]; then
        echo_info "Fetching latest Yazi version..."
        YAZI_VERSION=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [ -z "$YAZI_VERSION" ]; then
            echo_error "Failed to fetch latest version"
            exit 1
        fi
        echo_info "Latest version: $YAZI_VERSION"
    fi
}

# Download Yazi
download_yazi() {
    echo_info "Downloading Yazi v${YAZI_VERSION}..."
    
    # Yazi releases use musl for better compatibility
    DOWNLOAD_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${ARCH}-unknown-linux-musl.zip"
    
    echo_info "URL: $DOWNLOAD_URL"
    
    # Download to temp directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    if ! curl -L "$DOWNLOAD_URL" -o yazi.zip; then
        echo_error "Failed to download Yazi"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    echo_info "Extracting archive..."
    
    # Check if unzip is installed
    if ! command -v unzip &> /dev/null; then
        echo_info "Installing unzip..."
        apt-get update -qq
        apt-get install -y unzip
    fi
    
    unzip -q yazi.zip
    
    # Find the extracted directory
    EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "yazi-*-unknown-linux-musl" | head -n 1)
    
    if [ -z "$EXTRACT_DIR" ] || [ ! -f "$EXTRACT_DIR/yazi" ]; then
        echo_error "Yazi binary not found in archive"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    cd "$EXTRACT_DIR"
}

# Install Yazi binaries
install_yazi() {
    echo_info "Installing Yazi to $INSTALL_DIR..."
    
    # Backup existing binaries if present
    for bin in yazi ya; do
        if [ -f "$INSTALL_DIR/$bin" ]; then
            echo_info "Backing up existing $bin binary..."
            mv "$INSTALL_DIR/$bin" "$INSTALL_DIR/$bin.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    done
    
    # Install the binaries
    # Yazi comes with two binaries: yazi (the main program) and ya (CLI utility)
    if [ -f "yazi" ]; then
        mv yazi "$INSTALL_DIR/yazi"
        chmod +x "$INSTALL_DIR/yazi"
        echo_info "✓ Installed yazi"
    fi
    
    if [ -f "ya" ]; then
        mv ya "$INSTALL_DIR/ya"
        chmod +x "$INSTALL_DIR/ya"
        echo_info "✓ Installed ya (CLI utility)"
    fi
    
    # Clean up
    cd /
    rm -rf "$TMP_DIR"
    
    echo_info "Yazi binaries installed"
}

# Verify installation
verify_installation() {
    echo_info "Verifying installation..."
    
    if ! command -v yazi &> /dev/null; then
        echo_error "Yazi installation failed - command not found"
        exit 1
    fi
    
    INSTALLED_VERSION=$(yazi --version)
    echo_info "Installed: $INSTALLED_VERSION"
}

# Show optional dependencies info
show_dependencies_info() {
    echo ""
    echo_warn "Optional Dependencies:"
    echo "  For the best experience, consider installing these optional dependencies:"
    echo ""
    echo "  # File preview support"
    echo "  sudo apt install -y ffmpegthumbnailer fd-find ripgrep fzf zoxide imagemagick poppler-utils"
    echo ""
    echo "  # Archive preview"
    echo "  sudo apt install -y jq p7zip-full unrar"
    echo ""
    echo "  # Additional tools"
    echo "  sudo apt install -y bat eza"
    echo ""
}

# Main installation function
main() {
    echo_info "Starting Yazi installation..."
    echo ""
    
    check_root
    detect_system
    get_latest_version
    download_yazi
    install_yazi
    verify_installation
    
    echo ""
    echo_info "=========================================="
    echo_info "Yazi installation completed successfully!"
    echo_info "=========================================="
    echo ""
    echo_info "Quick start:"
    echo ""
    echo "  Run Yazi:"
    echo "    yazi"
    echo ""
    echo "  Show help:"
    echo "    yazi --help"
    echo ""
    echo "  Configuration directory:"
    echo "    ~/.config/yazi/"
    echo ""
    
    show_dependencies_info
    
    echo_info "Documentation: https://yazi-rs.github.io/"
    echo ""
}

# Run main function
main
