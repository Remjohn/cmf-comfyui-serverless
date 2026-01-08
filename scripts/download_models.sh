#!/bin/bash
set -e

# --- AUTO-DETECT VOLUME ROOT ---
# RunPod Serverless usually mounts to /runpod-volume
# RunPod Pods usually mount to /workspace
# We check both to be safe.

if [ -d "/runpod-volume/models" ]; then
    VOLUME_ROOT="/runpod-volume"
    echo "worker-comfyui: Detected Network Volume at /runpod-volume"
elif [ -d "/workspace/models" ]; then
    VOLUME_ROOT="/workspace"
    echo "worker-comfyui: Detected Network Volume at /workspace"
else
    echo "worker-comfyui: WARNING - Could not find 'models' folder in default locations."
    echo "worker-comfyui: Defaulting to /runpod-volume..."
    VOLUME_ROOT="/runpod-volume"
fi

VOLUME_MODELS="$VOLUME_ROOT/models"
COMFY_MODELS="/comfyui/models"

# --- LINKING LOGIC ---
echo "worker-comfyui: Linking models from $VOLUME_MODELS..."
# List of standard ComfyUI model subdirectories to link
# We link each folder individually to preserve the structure
SUBDIRS=("checkpoints" "vae" "unet" "clip" "loras" "controlnet" "upscale_models" "embeddings" "diffusers" "text_encoders" "clip_vision" "configs" "style_models" "hypernetworks" "photomaker" "vae_approx" "gligen" "diffusion_models" "audio_encoders")

if [ -d "$VOLUME_MODELS" ]; then
    for subdir in "${SUBDIRS[@]}"; do
        VOL_PATH="$VOLUME_MODELS/$subdir"
        COMFY_PATH="$COMFY_MODELS/$subdir"

        if [ -d "$VOL_PATH" ]; then
            echo "worker-comfyui: Linking $subdir..."
            if [ -d "$COMFY_PATH" ]; then rm -rf "$COMFY_PATH"; fi
            ln -s "$VOL_PATH" "$COMFY_PATH"
        else
            echo "worker-comfyui: '$subdir' not found in Volume. Skipping."
        fi
    done
else
    echo "worker-comfyui: ERROR - Models directory not found at $VOLUME_MODELS"
fi

echo "worker-comfyui: Model setup complete."
