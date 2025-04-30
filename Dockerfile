# ── stage 1: берём официальный vLLM, заменяем пакет на fresh-master ──────────
FROM vllm/vllm-openai:latest AS builder
RUN pip uninstall -y vllm && \
    git clone --depth 1 https://github.com/vllm-project/vllm /tmp/vllm && \
    pip install --no-cache-dir --upgrade torch==2.2.2 triton==3.0.0 && \
    pip install --no-cache-dir -e /tmp/vllm

# ── stage 2: финальный ран-тайм (минимум) ────────────────────────────────────
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# удобные утилиты (необязательно)
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# скачиваем модель во время билда, чтобы при запуске не ждать
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
        --token ${HF_TOKEN} \
        --local-dir /root/.cache/huggingface/hub \
        --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
