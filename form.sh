#!/bin/zsh

function DialogGen () {
  integer height=15
  integer width=40
  integer form_height=6

  dialog --form "please enter the required information" \
  $height $width $form_height \
  "Name:" 1 1 "" 1 12 15 0 \
  "Age:"  2 1 "" 2 12 15 0 \
  "Mail id:" 4 3 "" 4 15 10 0 \
  # "Mail idd:" 5 1 "" 5 12 15 0 
}

DialogGen