#!/bin/bash

MY_VAR=""

f () {
  var_name="MY_VAR"
  var_value="Hello, Globaooool!"
  eval "$var_name=\"$var_value\""
}

f
echo $MY_VAR

