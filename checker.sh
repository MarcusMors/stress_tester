#!/bin/bash
###!/bin/zsh is not supported :(

set -e
# g++-11 -std=c++20 code.cpp -o code.out
g++-11 -std=c++20 gen.cpp -o gen.out
g++-11 -std=c++20 brute.cpp -o brute.out

for ((i = 1; ; ++i)); do
    ./gen.out $i > input_file
    python3 ./code.py < input_file > myAnswer
    ./brute.out < input_file > correctAnswer
    diff -Z myAnswer correctAnswer > /dev/null || break
    echo "Passed test: "  $i
done

echo "WA on the following test:"
cat input_file
echo "Your answer is:"
cat myAnswer
echo "Correct answer is:"
cat correctAnswer