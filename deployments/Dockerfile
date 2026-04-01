FROM golang:1.24-alpine AS builder

ENV GOTOOLCHAIN=auto
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -p 1 -ldflags="-s -w" -o /rentgo ./cmd/api

FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /rentgo .
EXPOSE 8080
CMD ["./rentgo"]
