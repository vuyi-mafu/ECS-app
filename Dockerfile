# ================================================================
# Multi-Stage Dockerfile - Port 80 - Root User
# ================================================================

# ─────────────────────────────────────
# Stage 1: Builder
# ─────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ─────────────────────────────────────
# Stage 2: Runtime
# ─────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Copy packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application
COPY app.py .

# Set PATH
ENV PATH=/root/.local/bin:$PATH

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:80/health').read()" || exit 1

# Run as root (needed for port 80)
CMD ["python", "app.py"]