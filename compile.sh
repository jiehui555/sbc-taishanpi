#!/bin/bash

# Function to print log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Install dependencies
log "📦 Installing required dependencies..."
sudo apt update && sudo apt install -y \
    bash-completion command-not-found git wget xz-utils \
    make gcc gcc-aarch64-linux-gnu \
    python3 python3-dev python3-setuptools python3-pyelftools \
    bison flex swig bc cpio libssl-dev libgnutls28-dev
log "✅ Dependencies installed successfully!"

# Set working directory inside the container
WORKSPACE_DIR=$(pwd)

# Ensure script runs in the correct directory
cd "$WORKSPACE_DIR" || exit 1

# Create build directory
BUILD_DIR="$WORKSPACE_DIR/build"
if [[ -d "$BUILD_DIR" ]]; then
    log "⚠️ Build directory already exists. Please ensure it's clean before proceeding."
else
    mkdir -p "$BUILD_DIR"
    log "📁 Created build directory."
fi

# Create logs directory if it doesn't exist
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"
log "📁 Created logs directory."

# Generate log file with timestamp
LOG_FILE="$LOG_DIR/build_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Redirect all script output to the log file while still showing it in the terminal
exec > >(tee -a "$LOG_FILE") 2>&1

# Error handling function
error_handler() {
    log "❌ An error occurred!"
    log "⚠️ Line number: $1"
    log "📝 Command: $2"
    exit 1
}

# Cleanup function on script exit
cleanup() {
    log "🧹 Cleaning up temporary files..."
}

# Set traps
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR # Catch errors
trap cleanup EXIT                                  # Execute cleanup on exit

# Exit immediately if a command exits with a non-zero status
set -e

# Check the number of command-line arguments
if [ $# -ne 1 ]; then
    log "❌ Usage: $0 [u-boot|kernel]"
    exit 1
fi

# Execute the corresponding operation according to the argument
case "$1" in
    "u-boot")
        log "🚀 Executing U-Boot build script..."
        ./scripts/build-u-boot.sh "$WORKSPACE_DIR" "$BUILD_DIR" "$LOG_FILE"
        log "✅ U-Boot build script executed successfully!"
        ;;
    "kernel")
        log "🚀 Executing Kernel build script..."
        ./scripts/build-kernel.sh "$WORKSPACE_DIR" "$BUILD_DIR" "$LOG_FILE"
        log "✅ Kernel build script executed successfully!"
        ;;
    *)
        log "❌ Invalid argument. Usage: $0 [u-boot|kernel]"
        exit 1
        ;;
esac

log "📜 Log saved to: $LOG_FILE"
