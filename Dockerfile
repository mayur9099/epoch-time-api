# Using the official Python image from the Docker Hub
FROM python:3.8-slim

# Setting the working directory
WORKDIR /app

# Copying the requirements file into the container
COPY requirements.txt .

# Installing dependencies
RUN pip install -r requirements.txt

# Copying the rest of the application code into the container
COPY app.py .

# Expose the application port
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
