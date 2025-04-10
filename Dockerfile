# Build stage
FROM ubuntu:22.04 AS builder

# Install Flutter dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Set up Flutter
RUN flutter config --enable-web

# Set the working directory
WORKDIR /app

# Copy the Flutter project files
COPY . .

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release

# Serve stage
FROM nginx:alpine

# Install envsubst
RUN apk update && apk add gettext

# Copy the Nginx configuration template and entrypoint script
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy the built web app from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Use the PORT environment variable
ENV PORT=8080
EXPOSE ${PORT}

# Use the entrypoint script to start Nginx
ENTRYPOINT ["/entrypoint.sh"] 