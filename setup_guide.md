# llama.cpp + CUDA Setup Guide (RTX 40 Series / Ada GPUs)

A complete, production-ready guide for building **GPU-accelerated `llama.cpp`** with proper runtime linking, optimized compilation, and optional Python integration.

Tested on:

* NVIDIA GeForce RTX 4050 (Ada Lovelace, Compute Capability 8.9)
* Ubuntu / Debian-based Linux
* CUDA Toolkit installed

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Prerequisites](#prerequisites)
3. [Clean Build (Recommended Method)](#clean-build-recommended-method)
4. [Build Configuration Explained](#build-configuration-explained)
5. [Verifying GPU Support](#verifying-gpu-support)
6. [Running a Model (CLI)](#running-a-model-cli)
7. [Python Integration](#python-integration)
8. [Optional Build Variants](#optional-build-variants)
9. [Troubleshooting](#troubleshooting)
10. [Understanding the Build Process](#understanding-the-build-process)

---

# Project Structure

Recommended layout:

```
AI_models_local_setup_llamacpp/
├── llama.cpp/
├── models/
├── run_model_scripts/
├── system_prompts/
└── README.md
```

---

# Prerequisites

### 1. NVIDIA GPU

Verify:

```bash
nvidia-smi
```

You should see your GPU listed.

RTX 40 series GPUs use the **Ada Lovelace architecture** (Compute Capability 8.9 for RTX 4050).

---

### 2. CUDA Toolkit

```bash
nvcc --version
```

If missing, install CUDA before continuing.

---

### 3. Required Packages

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  cmake \
  git \
  libssl-dev
```

Optional (Python integration):

```bash
sudo apt install python3 python3-pip
```

---

# Clean Build (Recommended Method)

Always build from inside the `llama.cpp` directory.

```bash
cd llama.cpp
rm -rf build
```

## Configure (CUDA + Proper Runtime Linking)

```bash
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_FORCE_MMQ=ON \
  -DGGML_NATIVE=ON \
  -DCMAKE_BUILD_RPATH='$ORIGIN' \
  -DCMAKE_INSTALL_RPATH='$ORIGIN'
```

## Build (Parallelized)

```bash
cmake --build build -j$(nproc)
```

This uses all available CPU cores for faster compilation.

---

# Build Configuration Explained

| Flag                       | Purpose                                                |
| -------------------------- | ------------------------------------------------------ |
| `-DGGML_CUDA=ON`           | Enables GPU support                                    |
| `-DGGML_CUDA_FORCE_MMQ=ON` | Optimized CUDA kernels (recommended for RTX 40 series) |
| `-DGGML_NATIVE=ON`         | CPU instruction tuning (AVX2/FMA)                      |
| `$ORIGIN` RPATH            | Prevents shared library errors                         |
| `-j$(nproc)`               | Parallel compilation                                   |

---

## Why `$ORIGIN` Matters

Without it, you may see:

```
libmtmd.so.0 => not found
```

Linux does not automatically search the executable’s directory for shared libraries.

Embedding `$ORIGIN` ensures libraries in `build/bin` are found automatically — no `LD_LIBRARY_PATH` required.

---

# Verifying GPU Support

After building:

```bash
cd build/bin
./llama-cli
```

You should see:

```
ggml_cuda_init: found 1 CUDA devices:
Device 0: NVIDIA GeForce RTX 4050 Laptop GPU
```

If you see:

```
no usable GPU found
```

You likely forgot `-DGGML_CUDA=ON`.

---

# Running a Model (CLI)

From project root:

```bash
./llama.cpp/build/bin/llama-cli \
  --model models/your_model.gguf \
  -ngl 999
```

### Key Options

| Option        | Description                       |
| ------------- | --------------------------------- |
| `--model`     | Path to GGUF model                |
| `-ngl`        | Number of layers offloaded to GPU |
| `-t`          | CPU threads                       |
| `--n-predict` | Number of tokens to generate      |

---

## Choosing `-ngl`

* `-ngl 999` → Offload as much as possible to GPU
* `-ngl 0` → CPU-only

For 6GB RTX 4050, most 8B Q4 models fit fully on GPU.

---

# Python Integration

## Build Python Bindings

```bash
cd llama.cpp
make py
```

## Install

```bash
pip install ./python
```

## Example

```python
from llama_cpp import Llama

llm = Llama(
    model_path="models/your_model.gguf",
    n_gpu_layers=999
)

output = llm("Hello from Python!")
print(output["choices"][0]["text"])
```

GPU acceleration works the same way as CLI.

---

# Optional Build Variants

### Disable Examples & Tests (Faster Build)

```bash
-DLLAMA_BUILD_TESTS=OFF \
-DLLAMA_BUILD_EXAMPLES=OFF
```

---

### Static Build (No Shared Libraries)

```bash
-DBUILD_SHARED_LIBS=OFF
```

Pros:

* No runtime `.so` issues
* Fully portable

Cons:

* Larger binary

---

### Target Specific GPU Architecture (Advanced)

RTX 4050 = Compute Capability 8.9

```bash
-DGGML_CUDA_ARCH=89
```

Usually not required — auto-detected correctly in most cases.

---

# Troubleshooting

---

## 1. `libmtmd.so.0 => not found`

**Cause:** Missing RPATH.

**Fix:** Rebuild with:

```bash
-DCMAKE_BUILD_RPATH='$ORIGIN'
```

---

## 2. `no usable GPU found`

**Cause:** CPU-only build.

**Fix:** Rebuild with:

```bash
-DGGML_CUDA=ON
```

---

## 3. GPU worked before but stopped after rebuild

Deleting `build/` removes CMake cache and all flags.

You must re-specify CUDA flags every time.

---

## 4. CMake error: “does not contain CMakeLists.txt”

You ran CMake from the wrong directory.

Run it from inside `llama.cpp/`.

---
---

## 5. Get the project tree to help debug”

These commands generate a clean snapshot of your project structure and save it to `project_tree.txt`. They include hidden files, show human-readable file sizes, organize directories first for clarity, and ignore unnecessary build clutter like `.git`, object files, and cache files. The depth limit (`-L 4` or `-L 5`) keeps the output readable, while `--filelimit 200` prevents very large folders from flooding the file.

This snapshot is extremely useful for troubleshooting because it clearly shows whether important files (models, binaries, shared libraries) exist, whether their sizes look correct, and whether the build output is structured properly. It gives both you and an AI model a fast, structured overview of the project to diagnose missing files, broken builds, or runtime issues.

tree -a -h -L 5 \
  -I '.git|__pycache__|*.o|*.obj|*.a|*.pyc' \
  --dirsfirst \
  --filelimit 200 \
  > project_tree.txt

tree -a -h -L 4 \
  -I '.git|__pycache__|*.o|*.obj|*.a|*.pyc' \
  --dirsfirst \
  > project_tree.txt
  
---

# Understanding the Build Process

### `cmake -B build`

* Reads `CMakeLists.txt`
* Detects compilers and CUDA
* Generates Makefiles
* Stores configuration in `CMakeCache.txt`

No compilation happens here.

---

### `cmake --build build`

Compiles the code and links binaries.

---

### `-j$(nproc)`

Parallelizes compilation across CPU cores.
Only affects build speed.

---

Below is a **clean section** you can append to your guide (I structured it to match your existing style and tone).

You can place it right before **“Understanding the Build Process”** or make it a new section 11.

---

# Managing `llama.cpp` as a Git Submodule

This project uses **`llama.cpp` as a Git submodule**.

A submodule allows this repository to depend on a specific version of `llama.cpp` without copying its source code. Instead of tracking all of `llama.cpp`, Git stores a pointer to an exact commit.

This provides:

* Reproducibility (everyone builds the same version)
* Controlled updates
* Clean repository structure
* No nested Git repository issues

---

## Cloning the Project (Important)

When cloning this repository, you must initialize the submodule:

```bash
git clone <your-repo-url>
cd AI_models_local_setup_llamacpp
git submodule update --init --recursive
```

This downloads the exact pinned version of `llama.cpp`.

---

# Updating `llama.cpp` to Upstream

If you decide to update to the latest upstream version:

```bash
cd llama.cpp
git pull origin master
cd ..
git add llama.cpp
git commit -m "Update llama.cpp to latest upstream"
git push
```

This updates the submodule pointer in your repository.

⚠️ Always rebuild and test after updating.

---

# Rolling Back if an Update Breaks

If a newer upstream version introduces breaking changes, you can revert safely.

## Option 1 — Roll Back Entire Project

Find a previous commit:

```bash
git log
```

Then:

```bash
git checkout <previous_commit_hash>
git submodule update --init --recursive
```

This restores both your project and the exact working `llama.cpp` version.

---

## Option 2 — Roll Back Only `llama.cpp`

```bash
cd llama.cpp
git checkout <older_commit_hash>
cd ..
git add llama.cpp
git commit -m "Rollback llama.cpp to stable version"
```

---

# Why This Is Important

Each commit in this repository captures:

* Your scripts
* Your configuration
* The exact `llama.cpp` version

If something breaks, you can always return to a known working state.

This provides stability while still allowing controlled upgrades.

---

# Final Result

After following this guide:

* CUDA acceleration works
* Optimized for RTX 40 series (Ada)
* No shared library runtime errors
* No environment variable hacks
* Clean rebuild workflow
* CLI and Python both supported