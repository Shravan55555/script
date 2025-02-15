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

# Updated Telegram message function with message editing
update_build_status() {
    local status="$1"
    local progress="$2"
    local current_time=$(date "+%H:%M:%S %Z")
    
    local message="🛠️ *CRAVE BUILD STATUS* 🛠️%0A%0A"
    message+="📅 *Date:* \`$(date "+%A, %d %B %Y")\`%0A"
    message+="⏰ *Time:* \`${current_time}\`%0A"
    message+="📱 *ROM:* \`${romcuy}\`%0A"
    message+="📲 *Device:* \`${dcdnm}\`%0A%0A"
    message+="*Current Status:* ${status}%0A"
    message+="${progress}"

    if [ -z "$build_msg_id" ]; then
        # Send initial message and store message ID
        build_msg_id=$(curl -s -X POST "https://api.telegram.org/bot${btoken}/sendMessage" \
            -d "chat_id=${id_ch}" \
            -d "text=${message}" \
            -d "parse_mode=MarkdownV2" \
            -d "disable_web_page_preview=true" | jq -r '.result.message_id')
    else
        # Update existing message
        curl -s -X POST "https://api.telegram.org/bot${btoken}/editMessageText" \
            -d "chat_id=${id_ch}" \
            -d "message_id=${build_msg_id}" \
            -d "text=${message}" \
            -d "parse_mode=MarkdownV2" \
            -d "disable_web_page_preview=true"
    fi
}

# Send Log with Telegram
stf() {
    local caption="$1"
    local cid="$2"
    local log_file="${3:-hiya.txt}"
    curl -s -L -F document=@"$(pwd)/${log_file}" -F parse_mode="MarkdownV2" -F caption="$caption" -X POST https://api.telegram.org/bot$btoken/sendDocument -F chat_id=$cid
}

# Monitor build progress
monitor_build_progress() {
    local start_time=$(date +%s)
    local last_size=0
    local current_size=0
    
    while true; do
        if [ -d "out/target/product/${dcdnm}" ]; then
            current_size=$(du -s "out/target/product/${dcdnm}" | cut -f1)
            local elapsed=$(($(date +%s) - start_time))
            local hours=$((elapsed / 3600))
            local minutes=$(((elapsed % 3600) / 60))
            local seconds=$((elapsed % 60))
            
            # Calculate build speed
            local size_diff=$((current_size - last_size))
            local speed=$((size_diff / 60)) # MB per minute
            
            local progress="⏱️ *Elapsed Time:* \`${hours}h ${minutes}m ${seconds}s\`%0A"
            progress+="📊 *Build Size:* \`$((current_size / 1024)) MB\`%0A"
            [ $speed -gt 0 ] && progress+="⚡ *Build Speed:* \`${speed} MB/min\`"
            
            update_build_status "🏗️ Building\.\.\." "$progress"
            last_size=$current_size
        fi
        sleep 60
    done
}

# Start Build Process
print_section "CRAVE BUILD STARTING" "${PURPLE}"
log_info "Build process initiated"

# Initial status update
update_build_status "🌟 Initializing Build" ""

# Start progress monitoring in background
monitor_build_progress &
monitor_pid=$!

# Clean previous build
print_section "CLEANING ENVIRONMENT" "${CYAN}"
{
    log_info "Cleaning previous build artifacts..."
    rm -rf .repo/local_manifests || log_error "Failed to remove local_manifests"
    update_build_status "🧹 Cleaning Environment" ""
}

# Clone local_manifests
print_section "CLONING REPOSITORIES" "${YELLOW}"
{
    log_info "Cloning local_manifests..."
    git clone $(echo $lmfests) -b $(echo $blmfests) .repo/local_manifests || log_error "Failed to clone local_manifests"
    update_build_status "📥 Cloning Repositories" ""
    
    log_info "Initializing repo..."
    repo init -u $(echo $admfests) -b $(echo $badmfests) --git-lfs || log_error "Failed to initialize repo"
    
    log_info "Syncing repositories..."
    /opt/crave/resync.sh || repo sync || log_error "Failed to sync repositories"
}

# Setup build environment
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
