# Stage 1: Build with uv to manage dependencies
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

# Set working directory
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Force uv to copy instead of linking (useful with mounted volumes)
ENV UV_LINK_MODE=copy

# Install only production dependencies using the lockfile
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Add project source code and install it
ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Stage 2: Final image using a minimal Python base
FROM python:3.12-slim-bookworm

# Optional: Create a non-root user (uncomment if needed)
# RUN adduser --disabled-password --gecos "" app

# Set working directory
WORKDIR /app

# Copy virtual environment and dependencies from the build stage
COPY --from=uv /root/.local /root/.local
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Set path to use the virtual environment's executables
ENV PATH="/app/.venv/bin:$PATH"

# Default command to run the service
# Note: Use a bind mount for the database file and pass --db-path when running
ENTRYPOINT ["netbox-mcp-server"]
