# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo contains a Dockerfile for running the [fast.ai course part 2](https://github.com/goosmanlei/fastai-course-part2) on RunPod GPU instances:

- `Dockerfile.runpod` — GPU container for RunPod (linux/amd64 only)
- `macpod.sh` — Helper script to manage a local macOS container (references a separately built `macpod-for-fastai-course` image)

## Build

```bash
# RunPod image (linux/amd64 only — nvcr.io base has no arm64 variant)
docker build --platform linux/amd64 -f Dockerfile.runpod -t goosmanlei/runpod-learn .
```

## Run (macpod)

```bash
./macpod.sh          # start / stop / restart / status / logs / rm / shell
# JupyterLab at http://localhost:8001, ~/llmpath mapped to /workspace
```

## Architecture

`Dockerfile.runpod` is based on `runpod/pytorch:1.0.3-cu1300-torch290-ubuntu2404` (PyTorch 2.9.0, CUDA 13.0, Ubuntu 24.04) and sets up:

- **`work` user** with passwordless sudo (`gosu` used throughout for user-context ops)
- **Python venv** at `/home/work/venvs/llm` (clean, no `--system-site-packages`); torch/torchvision/triton/nvidia_* symlinked from system site-packages
- **Multi-layer pip install** driven by three requirement files:
  - `requirements-fastai.in` — fastai and related libs (Layer 2)
  - `requirements-llm.in` — HuggingFace transformers, diffusers, etc. (Layer 3)
  - `requirements-extra.in` — Gradio, Claude Code CLI (Layer 4)
  - `constraints.txt` — pinned versions shared by all layers
- **JupyterLab** on port 8888 (no auth), venv registered as Jupyter kernel via `--user` ipykernel install
- **Chinese mirrors** for apt (Aliyun), pip (`PIP_INDEX_URL`), and npm (npmmirror)
- **Chinese font** support (Noto Sans CJK SC) for matplotlib
- **Claude Code CLI** via Node.js 22
- **Course repos** cloned into `/home/work/`: `fastai-course-part2` and `course22p2`
- **`configure.sh`** — user-level config (matplotlib, Jupyter settings, git, shell); runs as `work` via `gosu work /configure.sh` in Layer 6

## Dependency Pinning

```bash
# Regenerate constraints.txt inside a running container:
docker run --rm <image> bash -c '$VIRTUAL_ENV/bin/pip freeze --exclude-editable' > constraints.txt
# Then remove lines starting with `[entrypoint]` and any `@ file:///` lines (symlinked packages)
```

An empty `constraints.txt` means no pinning (bootstrap mode).
