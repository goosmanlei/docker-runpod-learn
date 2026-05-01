#!/usr/bin/env python3
"""Environment check for the llm-general RunPod image."""

import importlib
import sys


def check(label, fn):
    try:
        result = fn()
        print(f"  [OK] {label}: {result}")
        return True
    except Exception as exc:
        print(f"  [FAIL] {label}: {exc}")
        return False


def pkg_version(name):
    return importlib.import_module(name).__version__


print("=" * 60)
print("Python")
print("=" * 60)
check("python", lambda: sys.version)

print()
print("=" * 60)
print("PyTorch & CUDA")
print("=" * 60)
import torch

check("torch version", lambda: torch.__version__)
check("cuda available", lambda: torch.cuda.is_available())
check("cuda version", lambda: torch.version.cuda)
check("cudnn version", lambda: torch.backends.cudnn.version())
check("gpu count", lambda: torch.cuda.device_count())
check("gpu name", lambda: torch.cuda.get_device_name(0) if torch.cuda.is_available() else "N/A")
check(
    "gpu memory (GB)",
    lambda: f"{torch.cuda.get_device_properties(0).total_memory / 1e9:.1f}"
    if torch.cuda.is_available()
    else "N/A",
)

print()
print("=" * 60)
print("CUDA Compute")
print("=" * 60)


def _cuda_compute():
    if not torch.cuda.is_available():
        return "N/A"
    a = torch.randn(1024, 1024, device="cuda")
    b = torch.randn(1024, 1024, device="cuda")
    c = a @ b
    torch.cuda.synchronize()
    return f"matmul 1024x1024 OK, result shape={tuple(c.shape)}"


check("cuda matmul", _cuda_compute)

print()
print("=" * 60)
print("ML Libraries")
print("=" * 60)
for lib in [
    "transformers",
    "datasets",
    "accelerate",
    "peft",
    "trl",
    "diffusers",
    "tokenizers",
    "safetensors",
    "huggingface_hub",
    "gradio",
    "numpy",
    "pandas",
    "matplotlib",
    "sklearn",
    "scipy",
    "seaborn",
    "pytest",
    "ruff",
]:
    check(lib, lambda l=lib: pkg_version(l))

print()
print("=" * 60)
print("bitsandbytes")
print("=" * 60)
check("bitsandbytes", lambda: pkg_version("bitsandbytes"))

print()
print("=" * 60)
print("triton")
print("=" * 60)
check("triton", lambda: pkg_version("triton"))

print()
print("Done.")
