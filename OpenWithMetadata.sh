#!/bin/bash

file="$1"
comment="//"

metadata="$comment\tAuthor   =>  Daiyaan Muhammad Fardeen\n$comment\tFilename =>  $file\n$comment\tCreated  =>  $(date)\n\n#include <bits/stdc++.h>\n#include <iostream>\n\nusing namespace std;\n\nint main(int argc, char** argv){\n\n\treturn 0;\n}"
if test -e "$file"; then #testing for the existence of the file from the argument
    nvim "$file" #if file exists, no need to add anything, just open it
else
    touch "$file"
    # for line in $metadata; do
    #     printf "%s" "$line" >> "$file" #outputing each line to the file
    # done
    echo -e $metadata >> "$file" # fixed after it randomly stopped working
    nvim "$file" #opening the file with the editor
fi
