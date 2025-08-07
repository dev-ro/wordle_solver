#!/bin/bash

# Dictionary Upload Script for Wordle Solver
# Uploads dictionary files from assets/words/ to Firebase Storage

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="wordle-solver-kyle"
BUCKET_NAME="${PROJECT_ID}.appspot.com"
DICTIONARIES_DIR="assets/words"
STORAGE_PATH="dictionaries"

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

# Check if required tools are installed
check_dependencies() {
    # Check for gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud CLI (gcloud) is not installed."
        log_info "Please install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Check for gsutil
    if ! command -v gsutil &> /dev/null; then
        log_error "gsutil is not available. It should come with gcloud CLI."
        exit 1
    fi
    
    # Check for python (for JSON validation)
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        log_warning "Python not found. JSON validation will be skipped."
        VALIDATE_JSON=false
    else
        VALIDATE_JSON=true
    fi
}

# Validate JSON files
validate_json_file() {
    local file=$1
    local filename=$(basename "$file")
    
    if [ "$VALIDATE_JSON" = true ]; then
        log_info "Validating $filename..."
        
        # Try python3 first, then python
        local python_cmd="python3"
        if ! command -v python3 &> /dev/null; then
            python_cmd="python"
        fi
        
        if $python_cmd -m json.tool "$file" > /dev/null 2>&1; then
            # Count words in the JSON array
            local word_count
            if command -v jq &> /dev/null; then
                word_count=$(jq 'length' "$file")
            else
                word_count=$($python_cmd -c "import json; print(len(json.load(open('$file'))))")
            fi
            log_success "$filename is valid JSON with $word_count words"
            return 0
        else
            log_error "$filename is not valid JSON"
            return 1
        fi
    else
        log_warning "Skipping JSON validation for $filename"
        return 0
    fi
}

# Check if user is authenticated with gcloud
check_authentication() {
    log_info "Checking Google Cloud authentication..."
    
    if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
        log_error "Not authenticated with Google Cloud."
        log_info "Please run: gcloud auth login"
        exit 1
    fi
    
    # Set the project
    gcloud config set project "$PROJECT_ID" > /dev/null 2>&1
    log_success "Authenticated and project set to $PROJECT_ID"
}

# Upload dictionaries to Cloud Storage
upload_dictionaries() {
    local dictionaries_dir="$1"
    
    if [ ! -d "$dictionaries_dir" ]; then
        log_error "Dictionaries directory not found: $dictionaries_dir"
        exit 1
    fi
    
    # Find all JSON files
    local json_files=($(find "$dictionaries_dir" -name "*.json" -type f))
    
    if [ ${#json_files[@]} -eq 0 ]; then
        log_warning "No JSON files found in $dictionaries_dir"
        exit 0
    fi
    
    log_info "Found ${#json_files[@]} dictionary files"
    
    # Validate all files first
    local valid_files=()
    for file in "${json_files[@]}"; do
        if validate_json_file "$file"; then
            valid_files+=("$file")
        fi
    done
    
    if [ ${#valid_files[@]} -eq 0 ]; then
        log_error "No valid dictionary files to upload"
        exit 1
    fi
    
    # Create storage directory if it doesn't exist
    log_info "Creating storage directory if needed..."
    gsutil ls "gs://$BUCKET_NAME/$STORAGE_PATH/" > /dev/null 2>&1 || gsutil mkdir "gs://$BUCKET_NAME/$STORAGE_PATH/"
    
    # Upload each valid file
    for file in "${valid_files[@]}"; do
        local filename=$(basename "$file")
        local remote_path="gs://$BUCKET_NAME/$STORAGE_PATH/$filename"
        
        log_info "Uploading $filename..."
        gsutil cp "$file" "$remote_path"
        
        # Set metadata
        gsutil setmeta -h "Content-Type:application/json" "$remote_path"
        gsutil setmeta -h "Cache-Control:public,max-age=3600" "$remote_path"
        
        log_success "Uploaded $filename to $remote_path"
    done
}

# List uploaded files for verification
verify_upload() {
    log_info "Verifying uploaded files..."
    
    if gsutil ls "gs://$BUCKET_NAME/$STORAGE_PATH/" > /dev/null 2>&1; then
        echo
        log_info "Files in Cloud Storage ($STORAGE_PATH/):"
        gsutil ls -l "gs://$BUCKET_NAME/$STORAGE_PATH/"
        echo
    else
        log_warning "Could not list files in storage"
    fi
}

# Deploy storage rules after upload
deploy_storage_rules() {
    log_info "Deploying storage rules..."
    
    if command -v firebase &> /dev/null; then
        firebase deploy --only storage:rules --project "$PROJECT_ID"
        log_success "Storage rules deployed"
    else
        log_warning "Firebase CLI not found. Skipping storage rules deployment."
        log_info "Please run: firebase deploy --only storage:rules"
    fi
}

# Main script logic
main() {
    log_info "🗂️  Starting dictionary upload to Firebase Storage"
    
    # Check all dependencies
    check_dependencies
    
    # Check authentication
    check_authentication
    
    # Upload dictionaries
    upload_dictionaries "$DICTIONARIES_DIR"
    
    # Verify upload
    verify_upload
    
    # Deploy storage rules
    deploy_storage_rules
    
    log_success "🎉 Dictionary upload completed successfully!"
    log_info "📖 Dictionaries are now available in Cloud Storage"
}

# Run main function
main "$@"
