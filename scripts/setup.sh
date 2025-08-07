#!/bin/bash

# Setup Script for Wordle Solver Development Environment
# Installs and configures all necessary tools

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
check_flutter() {
    log_info "Checking Flutter installation..."
    
    if command_exists flutter; then
        local flutter_version=$(flutter --version | head -n1)
        log_success "Flutter is installed: $flutter_version"
        
        # Run flutter doctor
        log_info "Running flutter doctor..."
        flutter doctor
    else
        log_error "Flutter is not installed"
        log_info "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
}

# Check Firebase CLI
check_firebase_cli() {
    log_info "Checking Firebase CLI..."
    
    if command_exists firebase; then
        local firebase_version=$(firebase --version)
        log_success "Firebase CLI is installed: $firebase_version"
        
        # Check if logged in
        if firebase projects:list > /dev/null 2>&1; then
            log_success "Firebase CLI is authenticated"
        else
            log_warning "Firebase CLI is not authenticated"
            log_info "Please run: firebase login"
        fi
    else
        log_error "Firebase CLI is not installed"
        log_info "Please install it with: npm install -g firebase-tools"
        exit 1
    fi
}

# Check Google Cloud CLI
check_gcloud() {
    log_info "Checking Google Cloud CLI..."
    
    if command_exists gcloud; then
        local gcloud_version=$(gcloud --version | head -n1)
        log_success "Google Cloud CLI is installed: $gcloud_version"
        
        # Check authentication
        if gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
            log_success "Google Cloud CLI is authenticated"
        else
            log_warning "Google Cloud CLI is not authenticated"
            log_info "Please run: gcloud auth login"
        fi
    else
        log_warning "Google Cloud CLI is not installed"
        log_info "Install from: https://cloud.google.com/sdk/docs/install"
        log_info "This is optional but recommended for advanced operations"
    fi
}

# Setup Flutter dependencies
setup_flutter() {
    log_info "Setting up Flutter dependencies..."
    
    # Clean and get dependencies
    flutter clean
    flutter pub get
    
    # Enable web support
    flutter config --enable-web
    
    log_success "Flutter dependencies configured"
}

# Setup Firebase project
setup_firebase_project() {
    log_info "Setting up Firebase project..."
    
    # Check if firebase.json exists
    if [ -f "firebase.json" ]; then
        log_success "Firebase project is already configured"
        
        # Show current project
        local current_project=$(firebase use --project wordle-solver-kyle 2>/dev/null || echo "Not set")
        log_info "Current Firebase project: $current_project"
    else
        log_error "Firebase project not configured"
        log_info "Please run: firebase init"
        exit 1
    fi
}

# Make scripts executable
setup_scripts() {
    log_info "Making scripts executable..."
    
    chmod +x scripts/*.sh
    
    log_success "Scripts are now executable"
}

# Create useful aliases
create_aliases() {
    log_info "Available commands after setup:"
    echo
    echo "  📱 Flutter commands:"
    echo "    flutter run -d web          # Run app in web browser"
    echo "    flutter build web           # Build for web"
    echo "    flutter test               # Run tests"
    echo
    echo "  🔥 Firebase commands:"
    echo "    firebase deploy            # Deploy everything"
    echo "    firebase serve --only hosting  # Local hosting"
    echo
    echo "  🛠️  Custom scripts:"
    echo "    ./scripts/deploy.sh all    # Deploy everything"
    echo "    ./scripts/deploy.sh hosting # Deploy web app only"
    echo "    ./scripts/upload-dictionaries.sh # Upload word lists"
    echo
}

# Main setup function
main() {
    log_info "🚀 Setting up Wordle Solver development environment"
    echo
    
    # Check all required tools
    check_flutter
    check_firebase_cli
    check_gcloud
    
    echo
    
    # Setup project
    setup_flutter
    setup_firebase_project
    setup_scripts
    
    echo
    
    # Show available commands
    create_aliases
    
    log_success "🎉 Setup completed successfully!"
    log_info "You're ready to start developing!"
}

# Run main function
main "$@"
