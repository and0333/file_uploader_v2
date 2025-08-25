# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.5
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION


USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bundle \
 && chown -R vscode:vscode /usr/local/bundle \
 && chmod -R 755 /usr/local/bundle

USER vscode
ENV PATH="/usr/local/bundle/bin:/usr/local/bin:/home/vscode/.local/bin:${PATH}"
ENV BUNDLE_PATH="/usr/local/bundle"
ENV BUNDLE_BIN="/usr/local/bundle/bin"
ENV GEM_HOME="/usr/local/bundle"
ENV GEM_PATH="/usr/local/bundle"

