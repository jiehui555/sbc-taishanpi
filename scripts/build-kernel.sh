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
log "✅ Preparing Kernel build environment..."
cd "$BUILD_DIR"

# Download Kernel library
if [[ ! -d "linux" ]]; then
    log "📥 Cloning Kernel repository..."
    git clone --depth=1 --branch=rk3566-v6.8 https://github.com/BigfootACA/linux && log "✅ Kernel repository successfully cloned."
    git clone --depth=1 --branch=master https://github.com/armbian/firmware armbian-firmware && log "✅ Armbian firmware repository successfully cloned."
    git clone --depth=1 --branch=master https://github.com/robertfoss/wireless-regdb && log "✅ Wireless driver repository successfully cloned."

    mkdir -p firmware/brcm
    cp armbian-firmware/brcm/BCM43430A1.hcd firmware/brcm/BCM43430A1.lckfb,tspi-v10.hcd
    cp armbian-firmware/brcm/brcmfmac43430-sdio.txt firmware/brcm/brcmfmac43430-sdio.lckfb,tspi-v10.txt
    cp armbian-firmware/brcm/brcmfmac43430-sdio.bin firmware/brcm/brcmfmac43430-sdio.lckfb,tspi-v10.bin
    cp armbian-firmware/brcm/brcmfmac43430-sdio.clm_blob firmware/brcm/brcmfmac43430-sdio.clm_blob
    cp wireless-regdb/regulatory.db.p7s firmware/regulatory.db.p7s
    cp wireless-regdb/regulatory.db firmware/regulatory.db
else
    log "⚠️ linux repository already exists. Skipping clone."
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

# Step 2: Build Kernel
log "🚀 Building Kernel..."
cd "$BUILD_DIR/linux"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- lckfb-tspi-rk3566_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
log "✅ Kernel build completed."

# Step 3: Validate output files
log "🔍 Checking generated files..."

REQUIRED_FILES=(
    "$BUILD_DIR/linux/arch/arm64/boot/Image"
    "$BUILD_DIR/linux/arch/arm64/boot/dts/rockchip/rk3566-lckfb-tspi.dtb"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        log "⚠️ Warning: Missing file $file"
        exit 1
    fi
done

log "✅ All required files found!"

# Step 4: Prepare output folder
OUTPUT_DIR="$WORKSPACE_DIR/output/kernel"
if [[ -d "$OUTPUT_DIR" ]]; then
    log "⚠️ The output folder already exists. Deleting it..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"
log "📁 Created output directory."

# Step 5: Copy generated files
log "📄 Copying generated files to output directory..."
cp "$BUILD_DIR/linux/arch/arm64/boot/Image" "$OUTPUT_DIR/"
cp "$BUILD_DIR/linux/arch/arm64/boot/dts/rockchip/rk3566-lckfb-tspi.dtb" "$OUTPUT_DIR/"

log "✅ Kernel build process completed successfully!"
