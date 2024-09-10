# Use the official Elixir image as the base image
FROM elixir:1.14.5 AS build

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git nodejs npm

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create and set the working directory
WORKDIR /app

# Copy mix.exs and mix.lock files
COPY mix.exs mix.lock ./

# Install mix dependencies
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files
COPY config config

# Copy the rest of the application code
COPY lib lib
COPY priv priv
COPY assets assets

# Compile the application
RUN mix do compile

# Install and setup deployment for esbuild
RUN mix esbuild.install --if-missing

# Build assets
RUN mix assets.deploy

# Build the release
RUN mix release

# Debug: List contents of the release directory
RUN ls -R /app/_build/prod/rel/chat_room

# Start a new build stage
FROM ubuntu:22.04 AS app

# Install runtime dependencies
RUN apt-get update && apt-get install -y openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set environment variables
ENV PHX_SERVER=true

# Create a non-root user
RUN useradd -m app

# Set the working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/chat_room ./

# Debug: List contents of the app directory
RUN ls -R /app

# Set the user
USER app

# Set the entrypoint
CMD ["/app/bin/chat_room", "start"]