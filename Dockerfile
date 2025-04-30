########################
# stage 1 – build layer
########################
FROM vllm/vllm-openai:latest AS builder

# 1) убираем предрелизный vLLM
RUN pip uninstall -y vllm

# 2) Torch nightly 2.6 + Triton 3.0
RUN pip install --no-cache-dir --pre torch \
      --index-url https://download.pytorch.org/whl/nightly/cu124 \
 && pip install --no-cache-dir triton==3.0.0

# 3) предсобранный wheel vLLM (master) с CUDA 12.4
RUN pip install --no-cache-dir \
      https://vllm-wheels.s3.us-west-2.amazonaws.com/nightly/\
vllm-1.0.0.dev+cu124-cp312-abi3-manylinux1_x86_64.whl

########################
# stage 2 – runtime
########################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

COPY --from=builder /usr/local /usr/local

RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub[cli]

ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token "$HF_TOKEN" \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
