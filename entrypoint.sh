#!/bin/bash

# Fix NVML library path for btop GPU monitoring.
# The NVIDIA container runtime injects libnvidia-ml.so.1 at startup,
# but btop 1.2.x (Ubuntu 22.04 apt) looks for libnvidia-ml.so (unversioned).
# Creating the symlink here (at runtime) makes GPU info visible in btop.
NVML_PATH=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so
NVML_VERSIONED=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
if [ -f "$NVML_VERSIONED" ] && [ ! -e "$NVML_PATH" ]; then
    ln -sf "$NVML_VERSIONED" "$NVML_PATH" 2>/dev/null || true
fi

# Pull latest course repo on each container start
echo "[entrypoint] Pulling latest fastai-course-part2..."
git -C /root/fastai-course-part2 pull --ff-only 2>&1 || true

exec "$@"
