#!/usr/bin/env zsh

files=(../web-clone/web/blink/constants/*.js)
total=${#files[@]}
index=0
successful=0

for file in "${files[@]}"; do
  ((index++))
  echo "Processing file $index of $total: $file"
  echo "Current success: $successful"
  cp "$file" "$file.bak"
  echo "🔧 Converting $file to TS"
  yarn typescriptify convert -p "$file" --write --delete --useStrictAnyObjectType --useStrictAnyFunctionType --convertUnannotated --disableFlow
  yarn typescriptify fix -p "$file" --tsProps --autoImport

  fileName=${file%.*}
  if test -f "$fileName.ts"; then
    tsFileName="$fileName.ts"
  elif test -f "$fileName.tsx"; then
    tsFileName="$fileName.tsx"
  else
    echo "🚨 No $fileName.ts/tsx file found"
    break
  fi

  echo "🔎 Found $tsFileName file. Checking validity..."

  fileFromRoot=$(echo "$tsFileName" | sed 's/\.\.\/web-clone\/web\//.\//g')

  # Replace "../web-clone/web/" with "./"

  if pnpm -C ../web-clone/web/ exec eslint --fix "$fileFromRoot" && pnpm -C ../web-clone/web/ localbuild; then
    echo "🎉 Successfully converted ${file}. Removing backup."
    rm "$file.bak"
    ((successful++))
  else
    echo "❌ Type or lint errors after converting ${file}. Restoring backup."
    mv "$file.bak" "$file"
    echo "🗑️ Removing $tsFileName file"
    rm $tsFileName
  fi

  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
done

echo "Finished processing $total files. $successful were successful 🕺"
