############################
# stage 1 – build layer
############################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS builder

# 1. базовые утилиты для git-clone
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 2. Torch 2.6.dev* + Triton 3.0
RUN pip install --no-cache-dir --pre torch \
      --index-url https://download.pytorch.org/whl/nightly/cu124 && \
    pip install --no-cache-dir triton==3.0.0

# 3. vLLM master (shallow-clone, без LFS)
ENV GIT_LFS_SKIP_SMUDGE=1
RUN pip install --no-cache-dir \
      "vllm @ git+https://github.com/vllm-project/vllm.git@master"

############################
# stage 2 – runtime layer
############################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# копируем Python-окружение из builder
COPY --from=builder /usr/local /usr/local

# (опционально) cli-утилиты
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# заранее скачиваем модель
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token "$HF_TOKEN" \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
