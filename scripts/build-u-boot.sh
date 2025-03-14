#!/bin/bash

# Function to print log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get parameters from the main script
WORKSPACE_DIR=$1
BUILD_DIR=$2
LOG_FILE=$3

# Step 1: Clone repositories and prepare environment
log "✅ Preparing U-Boot build environment..."
cd "$BUILD_DIR"

# Download rkbin library
if [[ ! -d "rkbin" ]]; then
    log "📥 Cloning rkbin repository..."
    git clone --depth=1 --branch=master https://github.com/rockchip-linux/rkbin && log "✅ rkbin repository successfully cloned."
else
    log "⚠️ rkbin repository already exists. Skipping clone."
fi

# Download U-Boot library
if [[ ! -d "u-boot" ]]; then
    log "📥 Cloning U-Boot repository..."
    git clone --depth=1 --branch=rk3566 https://github.com/BigfootACA/u-boot && log "✅ U-Boot repository successfully cloned."
else
    log "⚠️ U-Boot repository already exists. Skipping clone."
fi

# Apply overlay modifications
OVERLAY_DIR="$WORKSPACE_DIR/overlay"
if [[ -d "$OVERLAY_DIR" ]]; then
    log "🔄 Applying overlay modifications..."
    cp -rT "$OVERLAY_DIR" "$BUILD_DIR/"
    log "✅ Overlay applied successfully."
else
    log "⚠️ No overlay directory found. Skipping overlay application."
fi

# Step 2: Build U-Boot
log "🚀 Building U-Boot..."
cd "$BUILD_DIR/u-boot"
export BL31=../rkbin/bin/rk35/rk3568_bl31_v1.44.elf
export ROCKCHIP_TPL=../rkbin/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin
make lckfb-tspi-rk3566_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Step 3: Validate output files
log "🔍 Checking generated files..."
REQUIRED_FILES=(
    "$BUILD_DIR/u-boot/u-boot-rockchip.bin"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        log "⚠️ Warning: Missing file $file"
        exit 1
    fi
done

log "✅ All required files found!"

# Step 4: Prepare output folder
OUTPUT_DIR="$WORKSPACE_DIR/output/u-boot"
if [[ -d "$OUTPUT_DIR" ]]; then
    log "⚠️ The output folder already exists. Deleting it..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

# Step 5: Copy generated files
log "📄 Copying generated files to output directory..."
cp "$BUILD_DIR/u-boot/u-boot-rockchip.bin" "$OUTPUT_DIR/"

log "✅ U-Boot build process completed successfully!"
