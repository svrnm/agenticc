Output agenticc.mp4
Set FontSize 20
Set Width 1024
Set Height 1024
Set Margin 10
Set Theme "iTerm2 Solarized Dark"
Set MarginFill "#000000"
Set WindowBar Colorful
Set BorderRadius 10

Set Shell zsh
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
Sleep 2s

