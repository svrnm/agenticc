Output agenticc.mp4
Set FontSize 20
Set Width 1024
Set Height 1024
#Set FontSize 31
#Set Width 1080
#Set Height 1920
Set Margin 10
Set Theme "iTerm2 Solarized Dark"
Set MarginFill "#000000"
Set WindowBar Colorful
Set BorderRadius 10

Set Shell bash
Sleep 1.5s
Type "bat -P examples/fibonacci.c"
Enter
# Type "[?64;1;2;4;6;17;18;21;22;52c"
Sleep 1s
Type "."
Sleep 500ms
Type "/agenticc —o fibonacci examples/fibonacci.c"
Enter
Sleep 2s
Type "./fibonacci "
Sleep 500ms
Type "10"
Enter
Sleep 3s

Type "# but agenticc can do more 🤖 - it supports agentic prompt-driven software development!"
Enter
Sleep 1s
Type "bat -P examples/fibonacci-2.c"
Enter
Sleep 1s
Type "."
Sleep 500ms
Type "/agenticc —o fibonacci-2 examples/fibonacci-2.c"
Enter
Sleep 2s
Type "./fibonacci-2 "
Sleep 500ms
Type "10"
Enter
Sleep 3s

Type "# and it can do even more 🌍 - it does not limit you to a single programming language!"
Enter
Sleep 1s
Type "bat -P examples/fizz-buzz.c"
Enter
Sleep 1s
Type "."
Sleep 500ms
Type "/agenticc —o fizz-buzz examples/fizz-buzz.c"
Enter
Sleep 2s
Type "./fizz-buzz "
Sleep 500ms
Type "15"
Enter
Sleep 5s

