# The images of the API server, built from uv.lock, so they hold the versions that the lockfile names.
#
#   docker build --target run --tag cheesecracker-run .
#       the production image: Python, the dependencies of the server and its code. It starts the server
#   docker build --target dev --tag cheesecracker-dev .
#       the development image: every dependency group, uv, just and git. It starts a shell
#
# The environment lives in /opt/venv, never in the project folder.

# uv itself, copied from its own image
FROM ghcr.io/astral-sh/uv:0.12.13 AS uv

# The environment of the server, without the dependency groups: no tests, no ruff, no pre-commit
FROM python:3.12-slim-bookworm AS build
COPY --from=uv /uv /usr/local/bin/uv
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_CACHE=1
WORKDIR /app
COPY pyproject.toml uv.lock .python-version ./
RUN uv sync --locked --no-default-groups

# The run image: Python, the environment from the build stage, and the code. No uv, and no dev tools
FROM python:3.12-slim-bookworm AS run
RUN useradd --create-home --uid 1000 app
COPY --from=build /opt/venv /opt/venv
WORKDIR /app
COPY src/api-service/api ./api
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1
USER app
EXPOSE 9000
# Four workers, and no restart on a change: the server as it runs in production
CMD ["uvicorn", "api.service:app", "--host", "0.0.0.0", "--port", "9000", "--workers", "4"]

# The dev image: the whole project with every dependency group, and uv, just and git to work in it
FROM python:3.12-slim-bookworm AS dev
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*
COPY --from=uv /uv /uvx /usr/local/bin/
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    UV_NO_CACHE=1 \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1
# just, as a wheel from PyPI. git refuses a folder that another user owns, and a mounted folder
# belongs to the user of the host, so every folder is safe
RUN uv tool install "rust-just==1.50.0" \
    && git config --system --add safe.directory '*'
WORKDIR /work
COPY pyproject.toml uv.lock .python-version ./
RUN uv sync --locked
COPY . .
CMD ["bash"]
