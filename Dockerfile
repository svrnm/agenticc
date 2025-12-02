# Build stage
FROM golang:1.25-alpine@sha256:d3f0cf7723f3429e3f9ed846243970b20a2de7bae6a5b66fc5914e228d831bbb AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build agenticc
RUN go build -o agenticc ./cmd/agenticc

# Runtime stage
FROM alpine:latest@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412

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

