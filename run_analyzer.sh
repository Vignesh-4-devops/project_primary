#!/bin/bash

# Image and container names
IMAGE_NAME="site-analyzer"
CONTAINER_NAME="site-analyzer-container"

# Build the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .

# Check if the container already exists, if so remove it
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    docker rm -f $CONTAINER_NAME
fi

# Run the container
echo "Starting container..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 8080:8080 \
    $IMAGE_NAME

echo "Container started! Access the API at http://localhost:8080/site_info?url=YOUR_URL" 