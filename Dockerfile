# ── Dockerfile ────────────────────────────────────────────────────────────
FROM vllm/vllm-openai:nightly-cuda12.4          # Python 3.11, vLLM master

# (по желанию) cli-утилиты
RUN pip install --no-cache-dir fastapi uvicorn huggingface_hub[cli]

# заранее скачиваем модель
ARG HF_TOKEN
RUN huggingface-cli download Qwen/Qwen3-8B \
      --token "$HF_TOKEN" \
      --local-dir /root/.cache/huggingface/hub \
      --local-dir-use-symlinks False

ENV HF_HUB_DISABLE_TELEMETRY=1
ENTRYPOINT ["python","-m","vllm.entrypoints.openai.api_server"]
