#!/bin/bash
set -x

# Define globals
local_version_file="${WINEPREFIX}dosdevices/c:/ProgramData/Avaya/pcadmin_version.txt"
install_zip_path="${WINEPREFIX}dosdevices/c:/"
install_extracted_path="${WINEPREFIX}dosdevices/c:/"
install_setup_path="PC Administration v8_0_0_4/setup.exe"
log_file="${STARTUP_LOGFILE:-${WINEPREFIX}dosdevices/c:/avaya-wine-startapp.log}"
download_url="https://download.avaya.com/tsoweb/partner_acs/PC_Administration_v8_0_0_4.zip"

export WINEARCH="win64"
export WINEDLLOVERRIDES="mscoree=" # Disable Mono installation

log_message() {
    echo "$(date): $1" >>"$log_file"
}

# Pre-initialize Wine
if [ ! -f "${WINEPREFIX}system.reg" ]; then
    echo "WINE: Wine not initialized, initializing"
    wineboot -i
    log_message "WINE: Initialization done"
fi

# Configure Extra Mounts
for x in {d..z}; do
    if test -d "/drive_${x}" && ! test -d "${WINEPREFIX}dosdevices/${x}:"; then
        log_message "DRIVE: drive_${x} found but not mounted, mounting..."
        ln -s "/drive_${x}/" "${WINEPREFIX}dosdevices/${x}:"
    fi
done

# Set Virtual Desktop
cd $WINEPREFIX
if [ "$DISABLE_VIRTUAL_DESKTOP" = "true" ]; then
    log_message "WINE: DISABLE_VIRTUAL_DESKTOP=true - Virtual Desktop mode will be disabled"
    winetricks vd=off
else
    if [ -n "$DISPLAY_WIDTH" ] && [ -n "$DISPLAY_HEIGHT" ]; then
        log_message "WINE: Enabling Virtual Desktop mode with $DISPLAY_WIDTH:$DISPLAY_HEIGHT aspect ratio"
        winetricks vd="$DISPLAY_WIDTH"x"$DISPLAY_HEIGHT"
    else
        log_message "WINE: Enabling Virtual Desktop mode with recommended aspect ratio"
        winetricks vd="900x700"
    fi
fi

# Function to handle errors
handle_error() {
    echo "Error: $1" >>"$log_file"
    start_app # Start app even if there is a problem with the updater
}

fetch_and_install() {
    cd "$install_zip_path" || handle_error "INSTALLER: can't navigate to $install_zip_path"
    log_message "INSTALLER: Downloading Avaya PC Administration"
    curl -L "$download_url" --output "PC_Administration_v8_0_0_4.zip" || handle_error "INSTALLER: Failed to download installer"

    log_message "INSTALLER: Extracting the installer"
    unzip -o "PC_Administration_v8_0_0_4.zip" || handle_error "INSTALLER: Failed to extract the installer"

    log_message "INSTALLER: Running the setup from extracted files"
    WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "$install_setup_path" || handle_error "INSTALLER: Failed to install Avaya PC Administration"
}

start_app() {
    log_message "STARTAPP: Starting Avaya PC Administration"
    wine64 "Program Files (x86)/PARTNER ACS R8.0 PC Administration/Administration/pacsradmin.exe" &
    sleep infinity
}

if [ -f "${WINEPREFIX}drive_c/Program Files (x86)/Avaya/PC Administration/pcadmin.exe" ]; then
    log_message "STARTAPP: Avaya PC Administration is already installed. Starting the application."
    start_app
else # Client currently not installed
    fetch_and_install &&
        start_app
fi
