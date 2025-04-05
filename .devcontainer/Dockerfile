# Make sure RUBY_VERSION matches the Ruby version in .ruby-version or gemspec
ARG RUBY_VERSION=3.4.2
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

USER root

# Install pkg-config and SQLite development libraries
RUN apt-get update -qq && \
    apt-get install -y pkg-config libsqlite3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER vscode

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"