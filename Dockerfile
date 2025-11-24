FROM ghcr.io/relative-strength/ashigaru-terminal-image-startos:latest

USER root

# Install required tools including iproute2 for the 'ip' command
RUN apt-get update --allow-releaseinfo-change || apt-get update && \
    apt-get install -y curl wget iproute2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install yq with correct architecture mapping
# Note: yq uses "arm64" not "aarch64" for ARM64 releases
RUN ARCH=$(dpkg --print-architecture) && \
    echo "Installing yq for architecture: ${ARCH}" && \
    if [ "$ARCH" = "arm64" ]; then \
        YQ_BINARY="yq_linux_arm64"; \
    elif [ "$ARCH" = "amd64" ]; then \
        YQ_BINARY="yq_linux_amd64"; \
    else \
        YQ_BINARY="yq_linux_${ARCH}"; \
    fi && \
    echo "Downloading yq binary: ${YQ_BINARY}" && \
    wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.40.5/${YQ_BINARY}" && \
    chmod +x /usr/local/bin/yq && \
    echo "Testing yq installation..." && \
    /usr/local/bin/yq --version && \
    echo "Testing yq YAML parsing..." && \
    echo "test: value" | /usr/local/bin/yq '.test' && \
    echo "✓ yq is working correctly"

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/docker_entrypoint.sh

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/docker_entrypoint.sh"]