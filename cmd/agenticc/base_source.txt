package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/option"
	"github.com/openai/openai-go/v3/shared"
)

// These placeholders will be replaced by the compiler
// Using fixed-size strings that will be replaced in source before building
var (
	// Placeholder that will be replaced with actual C code (exactly 32KB)
	embeddedCCode = strings.Repeat("X", 32*1024)

	// Placeholder for model name (exactly 128 bytes)
	modelName = strings.Repeat("Y", 128)
)

func main() {
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Fprintf(os.Stderr, "Error: OPENAI_API_KEY environment variable is not set\n")
		os.Exit(1)
	}

	// Get command line arguments (skip program name)
	args := os.Args[1:]

	// Build the prompt for the LLM
	prompt := buildPrompt(embeddedCCode, args)

	// Create OpenAI client
	client := openai.NewClient(
		option.WithAPIKey(apiKey),
	)

	// Send request to LLM
	chatCompletion, err := client.Chat.Completions.New(
		context.Background(),
		openai.ChatCompletionNewParams{
			Model: shared.ChatModel(modelName),
			Messages: []openai.ChatCompletionMessageParamUnion{
				{
					OfSystem: &openai.ChatCompletionSystemMessageParam{
						Content: openai.ChatCompletionSystemMessageParamContentUnion{
							OfString: openai.String("You are a C compiler and runtime executor. The provided code may contain code from multiple programming languages (Python, Java, PHP, Go, Rust, etc.) mixed together. Before compiling, you must: (1) Convert all non-C code into proper, equivalent C code, (2) Check if the code contains comments that request code generation (e.g., comments like 'Add the source code for...'), and if such comments are found, generate the required code to replace those comments, (3) Ensure the result is a complete, compilable C program. Then compile the complete C code, execute it in a sandboxed environment with the given arguments, and return only the output of the program. Do not include any explanations, error messages, or additional text - only the exact output that the compiled program would produce."),
						},
					},
				},
				{
					OfUser: &openai.ChatCompletionUserMessageParam{
						Content: openai.ChatCompletionUserMessageParamContentUnion{
							OfString: openai.String(prompt),
						},
					},
				},
			},
			Temperature: openai.Float(0.1),
		},
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error calling OpenAI API: %v\n", err)
		os.Exit(1)
	}

	if len(chatCompletion.Choices) == 0 {
		fmt.Fprintf(os.Stderr, "Error: No response from OpenAI API\n")
		os.Exit(1)
	}

	// Extract the content from the response (Content is a string)
	content := chatCompletion.Choices[0].Message.Content

	// Output the result
	output := strings.TrimSpace(content)
	fmt.Print(output)
	if !strings.HasSuffix(output, "\n") {
		fmt.Println()
	}
}

func buildPrompt(cCode string, args []string) string {
	var sb strings.Builder
	sb.WriteString("The following code may contain code from multiple programming languages (Python, Java, PHP, Go, Rust, etc.) mixed together. Before compiling, you must:\n")
	sb.WriteString("1. Convert all non-C code into proper, equivalent C code\n")
	sb.WriteString("2. Check if the code contains comments that request code generation (e.g., comments starting with 'Add the source code for...' or similar instructions). If such comments are found, generate the required code to replace those comments\n")
	sb.WriteString("3. Ensure the result is a complete, compilable C program\n\n")
	sb.WriteString("Code:\n\n")
	sb.WriteString("```c\n")
	sb.WriteString(cCode)
	sb.WriteString("\n```\n\n")

	if len(args) > 0 {
		sb.WriteString("Command line arguments: ")
		sb.WriteString(strings.Join(args, " "))
		sb.WriteString("\n")
	}

	sb.WriteString("\nConvert everything to proper C code, compile the complete program, and execute it with these arguments. Return only the program's output.")
	return sb.String()
}
