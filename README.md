 # Container ID Display Application

A simple Flask web application that displays the container ID when accessed. This application is containerized using Docker.

## Project Structure

- `app.py`: Main Flask application that displays the container ID
- `requirements.txt`: Python dependencies
- `Dockerfile`: Container configuration file

## Requirements

- Python 3.7+
- Docker
- Flask 2.0.1

## Setup and Running

### Local Development

1. Create a virtual environment (optional but recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the application:
   ```bash
   python app.py
   ```
   The application will be available at http://localhost:8080

### Using Docker

1. Build the Docker image:
   ```bash
   docker build -t container-id-app .
   ```

2. Run the container:
   ```bash
   docker run -p 8080:8080 container-id-app
   ```
   The application will be available at http://localhost:8080

## Features

- Displays the container ID of the running instance
- Runs on port 8080
- Lightweight Python Flask application
- Containerized for easy deployment 