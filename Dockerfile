# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build agenticc
RUN go build -o agenticc ./cmd/agenticc

# Runtime stage
FROM alpine:latest

# Install Go runtime for building base binaries (agenticc needs go to build the base binary)
RUN apk add --no-cache go

WORKDIR /app

# Copy the agenticc binary
COPY --from=builder /build/agenticc /usr/local/bin/agenticc

# The base source is embedded in the binary, so no need to copy it separately
# But we'll keep the directory structure in case the fallback path is used
RUN mkdir -p /usr/local/share/agenticc

# Set entrypoint to agenticc
ENTRYPOINT ["agenticc"]

