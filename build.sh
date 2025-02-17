#!/bin/bash

#Export timezone
export TZ=Asia/Kolkata

#Export Configuration
export romcuy="Pixelage"
export dcdnm="RMX1901"
export botuname="cravebuild_bot"
export id_ch="-1001983626693"
export id_owner="-1001983626693"
export btoken="7602341657:AAF98-rFsXus2aSHRezf8HApeZvPkrgsjZM"
export lmfests="https://github.com/shravansayz/local_manifests"
export blmfests="pixelage"
export admfests="https://github.com/ProjectPixelage/android_manifest"
export badmfests="15"
export jembod="mka bacon"

#Notify with Telegram Function
stm() {
    local message="$1"
    local cid="$2"
    curl -s -X POST https://api.telegram.org/bot$btoken/sendMessage -d chat_id=$cid -d text="$message" -d disable_web_page_preview="True" -d parse_mode="MarkdownV2"
}

#Send File with Telegram
stf() {
    local file="$1"
    local caption="$2"
    local cid="$3"
    curl -s -L -F document=@"$file" -F parse_mode="MarkdownV2" -F caption="$caption" -X POST https://api.telegram.org/bot$btoken/sendDocument -F chat_id=$cid
}

#Create Build Log
build_log="build_$(date +%Y%m%d_%H%M%S).log"
error_log="error_$(date +%Y%m%d_%H%M%S).log"

#TG Start
echo "🚀 Build Process Started"
stm "🔥 *ROM Build Initiated* 🔥%0A%0A📅 *Date:* _$(date "+%A, %d %B %Y")_%0A⏰ *Time:* _$(date "+%H:%M:%S %Z")_%0A📱 *ROM:* _${romcuy}_%0A📲 *Device:* _${dcdnm}_%0A%0A👨‍💻 *Builder:* @Shravansayz%0A💝 *Support:* [Donate](https://saweria.co/shravansayz)" "$id_ch"

# Remove some stuffs
echo "🗑️ Cleaning workspace..."
rm -rf .repo/local_manifests
stm "🔄 *Build Progress Update*%0A%0A🗑️ Cleaning workspace%0A📥 Cloning manifests \.\.\." "$id_ch"

# Clone local_manifests repository
echo "📥 Cloning local manifests..."
git clone $lmfests -b $blmfests .repo/local_manifests 2>>$error_log
stm "🔄 *Build Progress Update*%0A%0A✅ Workspace cleaned%0A✅ Manifests cloned%0A🔄 Initializing repo \.\.\." "$id_ch"

# Initialize repo
echo "🔄 Initializing repository..."
repo init -u $admfests -b $badmfests --git-lfs 2>>$error_log
stm "🔄 *Build Progress Update*%0A%0A✅ Workspace cleaned%0A✅ Manifests cloned%0A✅ Repo initialized%0A🔄 Syncing repositories \.\.\." "$id_ch"

# Sync the repositories
echo "🔄 Syncing repositories..."
/opt/crave/resync.sh 2>>$error_log || repo sync 2>>$error_log
stm "🔄 *Build Progress Update*%0A%0A✅ Workspace cleaned%0A✅ Manifests cloned%0A✅ Repo initialized%0A✅ Repositories synced%0A⚙️ Setting up environment \.\.\." "$id_ch"

# Exports
echo "⚙️ Setting up build environment..."
export BUILD_USERNAME=shravan
export BUILD_HOSTNAME=crave

# Setup build environment
source build/envsetup.sh 2>>$error_log
stm "🔄 *Build Progress Update*%0A%0A✅ Workspace cleaned%0A✅ Manifests cloned%0A✅ Repo initialized%0A✅ Repositories synced%0A✅ Environment setup%0A🏗️ Starting ROM build \.\.\." "$id_ch"

# Building ROM
echo "🏗️ Building ROM..."
{
    lunch pixelage_${dcdnm}-ap4a-user
    $jembod
} 2>&1 | tee -a $build_log

# Check build status
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_status="✅ Build Completed Successfully!"
else
    build_status="❌ Build Failed!"
fi

# Send build completion notification
stm "🏁 *Build Finished* 🏁%0A%0A📱 *Device:* _${dcdnm}_%0A📊 *Status:* _${build_status}_%0A⏱️ *Duration:* _$(date -u -d @$SECONDS +%H:%M:%S)_%0A%0A📋 *Build logs will be sent shortly*" "$id_ch"

# Send logs
if [ -f "$build_log" ]; then
    stf "$build_log" "📊 *Build Log*" "$id_ch"
fi

if [ -f "$error_log" ]; then
    stf "$error_log" "⚠️ *Error Log*" "$id_ch"
fi

echo "🏁 Build process completed!"
