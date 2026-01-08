#!/bin/bash
set -e

# Define paths
VOLUME_DIR="/workspace"
VOLUME_MODELS="$VOLUME_DIR/models"
COMFY_MODELS="/comfyui/models"

echo "worker-comfyui: Linking existing models from Network Volume..."

# List of standard ComfyUI model subdirectories to link
# We link each folder individually to preserve the structure
SUBDIRS=("checkpoints" "vae" "unet" "clip" "loras" "controlnet" "upscale_models" "embeddings" "diffusers")

if [ -d "$VOLUME_MODELS" ]; then
    for subdir in "${SUBDIRS[@]}"; do
        VOL_PATH="$VOLUME_MODELS/$subdir"
        COMFY_PATH="$COMFY_MODELS/$subdir"

        if [ -d "$VOL_PATH" ]; then
            echo "worker-comfyui: Linking $subdir from Volume..."
            
            # Remove the empty default folder in ComfyUI if it exists
            if [ -d "$COMFY_PATH" ]; then
                rm -rf "$COMFY_PATH"
            fi
            
            # Link the specific folder from volume to ComfyUI
            ln -s "$VOL_PATH" "$COMFY_PATH"
        else
            echo "worker-comfyui: No '$subdir' folder found in Volume. Skipping."
        fi
    done
else
    echo "worker-comfyui: WARNING - No 'models' directory found in Network Volume ($VOLUME_MODELS)."
    echo "worker-comfyui: Assuming models are managed manually or elsewhere."
fi

echo "worker-comfyui: Model linking complete."
