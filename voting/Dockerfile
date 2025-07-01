# voting/Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
RUN ./gradlew build --no-daemon
EXPOSE 8080
CMD ["java", "-jar", "build/libs/voting-0.0.1-SNAPSHOT.jar"]
