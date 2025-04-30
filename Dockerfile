# ── stage 1: build runtime layer ────────────────────────────────────────────
FROM vllm/vllm-openai:latest AS builder

# 1) обновляем Torch до nightly-2.6 + Triton 3
RUN pip uninstall -y vllm \
 && pip install --no-cache-dir --pre torch \
      --index-url https://download.pytorch.org/whl/nightly/cu124/ \
 && pip install --no-cache-dir triton==3.0.0 vllm-nightly

# ── stage 2: минимальный runtime ────────────────────────────────────────────
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# Утилиты (по желанию)
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# Скачиваем модель во время билда
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
     --token $HF_TOKEN \
     --local-dir /root/.cache/huggingface/hub \
     --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
