# ── stage 1 ────────────────────────────────────────────────────────────────
FROM vllm/vllm-openai:latest AS builder

# удаляем pre-built vllm и тащим master-ветку
RUN pip uninstall -y vllm

ADD https://github.com/vllm-project/vllm/archive/refs/heads/master.tar.gz /tmp/

# распаковываем и сразу «срезаем» первый каталог,
# всё кладём в /tmp/vllm  → название папки больше не важно
RUN mkdir /tmp/vllm && \
    tar -xzf /tmp/master.tar.gz --strip-components=1 -C /tmp/vllm && \
    pip install --no-cache-dir --upgrade torch==2.2.2 triton==3.0.0 && \
    pip install --no-cache-dir -e /tmp/vllm

# ── stage 2: минимальный ран-тайм ──────────────────────────────────────────
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# тулзы (опц.)
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# заранее качаем модель (нужно пробросить HF_TOKEN при build)
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
        --token $HF_TOKEN \
        --local-dir /root/.cache/huggingface/hub \
        --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
