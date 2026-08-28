# ==========================================
# STAGE 1: Builder (Compile dependencies)
# ==========================================
# Using a slim version of the Python base image to keep the image small
FROM python:3.12-slim AS builder

# Set environment variables to optimize Python for Docker
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory inside the container
WORKDIR /app

# Install build-essential and PostgreSQL headers for compiling C extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy python/app dependencies
COPY requirements.txt .

# Upgrade pip and install app dependencies/packages into /root/.local
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt


# ==========================================
# STAGE 2: Production Runtime
# ==========================================
# Using a slim version of the Python base image to keep the image small
FROM python:3.12-slim AS runner

# Set environment variables to optimize Python for Docker
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/home/appuser/.local/bin:${PATH}"

# Install minimal C runtime library for PostgreSQL
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create non-root system user and group (Securing EKS workload)
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh -m appuser

# Set the working directory inside the container    
WORKDIR /app

# Copy python dependencies from builder with non-root ownership
COPY --from=builder --chown=appuser:appgroup /root/.local /home/appuser/.local

# Copy application source code with appropriate permissions/non-root ownership
COPY --chown=appuser:appgroup . .

# Explicitly set executable permissions for the entrypoint
RUN chmod +x /app/entrypoint.sh

# Enforce non-root execution context
USER 10001:10001

# Expose Django's default port
EXPOSE 8000

# Run database migrations and collect static assets from the shell script
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command for API Pods
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "60"]