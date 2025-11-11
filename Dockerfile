FROM ghcr.io/relative-strength/ashigaru-terminal-image-startos:latest

USER root

# Install curl and yq
RUN apt-get update --allow-releaseinfo-change || apt-get update --allow-releaseinfo-change && \
    apt-get install -y curl && \
    curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${PLATFORM} -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add default config
RUN mkdir -p /root/defaults/.ashigaru
COPY root/defaults/.ashigaru/config /root/defaults/.ashigaru/config

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/docker_entrypoint.sh

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/docker_entrypoint.sh"]
