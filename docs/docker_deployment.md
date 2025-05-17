# Docker Deployment Guide

This document explains how to deploy the API Dart project using Docker and Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) installed on your system
- Basic knowledge of Docker and containerization

## Project Structure

The project includes the following Docker-related files:

- `Dockerfile`: Multi-stage build file for creating the API container
- `docker-compose.yml`: Configuration for local development with multiple services
- `.dockerignore`: List of files and directories to exclude from the Docker build
- `scripts/init-db.sql`: Database initialization script for PostgreSQL

## Local Development with Docker Compose

Docker Compose is configured to set up a complete development environment with the following services:

- **api**: The API Dart application
- **postgres**: PostgreSQL database
- **redis**: Redis for caching
- **adminer**: Web-based database management tool
- **swagger-ui**: Swagger UI for API documentation

### Starting the Development Environment

1. Make sure Docker and Docker Compose are installed and running
2. Navigate to the project root directory
3. Run the following command:

```bash
docker-compose up
```

This will start all services defined in the `docker-compose.yml` file. To run in detached mode (background):

```bash
docker-compose up -d
```

### Accessing the Services

Once the services are running, you can access them at the following URLs:

- **API**: http://localhost:8081
- **API Documentation**: http://localhost:8081/docs
- **Swagger UI**: http://localhost:8083
- **Adminer**: http://localhost:8082
  - System: PostgreSQL
  - Server: postgres
  - Username: postgres
  - Password: postgres
  - Database: multi_llm_api_dev

### Stopping the Development Environment

To stop all services:

```bash
docker-compose down
```

To stop all services and remove volumes (this will delete all data):

```bash
docker-compose down -v
```

## Production Deployment

For production deployment, you can use the provided Dockerfile to build a standalone container.

### Building the Docker Image

```bash
docker build -t api-dart:latest .
```

### Running the Container

```bash
docker run -p 8080:8080 \
  -e DART_ENV=production \
  -e GEMINI_API_KEY=your_api_key \
  -e JWT_SECRET=your_jwt_secret \
  -e DB_HOST=your_db_host \
  -e DB_PASSWORD=your_db_password \
  api-dart:latest
```

### Environment Variables

You can override any environment variable defined in the `.env.production` file by passing it as a `-e` parameter to the `docker run` command.

## Docker Compose for Production

For a production setup with multiple services, you can create a separate `docker-compose.prod.yml` file:

```yaml
version: '3.8'

services:
  api:
    image: api-dart:latest
    ports:
      - "8080:8080"
    environment:
      - DART_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    restart: always

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: always

volumes:
  postgres_data:
  redis_data:
```

And run it with:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Continuous Integration/Continuous Deployment (CI/CD)

For CI/CD pipelines, you can use the following steps:

1. Build the Docker image
2. Run tests inside the container
3. Push the image to a container registry (e.g., Docker Hub, GitHub Container Registry)
4. Deploy the image to your production environment

Example GitHub Actions workflow:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t api-dart:${{ github.sha }} .
      
      - name: Run tests
        run: docker run api-dart:${{ github.sha }} dart test
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Push Docker image
        run: |
          docker tag api-dart:${{ github.sha }} ghcr.io/${{ github.repository }}/api-dart:${{ github.sha }}
          docker tag api-dart:${{ github.sha }} ghcr.io/${{ github.repository }}/api-dart:latest
          docker push ghcr.io/${{ github.repository }}/api-dart:${{ github.sha }}
          docker push ghcr.io/${{ github.repository }}/api-dart:latest
```

## Best Practices

1. **Security**:
   - Never store sensitive information (API keys, passwords) in the Docker image
   - Use environment variables or secrets management for sensitive information
   - Run the container as a non-root user (already configured in the Dockerfile)

2. **Performance**:
   - Use multi-stage builds to keep the final image small (already configured)
   - Use a proper caching strategy for dependencies
   - Configure appropriate resource limits for containers

3. **Monitoring**:
   - Set up health checks for containers
   - Implement logging and monitoring solutions
   - Configure automatic restarts for failed containers

4. **Scaling**:
   - Design the application to be stateless for horizontal scaling
   - Use a container orchestration platform like Kubernetes for production deployments
   - Implement proper load balancing

## Troubleshooting

### Common Issues

1. **Container fails to start**:
   - Check the logs: `docker logs multi_llm_api`
   - Verify environment variables are set correctly
   - Ensure the database is accessible

2. **Database connection issues**:
   - Check if the database container is running: `docker ps`
   - Verify the database credentials
   - Check network connectivity between containers

3. **Permission issues**:
   - Ensure volume mounts have correct permissions
   - Check if the application is running as the correct user

### Useful Commands

- View logs: `docker logs multi_llm_api`
- Enter container shell: `docker exec -it multi_llm_api /bin/bash`
- Check container status: `docker ps -a`
- Check container resource usage: `docker stats`
