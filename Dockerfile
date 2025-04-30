# ── stage 1: build vLLM master ──────────────────────────────────────────────
FROM vllm/vllm-openai:latest AS builder

# 1) удалить прединсталлированный vllm
RUN pip uninstall -y vllm && \
    apt-get update && apt-get install -y git git-lfs

# 2) shallow-clone с .git (setuptools-scm увидит repo)
ENV GIT_LFS_SKIP_SMUDGE=1
RUN git clone --depth 1 https://github.com/vllm-project/vllm.git /tmp/vllm

# 3) подходящая версия torch (2.6.0 cu124 — подходит V100, CUDA 12.4)
RUN pip install --no-cache-dir \
        --pre torch==2.6.0+cu124 \
        --index-url https://download.pytorch.org/whl/nightly/cu124

# 4) triton 3.0 и сам vLLM
RUN pip install --no-cache-dir triton==3.0.0
RUN pip install --no-cache-dir -e /tmp/vllm

# ── stage 2: минимальный runtime ────────────────────────────────────────────
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

COPY --from=builder /usr/local /usr/local

# опц. утилиты
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# качаем модель во время билда (нужно HF_TOKEN)
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token $HF_TOKEN \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
