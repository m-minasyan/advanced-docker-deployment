#!/bin/bash

# Advanced Docker Deployment Script with Multiple Containers and Enhanced Health Checks

# Load configuration from file
source config.env

# Log file location
LOG_FILE="deployment.log"

# JSON formatted logging
log_message() {
    local message="$1"
    echo "{\"date\": \"$(date)\", \"message\": \"$message\"}" | tee -a "$LOG_FILE"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_message "Docker is not installed. Please install Docker and try again."
        exit 1
    fi
}

# Pull Docker image
pull_docker_image() {
    local image_name="$1"
    log_message "Pulling Docker image: $image_name..."
    if docker pull "$image_name"; then
        log_message "Image pulled successfully."
    else
        log_message "Failed to pull the image."
        exit 1
    fi
}

# Run Docker container with environment variables and port configuration
run_docker_container() {
    local image_name="$1"
    local env_vars="$2"
    local ports="$3"
    log_message "Running Docker container from image: $image_name..."
    local container_id=$(docker run -d $env_vars $ports "$image_name")

    if [ -z "$container_id" ]; then
        log_message "Failed to start the container."
        exit 1
    else
        log_message "Container started successfully. Container ID: $container_id"
        echo "$container_id"
    fi
}

# Check the status of the container
check_container_status() {
    local container_id="$1"
    log_message "Checking status of the container: $container_id..."
    local status=$(docker container inspect -f '{{.State.Status}}' "$container_id")

    if [ "$status" == "running" ]; then
        log_message "Container is running."
    else
        log_message "Container is not running. Status: $status"
        exit 1
    fi
}

# Health check for the Docker container
container_health_check() {
    local container_id="$1"
    # Enhance this function based on your application's health check requirements
    # Example health check
    local port_check=$(docker container port "$container_id" | grep '80/tcp')
    if [ -n "$port_check" ]; then
        log_message "Health check passed: Port 80 is open."
    else
        log_message "Health check failed: Port 80 is not open."
        exit 1
    fi
}

# Stop and remove Docker container
stop_and_remove_container() {
    local container_id="$1"
    log_message "Stopping and removing container: $container_id..."
    docker stop "$container_id" && docker rm "$container_id"
    log_message "Container stopped and removed: $container_id"
}

# Main function with command line arguments
main() {
    local action=$1 # start or stop
    local image=${2:-$DOCKER_IMAGE} # Use second argument or default to DOCKER_IMAGE

    check_docker

    if [ "$action" == "start" ]; then
        pull_docker_image "$image"
        local container_id=$(run_docker_container "$image" "$DOCKER_ENV_VARS" "$DOCKER_PORTS")
        sleep 5 # Give the container time to start
        check_container_status "$container_id"
        container_health_check "$container_id"
    elif [ "$action" == "stop" ]; then
        stop_and_remove_container "$image"
    else
        log_message "Invalid action: $action. Use 'start' or 'stop'."
        exit 1
    fi
}

# Execute the script with command line arguments
main "$@"
