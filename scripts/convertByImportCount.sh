#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Finding files by import count"

# Get the list of files from getByImports.sh
files=$($DIR/getByImports.sh)

# Exit early if there are no files
if [ -z "$files" ]; then
  echo "No files found"
  exit 1
fi

echo "Converting $files"

# Run the typescriptify command with each file as an argument
yarn typescriptify convert $(echo "$files" | xargs -I{} echo "-p {}") --write --delete --useStrictAnyObjectType --useStrictAnyFunctionType --convertUnannotated
yarn typescriptify fix $(echo "$files" | xargs -I{} echo "-p {}") --tsProps --autoImport
