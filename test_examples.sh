#!/bin/bash

# Test script for agenticc examples
# Compiles, runs, and cleans up example C programs

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if agenticc exists
AGENTICC="./agenticc"
if [ ! -f "$AGENTICC" ]; then
    echo "Error: agenticc not found. Please build it first:"
    echo "  go build -o agenticc ./cmd/agenticc"
    exit 1
fi

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}Warning: OPENAI_API_KEY is not set. The compiled binaries will need it to run.${NC}"
fi

# Array to track created binaries for cleanup
BINARIES=()

# Function to cleanup binaries
cleanup() {
    echo -e "\n${BLUE}Cleaning up binaries...${NC}"
    for binary in "${BINARIES[@]}"; do
        if [ -f "$binary" ]; then
            rm -f "$binary"
            echo "  Removed $binary"
        fi
    done
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

echo -e "${GREEN}=== Testing agenticc Examples ===${NC}\n"

# Function to find and run binary
find_and_run() {
    local name=$1
    shift  # Remove first argument, rest are args for the binary
    
    # Check common locations
    if [ -f "$name" ]; then
        echo "$name"
    elif [ -f "examples/$name" ]; then
        echo "examples/$name"
    else
        echo "Error: Could not find binary $name" >&2
        exit 1
    fi
}

# Test 1: hello_world.c
echo -e "${BLUE}Test 1: hello_world.c${NC}"
echo "Compiling..."
"$AGENTICC" examples/hello_world.c -o hello_world -m gpt-4
BINARY_PATH=$(find_and_run hello_world)
BINARIES+=("$BINARY_PATH")
echo "Running..."
"$BINARY_PATH"
echo ""

# Test 2: adder.c
echo -e "${BLUE}Test 2: adder.c${NC}"
echo "Compiling..."
"$AGENTICC" examples/adder.c -o adder -m gpt-4
BINARY_PATH=$(find_and_run adder)
BINARIES+=("$BINARY_PATH")
echo "Running with arguments: 3 5 8"
"$BINARY_PATH" 3 5 8
echo ""

# Test 3: fibonacci.c
echo -e "${BLUE}Test 3: fibonacci.c${NC}"
echo "Compiling..."
"$AGENTICC" examples/fibonacci.c -o fibonacci -m gpt-4
BINARY_PATH=$(find_and_run fibonacci)
BINARIES+=("$BINARY_PATH")
echo "Running with argument: 10 (10th Fibonacci number)"
"$BINARY_PATH" 10
echo ""

echo -e "${GREEN}=== All tests completed successfully! ===${NC}"

