#!/bin/bash

# Firebase Deployment Script for Wordle Solver
# Usage: ./scripts/deploy.sh [target]
# Targets: all, hosting, functions, database, storage, firestore

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

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        log_info "npm install -g firebase-tools"
        exit 1
    fi
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
}

# Build Flutter web app
build_web() {
    log_info "Building Flutter web app..."
    flutter clean
    flutter pub get
    flutter build web --release
    log_success "Flutter web build completed"
}

# Deploy functions
deploy_functions() {
    log_info "Deploying Cloud Functions..."
    firebase deploy --only functions --project wordle-solver-kyle
    log_success "Cloud Functions deployed"
}

# Deploy hosting
deploy_hosting() {
    log_info "Deploying to Firebase Hosting..."
    build_web
    firebase deploy --only hosting --project wordle-solver-kyle
    log_success "Firebase Hosting deployed"
}

# Deploy database rules
deploy_database() {
    log_info "Deploying database rules..."
    firebase deploy --only firestore:rules,storage:rules --project wordle-solver-kyle
    log_success "Database rules deployed"
}

# Deploy Firestore rules only
deploy_firestore() {
    log_info "Deploying Firestore rules..."
    firebase deploy --only firestore:rules --project wordle-solver-kyle
    log_success "Firestore rules deployed"
}

# Deploy Storage rules only
deploy_storage() {
    log_info "Deploying Storage rules..."
    firebase deploy --only storage:rules --project wordle-solver-kyle
    log_success "Storage rules deployed"
}

# Deploy everything
deploy_all() {
    log_info "Deploying everything..."
    build_web
    firebase deploy --project wordle-solver-kyle
    log_success "Complete deployment finished"
}

# Main script logic
main() {
    local target=${1:-"all"}
    
    log_info "🚀 Starting Firebase deployment for target: $target"
    
    # Check prerequisites
    check_firebase_cli
    
    case $target in
        "all")
            check_flutter
            deploy_all
            ;;
        "hosting")
            check_flutter
            deploy_hosting
            ;;
        "functions")
            deploy_functions
            ;;
        "database")
            deploy_database
            ;;
        "firestore")
            deploy_firestore
            ;;
        "storage")
            deploy_storage
            ;;
        *)
            log_error "Unknown target: $target"
            log_info "Available targets: all, hosting, functions, database, firestore, storage"
            exit 1
            ;;
    esac
    
    log_success "🎉 Deployment completed successfully!"
}

# Run main function with all arguments
main "$@"
