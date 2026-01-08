#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

# Download/Link models from Network Volume
if [ -f "/scripts/download_models.sh" ]; then
    echo "worker-comfyui: Running model download script..."
    chmod +x /scripts/download_models.sh
    /scripts/download_models.sh
fi

# --- AUTO-DETECT CUSTOM NODES ---
if [ -d "/runpod-volume/custom_nodes" ]; then
    CN_SOURCE="/runpod-volume/custom_nodes"
elif [ -d "/workspace/custom_nodes" ]; then
    CN_SOURCE="/workspace/custom_nodes"
else
    CN_SOURCE=""
fi

if [ -n "$CN_SOURCE" ]; then
    echo "worker-comfyui: Linking custom nodes from $CN_SOURCE..."
    for dir in "$CN_SOURCE"/*; do
        if [ -d "$dir" ]; then
            ln -s "$dir" "/comfyui/custom_nodes/$(basename "$dir")" || echo "Failed to link $dir"
        fi
    done
else
    echo "worker-comfyui: No custom_nodes folder found in Volume."
fi

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi