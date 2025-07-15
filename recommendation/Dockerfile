FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY . .

RUN go build -o recommendation main.go

FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/recommendation .

EXPOSE 8000

CMD ["./recommendation"]
