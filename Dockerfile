# ── stage 1 ────────────────────────────────────────────────────────────────
FROM vllm/vllm-openai:latest AS builder

# 1. Обновляем Torch до 2.6.0 (cu124) + Triton-3
RUN pip uninstall -y vllm \
 && pip install --no-cache-dir --pre torch==2.6.0+cu124 \
       --index-url https://download.pytorch.org/whl/nightly/cu124 \
 && pip install --no-cache-dir triton==3.0.0

# 2. Ставим свежий vLLM напрямую из master (git+https)
RUN pip install --no-cache-dir \
      "vllm @ git+https://github.com/vllm-project/vllm.git@master"

# ── stage 2 ────────────────────────────────────────────────────────────────
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

COPY --from=builder /usr/local /usr/local

# Утилиты (опц.)
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# Качаем модель во время билда
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token $HF_TOKEN \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
