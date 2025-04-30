########################
# stage 1 – build layer
########################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS builder

# 1) nightly Torch 2.6 + Triton 3      ← ничего из apt не тянем
RUN pip install --no-cache-dir --pre torch \
      --index-url https://download.pytorch.org/whl/nightly/cu124 \
 && pip install --no-cache-dir triton==3.0.0

# 2) скачиваем master-ветку vLLM обычным .tar.gz
ADD https://github.com/vllm-project/vllm/archive/refs/heads/master.tar.gz /tmp/vllm.tar.gz

# 3) распаковываем и ставим **editable**; подсовываем версию вручную —
#    так setuptools-scm не требует .git
ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.8.6.dev0
RUN mkdir /tmp/vllm && \
    tar -xzf /tmp/vllm.tar.gz --strip-components=1 -C /tmp/vllm && \
    pip install --no-cache-dir -e /tmp/vllm

############################
# stage 2 – runtime layer
############################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# (необязательно) мелкие утилиты
RUN pip install --no-cache-dir uvicorn fastapi huggingface_hub[cli]

# Кэшируем модель во время билда
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token "$HF_TOKEN" \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
