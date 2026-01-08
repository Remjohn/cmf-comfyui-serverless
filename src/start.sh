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

# Link custom nodes from network volume (Critical for Wan 2.2)
if [ -d "/workspace/custom_nodes" ]; then
    echo "worker-comfyui: Linking custom nodes from volume..."
    for dir in /workspace/custom_nodes/*; do
        if [ -d "$dir" ]; then
            ln -s "$dir" "/comfyui/custom_nodes/$(basename "$dir")" || echo "Failed to link $dir"
        fi
    done
elif [ -d "/runpod-volume/custom_nodes" ]; then
     # Fallback check
    echo "worker-comfyui: Linking custom nodes from fallback /runpod-volume..."
    for dir in /runpod-volume/custom_nodes/*; do
        if [ -d "$dir" ]; then
            ln -s "$dir" "/comfyui/custom_nodes/$(basename "$dir")" || echo "Failed to link $dir"
        fi
    done
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