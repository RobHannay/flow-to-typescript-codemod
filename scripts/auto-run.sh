#!/usr/bin/env zsh

# You're need to set the references to `../web-clone/web` to be whatever path you have

repoPath="../web-clone/web"

echo "🗃️ Finding files in $repoPath"

setopt extended_glob
#negation eg
# files=(../web-clone/web/blink/^components/**/*.js)
#jsFilesInDir=(../web-clone/web/webapp/src/components/**/*.js)
#jsFilesInDir=("$repoPath"/apps/src/components/Test/Test.test.js)
#jsFilesInDir=("$repoPath"/dashboard/src/^{components,reducers,selectors,utils}/**/*.js)
#jsFilesInDir=("$repoPath"/webapp/src/**/*.js)


jsFilesInDir=("$repoPath"/blink/**/*.js)

# Optionally, add a path here to restart the script from a specific point.
# This is useful if the script fails and you want to restart from a specific file.
# e.g. restartPoint=("$repoPath"/webapp/src/components/)
restartPoint=("$repoPath"/)

# Filter `jsFilesInDir` to those that only include the @flow Pragma
files=()
for file in $jsFilesInDir; do
  if grep -q '@flow' "$file" && [[ $file > $restartPoint ]]; then
    files+=($file)
  fi
done

total=${#files[@]}
index=0
successful=0

for file in "${files[@]}"; do
  ((index++))
  echo "Processing file $index of $total: $file"
  echo "Current success: $successful"
  cp "$file" "$file.bak"
  echo "🔧 Converting $file to TS"
  yarn typescriptify convert -p "$file" --write --delete --useStrictAnyObjectType --useStrictAnyFunctionType --convertUnannotated
  yarn typescriptify fix -p "$file" --tsProps --autoImport

  fileName=${file%.*}
  if test -f "$fileName.ts"; then
    tsFileName="$fileName.ts"
  elif test -f "$fileName.tsx"; then
    tsFileName="$fileName.tsx"
  else
    echo "🚨 No $fileName.ts/tsx file found. Conversion must have failed. Restoring backup."
    mv "$file.bak" "$file"
    continue
  fi

  echo "🔎 Found $tsFileName file."

  # ------------ Check for `package.json` existence ----------------

  # Extract the directory path and file name from the JavaScript file path
#  dir_path=$(dirname "$file")
#  file_name=$(basename "$file")

#  # Check if package.json exists in the same directory
#  echo "Checking for co-located package.json"
#  if [ -f "$dir_path/package.json" ]; then
#      echo "📦 package.json exists"
#      # Extract the "main" field from package.json
#      main_field=$(jq -r '.main' "$dir_path/package.json")
#
#      # Get the base name of the "main" field
#      main_file_name=$(basename "$main_field")
#
#      echo "main file $main_file_name vs converted file $file_name"
#
#      # Compare the extracted main file name with the provided JavaScript file name
#      if [ "$main_file_name" = "$file_name" ]; then
#          echo "📦 package.json matches!"
#          # Replace the file extension with the TS file name
#          new_main_field=$(basename "$tsFileName")
#
#          # Rename the JavaScript file to the new TypeScript file
#          jq --arg new_main "$new_main_field" '.main = $new_main' "$dir_path/package.json" > tmp_package.json
#          mv "$dir_path/package.json" "$dir_path/package.json.bak"
#          mv tmp_package.json "$dir_path/package.json"
#          echo "Updated the 'main' field in package.json to $new_main_field"
#      else
#          echo "Main field in package.json doesn't match the provided JavaScript file."
#      fi
#  else
#      echo "No package.json found in the same directory."
#  fi

  # -------- End of package.json stuff ------------


  echo "✅ Checking validity. Linting..."

  # Replace "../web-clone/web/" with "./"
  fileFromRoot=$(echo "$tsFileName" | sed "s%$repoPath%.%")

  if pnpm -C "$repoPath" exec eslint --fix "$fileFromRoot" && echo "💅 Linted. Building..." && PROJECT=nodeServices pnpm -C "$repoPath" exec rsbuild build; then
    echo "🎉 Successfully converted ${file}. Removing backup."
    rm "$file.bak"
#    if [ -f "$dir_path/package.json.bak" ]; then
#      rm "$dir_path/package.json.bak"
#    fi
    ((successful++))
  else
    echo "❌ Type or lint errors after converting ${file}. Restoring backup."
    mv "$file.bak" "$file"
    echo "🗑️ Removing $tsFileName file"
    rm $tsFileName

#    if [ -f "$dir_path/package.json.bak" ]; then
#      echo "🌸️ Restoring $dir_path/package.json"
#      rm "$dir_path/package.json"
#      mv "$dir_path/package.json.bak" "$dir_path/package.json"
#    fi

    # -- Revert Snapshot files if necessary ---
    DIR_PATH=${tsFileName:h}
    TS_FILE_NAME=${tsFileName:t}
    JS_FILE_NAME=${file:t}

    # Build the snapshot file path
    TS_SNAPSHOT_FILE_PATH="${DIR_PATH}/__snapshots__/${TS_FILE_NAME}.snap"
    JS_SNAPSHOT_FILE_PATH="${DIR_PATH}/__snapshots__/${JS_FILE_NAME}.snap"

    echo "looking for $TS_SNAPSHOT_FILE_PATH"
    if [ -f "$TS_SNAPSHOT_FILE_PATH" ]; then
      echo "📸️ Found auto-migrated snapshot file too"
      mv "$TS_SNAPSHOT_FILE_PATH" "$JS_SNAPSHOT_FILE_PATH"
    fi
  fi

  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
done

echo "Finished processing $total files. $successful were successful 🕺"
