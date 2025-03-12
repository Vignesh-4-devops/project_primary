# Use a more recent Python version
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY app.py .

# Set a non-root user for security
RUN useradd -m appuser
USER appuser

# Run the application
CMD ["python", "app.py"]
