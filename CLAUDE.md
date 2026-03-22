# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo contains a Dockerfile for running the [fast.ai course part 2](https://github.com/goosmanlei/fastai-course-part2) on RunPod GPU instances:

- `Dockerfile.runpod` — GPU container for RunPod (linux/amd64 only)
- `macpod.sh` — Helper script to manage a local macOS container (references a separately built `macpod-for-fastai-course` image)

## Build

Two tags are maintained, each corresponding to a different base image:

| Tag | Base Image | PyTorch | CUDA | Ubuntu |
|-----|-----------|---------|------|--------|
| `cu1281` | `runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404` | 2.8.0 | 12.8.1 | 24.04 |
| `cu1263` | `runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404` | 2.6.0 | 12.6.3 | 24.04 |

```bash
# cu1281 (default)
docker build --platform linux/amd64 -f Dockerfile.runpod \
  --build-arg BASE_IMAGE=runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404 \
  --build-arg CONSTRAINTS_FILE=constraints-cu1281.txt \
  -t goosmanlei/runpod-learn:cu1281 .

# cu1263
docker build --platform linux/amd64 -f Dockerfile.runpod \
  --build-arg BASE_IMAGE=runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404 \
  --build-arg CONSTRAINTS_FILE=constraints-cu1263.txt \
  -t goosmanlei/runpod-learn:cu1263 .
```

## Run (macpod)

```bash
./macpod.sh          # start / stop / restart / status / logs / rm / shell
# JupyterLab at http://localhost:8001, ~/llmpath mapped to /workspace
```

## Architecture

`Dockerfile.runpod` uses `ARG BASE_IMAGE` and `ARG CONSTRAINTS_FILE` to support multiple tags (default: `runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404`, PyTorch 2.8.0, CUDA 12.8.1, Ubuntu 24.04) and sets up:

- **`work` user** with passwordless sudo (`gosu` used throughout for user-context ops)
- **Python venv** at `/home/work/venvs/llm` (clean, no `--system-site-packages`); torch/torchvision/triton/nvidia_* symlinked from system site-packages
- **Multi-layer pip install** driven by two requirement files:
  - `requirements-fastai.in` — fastai and related libs (Layer 2)
  - `requirements-llm.in` — HuggingFace transformers, diffusers, Gradio, Claude Code CLI (Layer 3)
  - `constraints-cu1281.txt` / `constraints-cu1263.txt` — per-tag pinned versions shared by all layers
- **JupyterLab** on port 8888 (no auth), venv registered as Jupyter kernel via `--user` ipykernel install
- **Chinese font** support (Noto Sans CJK SC) for matplotlib
- **Claude Code CLI** via Node.js 22
- **Course repo** cloned into `/home/work/`: `learning-the-principles-of-llms`
- **`configure.sh`** — user-level config (matplotlib, Jupyter settings, git, shell); runs as `work` via `gosu work /configure.sh` in Layer 6

## Dependency Pinning

Each tag has its own constraints file (`constraints-cu1281.txt`, `constraints-cu1263.txt`).

```bash
# Regenerate per-tag constraints inside a running container:
docker run --rm goosmanlei/runpod-learn:cu1281 bash -c \
  '$VIRTUAL_ENV/bin/pip freeze --exclude-editable' > constraints-cu1281.txt

docker run --rm goosmanlei/runpod-learn:cu1263 bash -c \
  '$VIRTUAL_ENV/bin/pip freeze --exclude-editable' > constraints-cu1263.txt
# Then remove lines starting with `[entrypoint]` and any `@ file:///` lines (symlinked packages)
```

An empty constraints file means no pinning (bootstrap mode).
