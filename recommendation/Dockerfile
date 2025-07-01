# recommendation/Dockerfile
FROM golang:1.21-alpine
WORKDIR /app
COPY . .
RUN go build -o recommendation .
EXPOSE 9090
CMD ["./recommendation"]
