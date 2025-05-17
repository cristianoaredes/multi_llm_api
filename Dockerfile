# Multi-stage build for API Dart project

# Stage 1: Build the application
FROM dart:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN dart pub get

# Copy the rest of the application
COPY . .

# Build the application
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Create a minimal runtime image
FROM debian:bullseye-slim

# Set working directory
WORKDIR /app

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the build stage
COPY --from=build /app/bin/server /app/bin/server

# Copy environment files
COPY --from=build /app/.env.* /app/
# Create a default .env file if it doesn't exist
RUN touch /app/.env

# Copy OpenAPI specification for Swagger UI
COPY --from=build /app/openapi /app/openapi

# Create a non-root user to run the application
RUN useradd -m dartuser
RUN chown -R dartuser:dartuser /app
USER dartuser

# Expose the port the server listens on
ENV PORT=8080
EXPOSE $PORT

# Set the environment to production by default
ENV DART_ENV=production

# Run the server
CMD ["/app/bin/server"]
