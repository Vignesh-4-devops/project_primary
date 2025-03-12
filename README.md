 # Site Technologies Display Application

A simple Flask web application that displays the Site Technologies when accessed. This application is containerized using Docker.

## Project Structure

- `app.py`: Main Flask application that displays the Site Technologies
- `requirements.txt`: Python dependencies
- `Dockerfile`: Container configuration file

## Requirements

- Python 3.7+
- Docker
- Flask 2.0.1

## Setup and Running


### Using Docker

1. Just run ./run_analyzer.sh and app is ready to role.

2. The you can access the app on localhost 8080.

Example url - http://localhost:8080/site_info?url=https://www.amazon.com

FYI: Using Gunicorn (Recommended for Production)


## Features

- Displays the Site Technologies of the running instance, supports concurrency.
- Runs on port 8080
- Lightweight Python Flask application
- Containerized for easy deployment 