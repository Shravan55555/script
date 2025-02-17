#!/bin/bash

# Export timezone
export TZ=Asia/Kolkata

# Export Configuration
export romcuy="Pixelage"
export dcdnm="RMX1901"
export id_ch="-1001983626693"
export id_owner="-1001983626693"
export btoken="7602341657:AAF98-rFsXus2aSHRezf8HApeZvPkrgsjZM"
export lmfests="https://github.com/shravansayz/local_manifests"
export blmfests="pixelage"
export admfests="https://github.com/ProjectPixelage/android_manifest"
export badmfests="15"
export jembod="mka bacon"

# Colors for visual feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize build status message ID
build_msg_id=""

# Error logging function
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S'): ${message}${NC}" | tee -a build_error.log
}

# Success logging function
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S'): ${message}${NC}" | tee -a build.log
}

# Info logging function
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO] $(date '+%Y-%m-%d %H:%M:%S'): ${message}${NC}" | tee -a build.log
}

# Section header function
print_section() {
    local title="$1"
    local color="$2"
    echo -e "\n${color}${BOLD}✧ ${title} ✧${NC}\n"
}

# Function to get repository size
get_repo_size() {
    local repo_url="$1"
    local size=$(curl -sI "$repo_url" | grep -i content-length | awk '{print $2}' | tr -d '\r')
    if [ -n "$size" ]; then
        echo "$(($size / 1024 / 1024)) MB"
    else
        echo "Size unknown"
    fi
}

# Function to send cloning status message
send_clone_status() {
    local message="🔄 *REPOSITORY CLONING STATUS* 🔄%0A%0A"
    message+="📅 *Date:* \`$(date "+%A, %d %B %Y")\`%0A"
    message+="⏰ *Time:* \`$(date "+%H:%M:%S %Z")\`%0A"
    message+="📱 *ROM:* \`${romcuy}\`%0A"
    message+="📲 *Device:* \`${dcdnm}\`%0A%0A"
    message+="*Repository Status:*%0A%0A"
    
    # Add local manifests status
    local_size=$(get_repo_size "$lmfests")
    message+="1️⃣ *Local Manifests*%0A"
    message+="📦 Repo: \`${lmfests}\`%0A"
    message+="🔖 Branch: \`${blmfests}\`%0A"
    message+="📊 Size: \`${local_size}\`%0A"
    message+="⏳ Status: Cloning\.\.\.%0A%0A"
    
    curl -s -X POST "https://api.telegram.org/bot${btoken}/sendMessage" \
        -d "chat_id=${id_ch}" \
        -d "text=${message}" \
        -d "parse_mode=MarkdownV2" \
        -d "disable_web_page_preview=true"
}

# Function to update clone status
update_clone_status() {
    local step="$1"
    local status="$2"
    local message="🔄 *REPOSITORY CLONING STATUS* 🔄%0A%0A"
    message+="📅 *Date:* \`$(date "+%A, %d %B %Y")\`%0A"
    message+="⏰ *Time:* \`$(date "+%H:%M:%S %Z")\`%0A"
    message+="📱 *ROM:* \`${romcuy}\`%0A"
    message+="📲 *Device:* \`${dcdnm}\`%0A%0A"
    message+="*Repository Status:*%0A%0A"
    
    local_size=$(get_repo_size "$lmfests")
    message+="1️⃣ *Local Manifests*%0A"
    message+="📦 Repo: \`${lmfests}\`%0A"
    message+="🔖 Branch: \`${blmfests}\`%0A"
    message+="📊 Size: \`${local_size}\`%0A"
    
    case "$step" in
        "local_manifest")
            message+="✅ Status: Cloned Successfully%0A%0A"
            ;;
        "repo_init")
            message+="✅ Status: Cloned Successfully%0A%0A"
            message+="2️⃣ *Main Repository*%0A"
            message+="📦 Repo: \`${admfests}\`%0A"
            message+="🔖 Branch: \`${badmfests}\`%0A"
            if [ "$status" = "started" ]; then
                message+="⏳ Status: Initializing\.\.\.%0A%0A"
            else
                message+="✅ Status: Initialized Successfully%0A%0A"
            fi
            ;;
        "repo_sync")
            message+="✅ Status: Cloned Successfully%0A%0A"
            message+="2️⃣ *Main Repository*%0A"
            message+="📦 Repo: \`${admfests}\`%0A"
            message+="🔖 Branch: \`${badmfests}\`%0A"
            message+="✅ Status: Initialized Successfully%0A"
            if [ "$status" = "started" ]; then
                message+="⏳ Status: Syncing Repositories\.\.\.%0A"
                message+="📊 Total Size: \`Calculating\.\.\.\`%0A%0A"
            else
                local sync_size=$(du -sh .repo | cut -f1)
                message+="✅ Status: Sync Completed%0A"
                message+="📊 Total Size: \`${sync_size}\`%0A%0A"
            fi
            ;;
    esac

    curl -s -X POST "https://api.telegram.org/bot${btoken}/sendMessage" \
        -d "chat_id=${id_ch}" \
        -d "text=${message}" \
        -d "parse_mode=MarkdownV2" \
        -d "disable_web_page_preview=true"
}

# Clone repositories
print_section "CLONING REPOSITORIES" "${YELLOW}"
{
    # Start cloning local_manifests
    log_info "Cloning local_manifests..."
    send_clone_status
    
    if git clone $(echo $lmfests) -b $(echo $blmfests) .repo/local_manifests; then
        log_success "Successfully cloned local_manifests"
        update_clone_status "local_manifest" "success"
    else
        log_error "Failed to clone local_manifests"
        exit 1
    fi
    
    # Initialize repo
    log_info "Initializing repo..."
    update_clone_status "repo_init" "started"
    
    if repo init -u $(echo $admfests) -b $(echo $badmfests) --git-lfs; then
        log_success "Successfully initialized repo"
        update_clone_status "repo_init" "success"
    else
        log_error "Failed to initialize repo"
        exit 1
    fi
    
    # Sync repositories
    log_info "Syncing repositories..."
    update_clone_status "repo_sync" "started"
    
    if /opt/crave/resync.sh || repo sync; then
        log_success "Successfully synced repositories"
        update_clone_status "repo_sync" "success"
    else
        log_error "Failed to sync repositories"
        exit 1
    fi
}

# Setup build environment
# Rest of your build script remains the same...
print_section "SETTING UP BUILD ENVIRONMENT" "${GREEN}"
{
    log_info "Configuring build environment..."
    export BUILD_USERNAME=shravan
    export BUILD_HOSTNAME=crave
    source build/envsetup.sh || log_error "Failed to setup build environment"
    update_build_status "⚙️ Setting up Environment" ""
}

# Start the build
print_section "STARTING ROM BUILD" "${PURPLE}"
{
    log_info "Configuring build target..."
    lunch pixelage_$(echo $dcdnm)-ap4a-user || log_error "Failed to configure lunch"
    update_build_status "🏗️ Starting Build Process" ""

    log_info "Starting build process..."
    $(echo $jembod) || log_error "Build failed"
}

# Kill progress monitoring
kill $monitor_pid

# Check build status
if [ -f "out/target/product/${dcdnm}/*.zip" ]; then
    print_section "BUILD COMPLETED SUCCESSFULLY" "${GREEN}"
    log_success "Build completed successfully"
    update_build_status "✅ Build Completed Successfully" ""
else
    print_section "BUILD FAILED" "${RED}"
    log_error "Build failed - no output file found"
    update_build_status "❌ Build Failed" ""
fi

# Send logs
print_section "SENDING BUILD LOGS" "${BLUE}"
log_info "Sending build logs..."
stf "*Build Logs*" "$id_ch" "build.log"
[ -f "build_error.log" ] && stf "*Error Logs*" "$id_ch" "build_error.log"

print_section "BUILD PROCESS COMPLETED" "${PURPLE}"
