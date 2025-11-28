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

# Test 1: hello_world.c
echo -e "${BLUE}Test 1: hello_world.c${NC}"
echo "Compiling..."
"$AGENTICC" -o hello_world -m gpt-4 examples/hello_world.c
BINARIES+=("hello_world")
echo "Running..."
./hello_world
echo ""

# Test 2: adder.c
echo -e "${BLUE}Test 2: adder.c${NC}"
echo "Compiling..."
"$AGENTICC" -o adder -m gpt-4 examples/adder.c
BINARIES+=("adder")
echo "Running with arguments: 3 5 8"
./adder 3 5 8
echo ""

# Test 3: fibonacci.c
echo -e "${BLUE}Test 3: fibonacci.c${NC}"
echo "Compiling..."
"$AGENTICC" -o fibonacci -m gpt-4 examples/fibonacci.c
BINARIES+=("fibonacci")
echo "Running with argument: 10 (10th Fibonacci number)"
./fibonacci 10
echo ""

# Test 4: fibonacci-2.c (prompt-based code generation)
echo -e "${BLUE}Test 4: fibonacci-2.c (prompt-based)${NC}"
echo "Compiling..."
"$AGENTICC" -o fibonacci-2 -m gpt-4 examples/fibonacci-2.c
BINARIES+=("fibonacci-2")
echo "Running with argument: 10 (10th Fibonacci number)"
./fibonacci-2 10
echo ""

# Test 5: fizz-buzz.c (multi-language code)
echo -e "${BLUE}Test 5: fizz-buzz.c (multi-language)${NC}"
echo "Compiling..."
"$AGENTICC" -o fizz-buzz -m gpt-4 examples/fizz-buzz.c
BINARIES+=("fizz-buzz")
echo "Running with argument: 15 (FizzBuzz up to 15)"
./fizz-buzz 15
echo ""

echo -e "${GREEN}=== All tests completed successfully! ===${NC}"

