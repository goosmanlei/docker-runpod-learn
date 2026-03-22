#!/bin/bash

# Fix GPU device numbering (RunPod may mount GPU as /dev/nvidia1 instead of /dev/nvidia0)
/fix-nvidia-dev-on-runpod.sh || true

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

# Clone or pull HuggingFace LLM course repo as work user.
# GITHUB_PERSONAL_ACCESS_TOKEN is injected by RunPod Secrets at runtime.
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    CLONE_URL="https://${GITHUB_PERSONAL_ACCESS_TOKEN}@github.com/goosmanlei/llm-hf.git"
else
    CLONE_URL="https://github.com/goosmanlei/llm-hf.git"
fi

if [ ! -d /home/work/llm-hf/.git ]; then
    echo "[entrypoint] Cloning llm-hf..."
    gosu work git clone "$CLONE_URL" /home/work/llm-hf || true
else
    echo "[entrypoint] Pulling latest llm-hf..."
    gosu work git -C /home/work/llm-hf pull --ff-only 2>&1 || true
fi

# Write RunPod-injected secrets to work user's env file so interactive shells inherit them
{
    [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && printf 'export GITHUB_PERSONAL_ACCESS_TOKEN=%q\n' "$GITHUB_PERSONAL_ACCESS_TOKEN"
    [ -n "$HF_TOKEN" ] && printf 'export HF_TOKEN=%q\n' "$HF_TOKEN"
} > /home/work/.env_runpod
chown work:work /home/work/.env_runpod
chmod 600 /home/work/.env_runpod

# Start sshd on port 22
/usr/sbin/sshd

# Drop to work user for the main process (gosu preserves signals)
exec gosu work "$@"
