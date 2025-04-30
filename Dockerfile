########  stage 1: build layer  ###########################################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS builder

# Python уже есть (3.12). Ставим готовые колёса:
RUN pip install --no-cache-dir --pre torch --index-url \
      https://download.pytorch.org/whl/nightly/cu124 \
 && pip install --no-cache-dir triton==3.0.0 \
 && pip install --no-cache-dir vllm-nightly-cu124

########  stage 2: runtime layer  ########################################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local

# (по желанию) минимальный набор cli-утилит
RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub[cli]

# заранее кешируем модель
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token "$HF_TOKEN" \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python", "-m", "vllm.entrypoints.openai.api_server"]
