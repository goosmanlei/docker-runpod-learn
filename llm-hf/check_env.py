#!/usr/bin/env python3
"""Environment check: CUDA, PyTorch, flash-attn, and common ML libs."""

import importlib
import sys


def check(label, fn):
    try:
        result = fn()
        print(f"  [OK] {label}: {result}")
        return True
    except Exception as e:
        print(f"  [FAIL] {label}: {e}")
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
check("gpu memory (GB)", lambda: f"{torch.cuda.get_device_properties(0).total_memory / 1e9:.1f}" if torch.cuda.is_available() else "N/A")

print()
print("=" * 60)
print("CUDA Compute (tensor op on GPU)")
print("=" * 60)
def _cuda_compute():
    a = torch.randn(1024, 1024, device="cuda")
    b = torch.randn(1024, 1024, device="cuda")
    c = a @ b
    torch.cuda.synchronize()
    return f"matmul 1024x1024 OK, result shape={tuple(c.shape)}"
check("cuda matmul", _cuda_compute)

print()
print("=" * 60)
print("Flash Attention")
print("=" * 60)
def _flash_attn_version():
    import flash_attn
    return flash_attn.__version__

def _flash_attn_compute():
    from flash_attn import flash_attn_func
    import torch
    B, S, H, D = 2, 128, 8, 64
    q = torch.randn(B, S, H, D, device="cuda", dtype=torch.float16)
    k = torch.randn(B, S, H, D, device="cuda", dtype=torch.float16)
    v = torch.randn(B, S, H, D, device="cuda", dtype=torch.float16)
    out = flash_attn_func(q, k, v)
    return f"output shape={tuple(out.shape)}"

check("flash_attn version", _flash_attn_version)
check("flash_attn forward pass", _flash_attn_compute)

print()
print("=" * 60)
print("HuggingFace & ML Libraries")
print("=" * 60)
for lib in [
    "transformers", "datasets", "accelerate", "peft",
    "diffusers", "tokenizers", "safetensors",
    "gradio",
]:
    check(lib, lambda l=lib: pkg_version(l))

print()
print("=" * 60)
print("bitsandbytes (quantization)")
print("=" * 60)
def _bnb_check():
    import bitsandbytes as bnb
    return f"version={bnb.__version__}"
check("bitsandbytes", _bnb_check)

print()
print("=" * 60)
print("triton")
print("=" * 60)
check("triton", lambda: pkg_version("triton"))

print()
print("Done.")
