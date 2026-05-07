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
    CLONE_URL=${STARTUP_GIT_REPO%/}
    GIT_AUTH_ARGS=()
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [[ "$CLONE_URL" == https://github.com/* ]]; then
        echo "[entrypoint] Using GITHUB_PERSONAL_ACCESS_TOKEN for GitHub clone/pull."
        GITHUB_AUTH_HEADER=$(printf 'x-access-token:%s' "$GITHUB_PERSONAL_ACCESS_TOKEN" | base64 -w 0)
        GIT_AUTH_ARGS=(-c "http.https://github.com/.extraheader=AUTHORIZATION: Basic ${GITHUB_AUTH_HEADER}")
    elif [[ "$CLONE_URL" == https://github.com/* ]]; then
        echo "[entrypoint] GITHUB_PERSONAL_ACCESS_TOKEN is not set; GitHub clone/pull will be anonymous."
    fi

    run_git() {
        gosu work git "${GIT_AUTH_ARGS[@]}" "$@"
    }

    configure_repo_git_auth() {
        if [ ! -d "$STARTUP_GIT_DIR/.git" ]; then
            return
        fi

        if [ -n "$GITHUB_AUTH_HEADER" ]; then
            gosu work git -C "$STARTUP_GIT_DIR" config \
                --local http.https://github.com/.extraheader \
                "AUTHORIZATION: Basic ${GITHUB_AUTH_HEADER}"
        else
            gosu work git -C "$STARTUP_GIT_DIR" config \
                --local --unset-all http.https://github.com/.extraheader 2>/dev/null || true
        fi
    }

    if [ ! -d "$STARTUP_GIT_DIR/.git" ]; then
        echo "[entrypoint] Cloning $CLONE_URL into $STARTUP_GIT_DIR..."
        if ! run_git clone "$CLONE_URL" "$STARTUP_GIT_DIR"; then
            echo "[entrypoint] Failed to clone STARTUP_GIT_REPO into $STARTUP_GIT_DIR." >&2
        fi
        configure_repo_git_auth
    else
        configure_repo_git_auth
        echo "[entrypoint] Pulling latest in $STARTUP_GIT_DIR..."
        if ! run_git -C "$STARTUP_GIT_DIR" pull --ff-only 2>&1; then
            echo "[entrypoint] Failed to pull latest in $STARTUP_GIT_DIR." >&2
        fi
    fi
fi

/usr/sbin/sshd

exec gosu work "$@"
