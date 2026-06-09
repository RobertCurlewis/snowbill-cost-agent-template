FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    bash \
    ca-certificates \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with bash as the login shell.
# The node devcontainer feature runs a `source ...` snippet in this user's
# shell; under the default /bin/sh (dash) that fails with "source: not found"
# (exit 127), so bash must be the login shell.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME

# Install Python dependencies
COPY .devcontainer/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

USER $USERNAME
