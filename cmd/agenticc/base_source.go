package main

import _ "embed"

// This file contains an embedded copy of the base binary source code
// for standalone compilation. It's kept in sync with cmd/base/main.go

//go:embed base_source.txt
var embeddedBaseSource string
