#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

IMAGE="goosmanlei/runpod-learn-general"

# Format: tag|base_image|torch_constraints|torch_index_url
TAGS=(
    "cu1281|runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404|constraints-torch-cu1281.txt|https://download.pytorch.org/whl/cu128"
    "cu1263|runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404|constraints-torch-cu1263.txt|https://download.pytorch.org/whl/cu126"
)

BUILD_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --build-only)
            BUILD_ONLY=true
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $0 [--build-only]" >&2
            exit 2
            ;;
    esac
done

for entry in "${TAGS[@]}"; do
    IFS='|' read -r tag base torch_constraints torch_index <<< "$entry"
    echo "==> Building $IMAGE:$tag"
    echo "    base: $base"
    echo "    torch constraints: $torch_constraints"
    echo "    torch index: $torch_index"
    docker_cmd=(
        docker build --platform linux/amd64 -f Dockerfile.runpod
        --build-arg BASE_IMAGE="$base"
        --build-arg TORCH_CONSTRAINTS_FILE="$torch_constraints"
        --build-arg TORCH_INDEX_URL="$torch_index"
        -t "$IMAGE:$tag" .
    )
    DOCKER_BUILDKIT=1 "${docker_cmd[@]}"
done

if $BUILD_ONLY; then
    echo "==> Build complete. Skipping push and commit because --build-only was set."
    exit 0
fi

for entry in "${TAGS[@]}"; do
    IFS='|' read -r tag base torch_constraints torch_index <<< "$entry"
    echo "==> Pushing $IMAGE:$tag"
    docker push "$IMAGE:$tag"
done

if git diff --quiet && git diff --cached --quiet; then
    echo "==> No changes to commit."
    exit 0
fi

git add -A
git commit -m "chore: update llm-general image files"
git push origin "$(git rev-parse --abbrev-ref HEAD)"
echo "==> Done."
