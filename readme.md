<!--
 Copyright (C) 2025 José Enrique Vilca Campana
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

# CP stress tester

This tool is able to create a Random Number Generator file and is able to execute it to compare the results of two solutions.
If you don't know what a stress test is and why is it important, read 

## Set up

Requirements:

```bash
  sudo apt install dialog
``` 

## How to use it?

To create a Random Number Generator file and test config, just execute it. (The program creates the file in the current directory)

```bash
   stress_tester
```

To stress test based on your Random Number Generator file and test config.

```bash
   stress_tester RNG_<problem>.py
```


## What is stress testing?

is to test your program with random input, is to "put your program under stress".

## How to use stress testing in competitive programming?

You have a problem that it's hard and has various edge cases. However the brute force solution is kinda trivial.
So you try to get the efficient solution and test its correctness against the brute force solution.

In this case, we won't manage all kinds of input, we will test the program assuming the problem limits are true.

## Why is it important in competitive programming learning or to learn in general?

Honestly, i have the feeling of learning using stress testing.
It keeps me motivated to find the edge cases and correctness of a problem.
Howerver, i wonder if it will numb my own sense of searching these cases by my own.
Anyways, i also created this tool to help new programmers to test their solutions against the correct one and see easily the failure cases of their program.
Mainly, i was thinking of the "Concurso Escolar de Programación CEP", i want as many of them to don't feel distressed and don't give up.


## Extra recommendations

Use Address sanitizer,
I created this video explaining how to use it in vscode.
I recommend watching this video ....

Learn Mathematics with mathanki


## Buy me a coffe/apicito!

here is my yape QR

