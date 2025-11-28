package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	codeMarker   = "AGENTICC_CODE_MARKER_START_"
	modelMarker  = "AGENTICC_MODEL_MARKER_"
	maxCodeSize  = 32 * 1024 // 32KB should be enough for most C programs
	maxModelSize = 128       // 128 bytes for model name
)

func main() {
	// Normalize em dashes to regular hyphens in arguments
	normalizeArgs()

	// Manually parse all arguments to support flags before and after the input file
	var (
		outputFile = ""
		model      = "gpt-4"
		inputFile  = ""
	)

	// Parse all arguments
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]

		// Check if it's a flag
		if strings.HasPrefix(arg, "-") {
			// Handle -o flag
			if arg == "-o" {
				if i+1 < len(os.Args) {
					outputFile = os.Args[i+1]
					i++ // Skip the value
				}
			} else if strings.HasPrefix(arg, "-o=") {
				// Handle -o=value format
				outputFile = strings.TrimPrefix(arg, "-o=")
			} else if arg == "-m" {
				// Handle -m flag
				if i+1 < len(os.Args) {
					model = os.Args[i+1]
					i++ // Skip the value
				}
			} else if strings.HasPrefix(arg, "-m=") {
				// Handle -m=value format
				model = strings.TrimPrefix(arg, "-m=")
			}
		} else {
			// Not a flag, must be the input file
			if inputFile == "" {
				inputFile = arg
			}
		}
	}

	if inputFile == "" {
		fmt.Fprintf(os.Stderr, "Usage: %s [options] <input.c> [options]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  -o string\n")
		fmt.Fprintf(os.Stderr, "    \tOutput binary name (default: input filename without .c extension)\n")
		fmt.Fprintf(os.Stderr, "  -m string\n")
		fmt.Fprintf(os.Stderr, "    \tOpenAI model to use (default: gpt-4)\n")
		os.Exit(1)
	}

	// If no output file specified, derive it from input file
	if outputFile == "" {
		// Remove .c extension if present, otherwise use input filename
		if strings.HasSuffix(inputFile, ".c") {
			outputFile = strings.TrimSuffix(inputFile, ".c")
		} else {
			outputFile = inputFile
		}
	}

	// Read the C source file
	cCode, err := os.ReadFile(inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Print initial agentic compilation message
	fmt.Printf("🤖 Agentically compiling %s\n", inputFile)

	// Build the base binary with the actual code embedded
	baseBinaryPath, err := buildBaseBinaryWithCode(string(cCode), model)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error building base binary: %v\n", err)
		os.Exit(1)
	}
	defer os.Remove(baseBinaryPath)

	// Copy the built binary to the output location
	baseBinary, err := os.ReadFile(baseBinaryPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading base binary: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile(outputFile, baseBinary, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing output file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Successfully agentically compiled %s — %s\n", inputFile, outputFile)
}

func buildBaseBinaryWithCode(cCode string, modelName string) (string, error) {
	// Create a temporary directory for the base binary source
	tmpDir, err := os.MkdirTemp("", "agenticc-base-*")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(tmpDir)

	// Read the base source code from various possible locations
	baseSourceCode, err := readBaseSource()
	if err != nil {
		return "", fmt.Errorf("failed to read base source: %v", err)
	}

	// Replace placeholders in the source code before building
	// Replace the embeddedCCode assignment (looking for the strings.Repeat pattern)
	// Don't pad - just use the code directly
	codeReplacement := fmt.Sprintf("\tembeddedCCode = %q", cCode)

	// Replace the modelName assignment
	// Don't pad with nulls - just use the model name directly
	// The string will be stored correctly by Go
	modelReplacement := fmt.Sprintf("\tmodelName = %q", modelName)

	// Replace the variable assignments in the source using line-by-line replacement
	// This is more reliable than string replacement
	lines := strings.Split(baseSourceCode, "\n")
	codeReplaced := false
	modelReplaced := false
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		// Match embeddedCCode line - more flexible matching
		if !codeReplaced && strings.Contains(trimmed, "embeddedCCode") && strings.Contains(trimmed, "strings.Repeat") && strings.Contains(trimmed, "X") {
			// Preserve indentation
			indent := strings.TrimSuffix(line, trimmed)
			lines[i] = indent + strings.TrimSpace(codeReplacement)
			codeReplaced = true
		}
		// Match modelName line - more flexible matching
		if !modelReplaced && strings.Contains(trimmed, "modelName") && strings.Contains(trimmed, "strings.Repeat") && strings.Contains(trimmed, "Y") {
			indent := strings.TrimSuffix(line, trimmed)
			lines[i] = indent + strings.TrimSpace(modelReplacement)
			modelReplaced = true
		}
	}

	// Print message when placeholders are being replaced
	if codeReplaced && modelReplaced {
		fmt.Println("🔗 Linking agents...")
	}

	// Verify replacements happened
	if !codeReplaced {
		fmt.Fprintf(os.Stderr, "Warning: embeddedCCode replacement not found in source\n")
	}
	if !modelReplaced {
		fmt.Fprintf(os.Stderr, "Warning: modelName replacement not found in source\n")
	}

	modifiedSource := strings.Join(lines, "\n")

	// Write the modified source code to the temp directory
	sourcePath := filepath.Join(tmpDir, "main.go")
	if err := os.WriteFile(sourcePath, []byte(modifiedSource), 0644); err != nil {
		return "", fmt.Errorf("failed to write base source: %v", err)
	}

	// Initialize Go module
	cmd := exec.Command("go", "mod", "init", "agenticc-base")
	cmd.Dir = tmpDir
	cmd.Env = os.Environ()
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("go mod init failed: %v\n%s", err, stderr.String())
	}

	// Get the required dependency
	cmd = exec.Command("go", "get", "github.com/openai/openai-go/v3@v3.8.1")
	cmd.Dir = tmpDir
	cmd.Env = os.Environ()
	stderr.Reset()
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("go get failed: %v\n%s", err, stderr.String())
	}

	// Tidy the module
	cmd = exec.Command("go", "mod", "tidy")
	cmd.Dir = tmpDir
	cmd.Env = os.Environ()
	stderr.Reset()
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("go mod tidy failed: %v\n%s", err, stderr.String())
	}

	// Create a temporary file for the compiled base binary
	tmpFile, err := os.CreateTemp("", "agenticc-base-binary-*")
	if err != nil {
		return "", err
	}
	tmpFile.Close()
	tmpPath := tmpFile.Name()

	// Build the base binary (build from current directory since cmd.Dir is set)
	cmd = exec.Command("go", "build", "-o", tmpPath, ".")
	cmd.Dir = tmpDir
	cmd.Env = os.Environ()
	stderr.Reset()
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("go build failed: %v\n%s", err, stderr.String())
	}

	return tmpPath, nil
}

func replacePlaceholders(binary []byte, cCode string, modelName string) []byte {
	codeBytes := []byte(cCode)
	modelBytes := []byte(modelName)

	// Check if code is too long
	if len(codeBytes) > maxCodeSize {
		fmt.Fprintf(os.Stderr, "Warning: C code exceeds %d bytes, truncating\n", maxCodeSize)
		codeBytes = codeBytes[:maxCodeSize]
	}

	// Check if model name is too long
	if len(modelBytes) > maxModelSize {
		fmt.Fprintf(os.Stderr, "Warning: Model name exceeds %d bytes, truncating\n", maxModelSize)
		modelBytes = modelBytes[:maxModelSize]
	}

	// Find code marker and replace the entire 32KB area starting from it
	codeMarkerBytes := []byte(codeMarker)
	idx := bytes.Index(binary, codeMarkerBytes)
	if idx == -1 {
		fmt.Fprintf(os.Stderr, "Error: Could not find code marker in base binary\n")
		os.Exit(1)
	}

	// Replace in-place: exactly maxCodeSize bytes starting from the marker
	placeholderStart := idx
	placeholderEnd := placeholderStart + maxCodeSize
	if placeholderEnd > len(binary) {
		fmt.Fprintf(os.Stderr, "Error: Code placeholder area extends beyond binary\n")
		os.Exit(1)
	}

	replacement := make([]byte, maxCodeSize)
	copy(replacement, codeBytes)
	// Rest is zeros (null bytes) from make()
	copy(binary[placeholderStart:placeholderEnd], replacement)

	// Find model marker and replace the entire 128-byte area starting from it
	modelMarkerBytes := []byte(modelMarker)
	idx = bytes.Index(binary, modelMarkerBytes)
	if idx == -1 {
		fmt.Fprintf(os.Stderr, "Error: Could not find model marker in base binary\n")
		os.Exit(1)
	}

	// Replace in-place: exactly maxModelSize bytes starting from the marker
	placeholderStart = idx
	placeholderEnd = placeholderStart + maxModelSize
	if placeholderEnd > len(binary) {
		fmt.Fprintf(os.Stderr, "Error: Model placeholder area extends beyond binary\n")
		os.Exit(1)
	}

	modelReplacement := make([]byte, maxModelSize)
	copy(modelReplacement, modelBytes)
	// Rest is zeros from make()
	copy(binary[placeholderStart:placeholderEnd], modelReplacement)

	return binary
}

func readBaseSource() (string, error) {
	// First try the embedded source (for standalone binaries)
	if embeddedBaseSource != "" {
		return embeddedBaseSource, nil
	}

	// Fallback: try multiple possible paths for the base source
	possiblePaths := []string{
		"cmd/base/main.go", // Relative to project root
		filepath.Join(filepath.Dir(os.Args[0]), "..", "cmd", "base", "main.go"), // Relative to binary
		filepath.Join(filepath.Dir(os.Args[0]), "cmd", "base", "main.go"),       // Alternative relative to binary
	}

	for _, path := range possiblePaths {
		if data, err := os.ReadFile(path); err == nil {
			return string(data), nil
		}
	}

	return "", fmt.Errorf("could not find base source code in any of the expected locations")
}

// normalizeArgs replaces em dashes (—) with regular hyphens (-) in command-line arguments
// This allows users to use —o and —m instead of -o and -m
func normalizeArgs() {
	for i, arg := range os.Args {
		// Only process arguments that start with an em dash (Unicode character)
		if strings.HasPrefix(arg, "—") {
			// Replace em dash with regular hyphen
			os.Args[i] = "-" + strings.TrimPrefix(arg, "—")
		}
	}
}
