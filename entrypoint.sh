#!/bin/bash

# Fix /workspace ownership so work user can write to it
chown work:work /workspace 2>/dev/null || true

# Fix NVML library path for btop GPU monitoring.
# The NVIDIA container runtime injects libnvidia-ml.so.1 at startup,
# but btop 1.2.x (Ubuntu 22.04 apt) looks for libnvidia-ml.so (unversioned).
# Creating the symlink here (at runtime) makes GPU info visible in btop.
NVML_PATH=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so
NVML_VERSIONED=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
if [ -f "$NVML_VERSIONED" ] && [ ! -e "$NVML_PATH" ]; then
    ln -sf "$NVML_VERSIONED" "$NVML_PATH" 2>/dev/null || true
fi

# Clone or pull course repo as work user
if [ ! -d /home/work/learning-the-principles-of-llms/.git ]; then
    echo "[entrypoint] Cloning learning-the-principles-of-llms..."
    gosu work git clone https://github.com/goosmanlei/learning-the-principles-of-llms.git /home/work/learning-the-principles-of-llms || true
else
    echo "[entrypoint] Pulling latest learning-the-principles-of-llms..."
    gosu work git -C /home/work/learning-the-principles-of-llms pull --ff-only 2>&1 || true
fi

# Drop to work user for the main process (gosu preserves signals)
exec gosu work "$@"
