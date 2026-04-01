# Honcho self-hosted server
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN pip install --no-cache-dir uv

# Clone Honcho repository (pinned to specific commit for reproducible builds)
RUN git clone https://github.com/plastic-labs/honcho.git /app \
    && cd /app && git checkout cc3483bfaa92277e349b1f7f1a6b0767c2512085

# Patch clients.py to make Google provider optional
RUN sed -i 's/for provider_name, provider_value in SELECTED_PROVIDERS:/# Patched: Skip provider validation\nif False:  # for provider_name, provider_value in SELECTED_PROVIDERS:/' /app/src/utils/clients.py

# Install Python dependencies
RUN uv sync

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Waiting for PostgreSQL..."\n\
until pg_isready -h postgres -U postgres; do\n\
  sleep 2\n\
done\n\
\n\
echo "Running database migrations..."\n\
uv run alembic upgrade head\n\
\n\
echo "Starting Honcho server..."\n\
exec uv run fastapi run src/main.py --host 0.0.0.0 --port 8000\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
