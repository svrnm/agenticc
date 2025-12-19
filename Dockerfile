# Build stage
FROM golang:1.25-alpine@sha256:72567335df90b4ed71c01bf91fb5f8cc09fc4d5f6f21e183a085bafc7ae1bec8 AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build agenticc
RUN go build -o agenticc ./cmd/agenticc

# Runtime stage
FROM alpine:latest@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62

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

