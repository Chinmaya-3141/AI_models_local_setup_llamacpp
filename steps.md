# **Complete Guide: llama.cpp with GPU + Python Integration**

## **Step 0: Prerequisites**

Before starting, make sure your system has:

1. **Git**

   ```bash
   git --version
   ```

   * Linux: `sudo apt install git`
   * Windows: install from [git-scm.com](https://git-scm.com/)

2. **C++ Compiler**

   * Linux: `g++` (≥ 10) or `clang++`

     ```bash
     g++ --version
     ```
   * Windows: Visual Studio with C++ workload

3. **CMake**

   ```bash
   cmake --version
   ```

4. **CUDA Toolkit** (for NVIDIA GPU acceleration)

   ```bash
   nvcc --version
   ```

5. **Python ≥ 3.10** (for Python integration)

   ```bash
   python3 --version
   ```

---

## **Step 1: Clone the Official Repository**

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
```

* This downloads the official `llama.cpp` repo with all documentation and build scripts.

---

## **Step 2: Build llama.cpp with GPU Support**

### **A) Using CMake (Recommended)**

```bash
mkdir build
cd build
cmake .. -DLLAMA_CUBLAS=ON -DGGML_CUDA=ON
cmake --build . --config Release -j$(nproc)
```

Explanation:

* `LLAMA_CUBLAS=ON` → Use NVIDIA cuBLAS for GPU acceleration
* `GGML_CUDA=ON` → Enable CUDA kernels
* `-j$(nproc)` → Use all CPU cores for faster compilation

---

### **B) Quick Makefile Build**

```bash
make clean
make LLAMA_CUBLAS=1
```

* Produces `./main` (CLI program) with GPU acceleration.

---

## **Step 3: Verify GPU Build**

Check if GPU is detected:

```bash
./build/bin/llama-cli --list-devices
```

* You should see your NVIDIA GPU listed.
* If no GPU appears, CUDA may not be properly installed or `llama.cpp` wasn’t built with GPU flags.

---

## **Step 4: Download or Prepare a Model**

`llama.cpp` uses **GGUF/quantized models**. Options:

### **Option A: Download via Hugging Face**

```bash
./build/bin/llama-cli -hf ggml-org/gemma-3-1b-it-GGUF
```

* Downloads and caches the model locally.

### **Option B: Manual Download**

1. Download model weights (7B, 13B, etc.) from Hugging Face or Meta.
2. Convert to GGUF if needed.
3. Place in `models/` directory.

---

## **Step 5: Run the Model (CLI)**

### **Interactive Prompt Example**

```bash
./build/bin/llama-cli -m ./models/your_model.gguf -p "Hello, LLaMA!" --n-gpu-layers 20
```

* `-m` → model path
* `-p` → prompt
* `--n-gpu-layers` → number of layers to run on GPU
* You can also use flags like `--n-predict`, `-t` for threads, and `--color` for colored output.

---

## **Step 6: Python Integration**

Python binding allows you to **use llama.cpp inside Python scripts**.

### **A) Build Python Bindings**

```bash
cd llama.cpp
make py
```

### **B) Install Python Module**

```bash
pip install ./python
```

### **C) Python Example Script**

```python
from llama_cpp import Llama

# Load GGUF model
llm = Llama(model_path="models/your_model.gguf", n_gpu_layers=20)

# Run inference
output = llm("Hello from Python with GPU!")
print(output.text)
```

Explanation:

* `n_gpu_layers` → Number of transformer layers to run on GPU (rest runs on CPU).
* `output.text` → Contains the generated text.

✅ GPU acceleration works the same as in CLI.

---

## **Step 7: Tips for Best Performance**

1. **Use Quantized Models** (`q4_0`, `q5_0`) → Faster + smaller VRAM.
2. **Adjust `n_gpu_layers`** → Larger GPUs can handle more layers; smaller GPUs need fewer.
3. **Monitor GPU** → `nvidia-smi` shows memory usage and utilization.
4. **CPU Fallback** → If GPU memory is exceeded, remaining layers run on CPU.

---

## **Step 8: Optional Flags & CLI Tricks**

* `--color` → colorized output
* `--n-predict N` → number of tokens to generate
* `-t N` → threads for CPU fallback
* `--seed N` → set random seed for reproducibility

---

## **Diagram of Workflow (GPU + Python)**

```
[Model GGUF File] --> [llama.cpp C++ Core] --> [CLI or Python]
                                    |
                                    +--> GPU (first N layers)
                                    |
                                    +--> CPU (remaining layers)
```

* CLI: Run commands directly.
* Python: Embed llama.cpp in scripts or apps.
* GPU: Accelerates matrix operations for faster inference.

---

✅ **Now you have:**

* GPU-accelerated llama.cpp
* CLI usage
* Python integration
* Tips for quantized models and performance

---

If you want, I can also make a **fully automated bash script** that installs prerequisites, clones the repo, builds with GPU, downloads a model, and runs a test Python script in one shot. This is very handy for Linux/WSL setups.

Do you want me to create that script?
