# Используем тот же базовый образ, который уже содержит vLLM и нужные зависимости (кроме свежего transformers)
FROM vllm/vllm-openai:v0.8.5
# FROM vllm/vllm-openai:latest # Или попробуйте :latest, если v0.8.5 не сработает

# Устанавливаем git (он нужен для pip install git+...)
# Обновляем pip
# Удаляем старую версию transformers, чтобы избежать конфликтов (рекомендуется)
# Устанавливаем САМУЮ ПОСЛЕДНЮЮ версию transformers прямо из GitHub репозитория
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip && \
    pip uninstall -y transformers && \
    pip install --no-cache-dir "transformers @ git+https://github.com/huggingface/transformers.git"

# Ничего больше делать не нужно. Не переустанавливаем vLLM.
# Не трогаем версию Torch, позволяем pip разрешить зависимости.
# Базовый образ уже имеет ENTRYPOINT/CMD для запуска vLLM.
