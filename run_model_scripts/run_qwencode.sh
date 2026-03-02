#!/bin/bash

# Run Qwen2.5-Coder 7B with CUDA on RTX 4050

/home/chinmaya/Programming/AI_models/llama.cpp/build/bin/llama-cli \
    -m /home/chinmaya/Programming/AI_models/models/qwen2.5-coder-7b-instruct-q4_k_m.gguf \
    -ngl 28 \
    --threads $(nproc) \
    # -b 512 \
    # -c 4096 \
    # --temp 0.2 \



# Run as server

# /home/chinmaya/Programming/AI_models/llama.cpp/build/bin/llama-server \
#   -m /home/chinmaya/Programming/AI_models/models/qwen2.5-coder-7b-instruct-q4_k_m.gguf \
#   -ngl 26 \
#   -c 4096 \
#   -b 256 \
#   --threads 8 \
#   --port 9001









