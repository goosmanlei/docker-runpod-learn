# llm-general Maintenance Notes

This image is a personal RunPod learning image. Keep this file short and practical; it is not a full spec.

## Current Intent

- Use `work` as the default runtime user.
- Use Miniforge/mamba with the environment at `/home/work/miniforge3/envs/llm-general`.
- Keep `torch`, `torchvision`, and `torchaudio` pinned per CUDA tag through `constraints-torch-*.txt`.
- Do not pin the general Python dependency set. Add ordinary packages to `requirements-general.in`.
- Do not bake secrets, SSH keys, or personal tokens into the image.
- Default runtime clone/pull is `https://github.com/goosmanlei/aigc-sprint.git` to `/home/work/aigc-sprint`.
- Keep private repository access token-based through `GITHUB_PERSONAL_ACCESS_TOKEN`; do not bake tokens into the image or remote URL.
- At runtime, `entrypoint.sh` stores the GitHub auth header in the startup repo's local Git config so manual `git pull` works inside the container.

## Maintained Tags

- `cu1281`: `runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404`, PyTorch `2.8.0+cu128`
- `cu1263`: `runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404`, PyTorch `2.6.0+cu126`

## Build

From the repository root:

```bash
./llm-general/build-push-commit.sh --build-only
```

Without `--build-only`, the script builds, pushes both tags, then commits and pushes source changes if any exist.

## Quick Checks

```bash
docker run --rm goosmanlei/runpod-learn-general:cu1281 bash -lc \
  'python -c "import torch, jupyterlab, imageio, imageio_ffmpeg; print(torch.__version__); print(jupyterlab.__version__)"'

docker run --rm goosmanlei/runpod-learn-general:cu1263 bash -lc \
  'python -c "import torch, jupyterlab, imageio, imageio_ffmpeg; print(torch.__version__); print(jupyterlab.__version__)"'
```

## Files To Touch

- `Dockerfile.runpod`: system, conda, torch, runtime, SSH, and default command setup.
- `requirements-general.in`: ordinary Python packages.
- `constraints-torch-cu1281.txt` and `constraints-torch-cu1263.txt`: only Torch-family long-term pins.
- `entrypoint.sh`: runtime secrets, SSH key injection, optional startup git clone/pull.
- `configure.sh`: user-level Jupyter, matplotlib, and shell configuration.
- `build-push-commit.sh`: build/push workflow.
