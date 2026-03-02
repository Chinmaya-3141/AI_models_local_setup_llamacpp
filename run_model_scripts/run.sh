#!/usr/bin/env bash

# ===============================================
# Universal LLM Launcher (Auto-detect args & defaults)
# ===============================================

# -------------------------------
# Internal defaults
# -------------------------------
# THREADS: number of CPU threads for inference
# CONTEXT: token context window (max prompt+completion length)
# BATCH: internal GPU batch size (affects speed/memory, not quality)
# TEMP: sampling temperature (0.2 = low randomness for coding)
THREADS="$(nproc)"
CONTEXT=4096
BATCH=256
TEMP=0.2

# -------------------------------
# Known models list
# -------------------------------
KNOWN_MODELS=("2.5coder" "qwen3")
DEFAULT_MODEL="2.5coder"

# -------------------------------
# Resolve paths relative to project root
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CLI_BIN="$BASE_DIR/llama.cpp/build/bin/llama-cli"
SERVER_BIN="$BASE_DIR/llama.cpp/build/bin/llama-server"
MODEL_DIR="$BASE_DIR/models"
PROMPT_DIR="$BASE_DIR/system_prompts"


# -------------------------------
# Read arguments
# -------------------------------
ARG1="$1"
ARG2="$2"
ARG3="$3"

# -------------------------------
# Determine model, prompt, and mode
# -------------------------------
MODEL_KEY=""
PROMPT_NAME=""
MODE=""

# Check if last argument is "server"
if [[ "$ARG1" == "server" || "$ARG2" == "server" || "$ARG3" == "server" ]]; then
    MODE="server"
fi

# Determine model & prompt based on number and type of arguments
if [[ -z "$ARG1" ]]; then
    # No arguments → default model, no prompt
    MODEL_KEY="$DEFAULT_MODEL"
elif [[ " ${KNOWN_MODELS[@]} " =~ " $ARG1 " ]]; then
    # First argument is a known model
    MODEL_KEY="$ARG1"
    # If ARG2 exists and is not 'server', treat as prompt
    if [[ -n "$ARG2" && "$ARG2" != "server" ]]; then
        PROMPT_NAME="$ARG2"
    fi
else
    # First argument is not a known model → treat as prompt, use default model
    MODEL_KEY="$DEFAULT_MODEL"
    PROMPT_NAME="$ARG1"
fi

# -------------------------------
# Resolve system prompt file
# -------------------------------
PROMPT_FILE=""
if [ -n "$PROMPT_NAME" ]; then
    PROMPT_FILE="$PROMPT_DIR/$PROMPT_NAME.txt"
    if [ ! -f "$PROMPT_FILE" ]; then
        echo "Error: System prompt file not found: $PROMPT_FILE"
        exit 1
    fi
fi

# -------------------------------
# Model Mapping
# -------------------------------
case "$MODEL_KEY" in
    2.5coder)
        MODEL_PATH="$MODEL_DIR/qwen2.5-coder-7b-instruct-q4_k_m.gguf"
        GPU_LAYERS=26
        ;;
    qwen3)
        MODEL_PATH="$MODEL_DIR/Qwen3-8B-Q4_K_M.gguf"
        GPU_LAYERS=30
        ;;
    *)
        echo "Error: Unknown model key '$MODEL_KEY'"
        exit 1
        ;;
esac

if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model file not found: $MODEL_PATH"
    exit 1
fi



# -------------------------------
# Launch server or interactive CLI
# -------------------------------
if [ "$MODE" = "server" ]; then
    echo "Launching in SERVER mode..."
    "$SERVER_BIN" \
        -m "$MODEL_PATH" \
        -ngl "$GPU_LAYERS" \
        -c "$CONTEXT" \
        -b "$BATCH" \
        --threads "$THREADS" \
        --port 9001
else
    echo "Launching in INTERACTIVE mode..."
    CMD=("$CLI_BIN" -m "$MODEL_PATH" -ngl "$GPU_LAYERS" --threads "$THREADS" -c "$CONTEXT" --temp "$TEMP")

    # Add system prompt if it exists
    if [ -n "$PROMPT_FILE" ]; then
        CMD+=(--system-prompt-file "$PROMPT_FILE")
    fi

    "${CMD[@]}"
fi



# #!/usr/bin/env bash

# # ===============================================
# # Universal LLM Launcher (Default & Robust Version)
# # ===============================================

# # -------------------------------
# # Resolve paths relative to project root
# # -------------------------------
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"  # parent dir of run_model_scripts

# CLI_BIN="$BASE_DIR/llama.cpp/build/bin/llama-cli"
# SERVER_BIN="$BASE_DIR/llama.cpp/build/bin/llama-server"
# MODEL_DIR="$BASE_DIR/models"
# PROMPT_DIR="$BASE_DIR/system_prompts"

# # -------------------------------
# # Read arguments
# # -------------------------------
# MODEL_KEY="${1:-2.5coder}"   # default model if not passed
# # MODEL_KEY="${1:-qwen3}"   # default model if no argument
# PROMPT_NAME="$2"             # optional
# MODE="$3"                    # optional "server"

# # -------------------------------
# # Determine system prompt file if given
# # -------------------------------
# if [ -n "$PROMPT_NAME" ]; then
#     PROMPT_FILE="$PROMPT_DIR/$PROMPT_NAME.txt"
#     if [ ! -f "$PROMPT_FILE" ]; then
#         echo "Error: System prompt file not found: $PROMPT_FILE"
#         exit 1
#     fi
# else
#     PROMPT_FILE=""  # no prompt
# fi

# # -------------------------------
# # Model Mapping
# # -------------------------------
# case "$MODEL_KEY" in
#     2.5coder)
#         MODEL_PATH="$MODEL_DIR/qwen2.5-coder-7b-instruct-q4_k_m.gguf"
#         GPU_LAYERS=28
#         ;;
#     qwen3)
#         MODEL_PATH="$MODEL_DIR/qwen3-8b-instruct-q4_k_m.gguf"
#         GPU_LAYERS=28
#         ;;
#     *)
#         echo "Error: Unknown model key '$MODEL_KEY'"
#         echo ""
#         echo "To add a new model:"
#         echo "1) Place the model file inside: $MODEL_DIR"
#         echo "2) Add a new case entry like:"
#         echo ""
#         echo "   mymodel)"
#         echo "       MODEL_PATH=\"$MODEL_DIR/my-model.gguf\""
#         echo "       GPU_LAYERS=28"
#         echo "       ;;"
#         exit 1
#         ;;
# esac

# if [ ! -f "$MODEL_PATH" ]; then
#     echo "Error: Model file not found: $MODEL_PATH"
#     exit 1
# fi

# # -------------------------------
# # Internal defaults
# # -------------------------------
# THREADS="$(nproc)"
# CONTEXT=4096
# BATCH=256
# TEMP=0.2

# # -------------------------------
# # Launch server or interactive CLI
# # -------------------------------
# if [ "$MODE" = "server" ]; then
#     echo "Launching in SERVER mode..."
#     "$SERVER_BIN" \
#         -m "$MODEL_PATH" \
#         -ngl "$GPU_LAYERS" \
#         -c "$CONTEXT" \
#         -b "$BATCH" \
#         --threads "$THREADS" \
#         --port 9001
# else
#     echo "Launching in INTERACTIVE mode..."
#     CMD=("$CLI_BIN" -m "$MODEL_PATH" -ngl "$GPU_LAYERS" --threads "$THREADS" -c "$CONTEXT" --temp "$TEMP")
    
#     # Only add prompt if it exists
#     if [ -n "$PROMPT_FILE" ]; then
#         CMD+=(--system-prompt-file "$PROMPT_FILE")
#     fi

#     "${CMD[@]}"
# fi