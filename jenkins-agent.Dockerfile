FROM jenkins/inbound-agent:jdk21

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        docker-cli \
    && rm -rf /var/lib/apt/lists/*

USER jenkins
