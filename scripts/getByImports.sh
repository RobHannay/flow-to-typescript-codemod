#!/usr/bin/env zsh

# Count files with x imports

countLTE=0

pathToRepo='../web'

grep -rl '@flow' --include='*.js' --exclude-dir='node_modules' $pathToRepo | while read -r file; do
  if [[ $(grep -c '^import' "$file") -le $countLTE ]]; then
    echo "$file"
  fi
done