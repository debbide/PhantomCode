FROM node:22-bookworm-slim

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    vim \
    nano \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install claude-code-router globally via npm
RUN npm install -g @musistudio/claude-code-router

# Set environment variables to use Microsoft's official marketplace
# This is REQUIRED to find the official Claude plugin in the extensions view
ENV EXTENSIONS_GALLERY='{"serviceUrl":"https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl":"https://vscode.blob.core.windows.net/gallery/index","itemUrl":"https://marketplace.visualstudio.com/items","controlUrl":"","recommendationsUrl":""}'

# Create a workspace directory
WORKDIR /home/coder/project

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
# 8080: code-server
# 3456: router API gateway
# 3458: router Web UI
EXPOSE 8080 3456 3458

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
