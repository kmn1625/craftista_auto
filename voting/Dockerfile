FROM gradle:8.4.0-jdk17 AS builder

WORKDIR /home/app

COPY . .

RUN gradle build --no-daemon

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=builder /home/app/build/libs/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
