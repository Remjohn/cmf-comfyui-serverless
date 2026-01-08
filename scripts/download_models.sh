#!/bin/bash
set -e

# Define model paths
VOLUME_DIR="/runpod-volume"
MODELS_DIR="$VOLUME_DIR/models"
CHECKPOINTS_DIR="$MODELS_DIR/checkpoints"
VAE_DIR="$MODELS_DIR/vae"
UNET_DIR="$MODELS_DIR/unet"
CLIP_DIR="$MODELS_DIR/clip"

mkdir -p "$CHECKPOINTS_DIR"
mkdir -p "$VAE_DIR"
mkdir -p "$UNET_DIR"
mkdir -p "$CLIP_DIR"

echo "worker-comfyui: Checking for models in Network Volume ($VOLUME_DIR)..."

# --- FLUX 1 DEV FP8 ---
FLUX_PATH="$CHECKPOINTS_DIR/flux1-dev-fp8.safetensors"
if [ ! -f "$FLUX_PATH" ]; then
    echo "worker-comfyui: Downloading Flux1 Dev FP8..."
    wget -q -O "$FLUX_PATH" https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors
    echo "worker-comfyui: Downloaded Flux1 Dev FP8."
else
    echo "worker-comfyui: Flux1 Dev FP8 already exists."
fi

# --- SD3 MEDIUM ---
SD3_PATH="$CHECKPOINTS_DIR/sd3_medium_incl_clips_t5xxlfp8.safetensors"
if [ ! -f "$SD3_PATH" ]; then
    echo "worker-comfyui: Downloading SD3 Medium..."
    # Note: Requires HUGGINGFACE_ACCESS_TOKEN env var if repo is gated
    wget -q --header="Authorization: Bearer ${HUGGINGFACE_ACCESS_TOKEN}" -O "$SD3_PATH" https://huggingface.co/stabilityai/stable-diffusion-3-medium/resolve/main/sd3_medium_incl_clips_t5xxlfp8.safetensors
    echo "worker-comfyui: Downloaded SD3 Medium."
else
    echo "worker-comfyui: SD3 Medium already exists."
fi

# --- Symlink models to ComfyUI directory ---
# This ensures ComfyUI sees the models in the volume without copying them
echo "worker-comfyui: Symlinking models to ComfyUI..."

# Remove existing empty directories in ComfyUI to allow symlinking
rm -rf /comfyui/models/checkpoints
rm -rf /comfyui/models/vae
rm -rf /comfyui/models/unet
rm -rf /comfyui/models/clip

# create /comfyui/models if not exists
mkdir -p /comfyui/models

# Link the volume directories
ln -s "$CHECKPOINTS_DIR" /comfyui/models/checkpoints
ln -s "$VAE_DIR" /comfyui/models/vae
ln -s "$UNET_DIR" /comfyui/models/unet
ln -s "$CLIP_DIR" /comfyui/models/clip

echo "worker-comfyui: Model setup complete."
