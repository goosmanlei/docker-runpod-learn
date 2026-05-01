#!/bin/bash
set -e

chown work:work /workspace 2>/dev/null || true

NVML_PATH=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so
NVML_VERSIONED=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1
if [ -f "$NVML_VERSIONED" ] && [ ! -e "$NVML_PATH" ]; then
    ln -sf "$NVML_VERSIONED" "$NVML_PATH" 2>/dev/null || true
fi

if [ -n "$LEIGUOGUO_MBP_M5_RSA_PUB" ]; then
    mkdir -p /home/work/.ssh
    printf '%s\n' "$LEIGUOGUO_MBP_M5_RSA_PUB" > /home/work/.ssh/authorized_keys
    chown -R work:work /home/work/.ssh
    chmod 700 /home/work/.ssh
    chmod 600 /home/work/.ssh/authorized_keys
fi

{
    [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && printf 'export GITHUB_PERSONAL_ACCESS_TOKEN=%q\n' "$GITHUB_PERSONAL_ACCESS_TOKEN"
    [ -n "$HF_TOKEN" ] && printf 'export HF_TOKEN=%q\n' "$HF_TOKEN"
} > /home/work/.env_runpod
chown work:work /home/work/.env_runpod
chmod 600 /home/work/.env_runpod

if [ -n "$STARTUP_GIT_REPO" ]; then
    STARTUP_GIT_DIR=${STARTUP_GIT_DIR:-/home/work/project}
    CLONE_URL=$STARTUP_GIT_REPO
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
        case "$STARTUP_GIT_REPO" in
            https://github.com/*)
                CLONE_URL="https://${GITHUB_PERSONAL_ACCESS_TOKEN}@${STARTUP_GIT_REPO#https://}"
                ;;
        esac
    fi

    if [ ! -d "$STARTUP_GIT_DIR/.git" ]; then
        echo "[entrypoint] Cloning STARTUP_GIT_REPO into $STARTUP_GIT_DIR..."
        gosu work git clone "$CLONE_URL" "$STARTUP_GIT_DIR" || true
    else
        echo "[entrypoint] Pulling latest in $STARTUP_GIT_DIR..."
        gosu work git -C "$STARTUP_GIT_DIR" pull --ff-only 2>&1 || true
    fi
fi

/usr/sbin/sshd

exec gosu work "$@"
