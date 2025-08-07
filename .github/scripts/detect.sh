#!/bin/bash
set -euo pipefail

EVENT_NAME="${1:-}"
BINARY_PATH_INPUT="${2:-}"
PDB_PATH_INPUT="${3:-}"

if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
    BINARY_PATH=$(printf '%s' "$BINARY_PATH_INPUT")
    PDB_PATH=$(printf '%s' "$PDB_PATH_INPUT")
    
    if [[ ! "$BINARY_PATH" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        echo "Error: Invalid binary path - contains disallowed characters"
        echo "has_binaries=false" >> $GITHUB_OUTPUT
        exit 1
    fi
    
    if [[ ! "$PDB_PATH" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        echo "Error: Invalid PDB path - contains disallowed characters"
        echo "has_binaries=false" >> $GITHUB_OUTPUT
        exit 1
    fi
    
    if [[ ! "$BINARY_PATH" =~ ^binaries/ ]]; then
        echo "Error: Binary must be in binaries/ directory"
        echo "has_binaries=false" >> $GITHUB_OUTPUT
        exit 1
    fi
    
    if [[ ! "$PDB_PATH" =~ ^binaries/ ]]; then
        echo "Error: PDB must be in binaries/ directory"
        echo "has_binaries=false" >> $GITHUB_OUTPUT
        exit 1
    fi
    
    if [ -f "$BINARY_PATH" ] && [ -f "$PDB_PATH" ]; then
        BINARY_NAME=$(basename "$BINARY_PATH" .exe)
        JSON_OUTPUT=$(jq -n \
            --arg name "$BINARY_NAME" \
            --arg bin "$BINARY_PATH" \
            --arg pdb "$PDB_PATH" \
            '[{name: $name, binary_path: $bin, pdb_path: $pdb}]')
        echo "binaries=$JSON_OUTPUT" >> $GITHUB_OUTPUT
        echo "has_binaries=true" >> $GITHUB_OUTPUT
    else
        echo "has_binaries=false" >> $GITHUB_OUTPUT
    fi
else
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
    
    HAS_BINARIES=false
    
    TEMP_JSON=$(mktemp)
    echo "[]" > "$TEMP_JSON"
    
    for file in $CHANGED_FILES; do
        [[ "$file" =~ ^binaries/[^/]+/[^/]+\.exe$ ]] || {
            echo "Skipping file (wrong pattern): $file"
            continue
        }
        
        FOLDER_NAME=$(echo "$file" | cut -d'/' -f2)
        BINARY_NAME=$(basename "$file" .exe)
        
        echo "Processing: $file -> folder='$FOLDER_NAME', binary='$BINARY_NAME'"
        
        [[ "$BINARY_NAME" == "$FOLDER_NAME" ]] || {
            echo "Skipping binary with mismatched name/folder: $file (folder: $FOLDER_NAME, binary: $BINARY_NAME)"
            continue
        }
        
        BINARY_PATH="$file"
        PDB_PATH="binaries/$FOLDER_NAME/$BINARY_NAME.pdb"
        
        [ -f "$PDB_PATH" ] && echo "$CHANGED_FILES" | grep -q "^$PDB_PATH$" || {
            echo "Skipping binary without matching PDB: $file"
            continue
        }
        
        echo "Found valid binary pair: $BINARY_PATH + $PDB_PATH"
        
        jq --arg name "$FOLDER_NAME" \
           --arg bin "$BINARY_PATH" \
           --arg pdb "$PDB_PATH" \
           '. += [{name: $name, binary_path: $bin, pdb_path: $pdb}]' \
           "$TEMP_JSON" > "$TEMP_JSON.tmp" && mv "$TEMP_JSON.tmp" "$TEMP_JSON"
        
        HAS_BINARIES=true
    done
    
    BINARIES=$(cat "$TEMP_JSON" | jq -c .)
    rm -f "$TEMP_JSON" "$TEMP_JSON.tmp"
    
    {
        echo "binaries<<EOF"
        echo "$BINARIES"
        echo "EOF"
        echo "has_binaries=$HAS_BINARIES"
    } >> $GITHUB_OUTPUT
fi