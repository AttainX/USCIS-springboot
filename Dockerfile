# Use a base image with Java pre-installed
FROM openjdk:17-jdk

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled Spring Boot application JAR file into the container
COPY build/libs/*.jar app.jar

# Expose the port that the Spring Boot application will listen on
EXPOSE 8080

# Define the command to run the Spring Boot application when the container starts
CMD ["java", "-jar", "app.jar"]
