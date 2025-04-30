############################
# stage 1 – build layer
############################
FROM vllm/vllm-openai:latest AS builder

# 1) убираем предустановленный стабильный vLLM
RUN pip uninstall -y vllm

# 2) свежий nightly Torch + Triton 3
RUN pip install --no-cache-dir --pre torch \
      --index-url https://download.pytorch.org/whl/nightly/cu124/ \
 && pip install --no-cache-dir triton==3.0.0

# 3) vLLM master tar.gz (без git, без apt)
ADD https://github.com/vllm-project/vllm/archive/refs/heads/master.tar.gz /tmp/vllm.tar.gz
ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.8.6.dev0
RUN mkdir /tmp/vllm && \
    tar -xzf /tmp/vllm.tar.gz --strip-components=1 -C /tmp/vllm && \
    pip install --no-cache-dir -e /tmp/vllm

############################
# stage 2 – runtime layer
############################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# (опционально) cli-утилиты
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# качаем модель во время билда
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
     --token "$HF_TOKEN" \
     --local-dir /root/.cache/huggingface/hub \
     --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
