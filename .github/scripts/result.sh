#!/bin/bash
set -euo pipefail

BINARY_NAME="${1:-}"
if [ -z "$BINARY_NAME" ]; then
    echo "Error: Binary name is required"
    exit 1
fi

echo "Benchmark completed successfully!"
echo "Processing results for: $BINARY_NAME"

mkdir -p "binaries/$BINARY_NAME/obfuscated"
mkdir -p "binaries/$BINARY_NAME/configs"
mkdir -p "binaries/$BINARY_NAME/benchmarks"

if [ ! -f "benchmark_result.json" ]; then
    echo "Error: benchmark_result.json not found"
    exit 1
fi

OBFUSCATED_COUNT=$(cat benchmark_result.json | jq -r '.obfuscated_binaries | length')

[ "$OBFUSCATED_COUNT" -gt 0 ] || {
    echo "No obfuscated binaries to download"
    exit 0
}

echo "Downloading $OBFUSCATED_COUNT obfuscated binaries and configs..."

for i in $(seq 0 $((OBFUSCATED_COUNT-1))); do
    TOOL=$(cat benchmark_result.json | jq -r ".obfuscated_binaries[$i].tool")
    VARIANT=$(cat benchmark_result.json | jq -r ".obfuscated_binaries[$i].variant_name")
    BINARY_URL=$(cat benchmark_result.json | jq -r ".obfuscated_binaries[$i].file_path")
    CONFIG_URL=$(cat benchmark_result.json | jq -r ".obfuscated_binaries[$i].config_path // empty")
    
    echo "Downloading $TOOL ($VARIANT)..."
    
    [ "$BINARY_URL" = "null" ] || [ -z "$BINARY_URL" ] || {
        RETRY_COUNT=0
        MAX_RETRIES=10
        
        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            curl -s -o "binaries/$BINARY_NAME/obfuscated/${VARIANT}.exe" "$BINARY_URL"
            
            grep -q "InternalError" "binaries/$BINARY_NAME/obfuscated/${VARIANT}.exe" 2>/dev/null || {
                echo "  Downloaded binary: ${VARIANT}.exe"
                break
            }
            
            echo "    Waiting for CDN propagation... (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
            sleep 10
            RETRY_COUNT=$((RETRY_COUNT+1))
        done
        
        [ $RETRY_COUNT -lt $MAX_RETRIES ] || {
            echo "  WARNING: Failed to download ${VARIANT}.exe after $MAX_RETRIES attempts"
        }
    }
    
    [ "$CONFIG_URL" = "null" ] || [ -z "$CONFIG_URL" ] || {
        case "$TOOL" in
            "vmprotect") CONFIG_EXT=".vmp" ;;
            "codedefender") CONFIG_EXT=".yml" ;;
            *) CONFIG_EXT=".config" ;;
        esac
        
        curl -s -o "binaries/$BINARY_NAME/configs/${VARIANT}${CONFIG_EXT}" "$CONFIG_URL"
        echo "  Downloaded config: ${VARIANT}${CONFIG_EXT}"
    }
done

cp benchmark_result.json "binaries/$BINARY_NAME/benchmarks/latest.json"

METRICS_FILES=$(cat benchmark_result.json | jq -r '.metrics_files[]? // empty')
if [ ! -z "$METRICS_FILES" ]; then
    echo "Generated metrics files:"
    for file in $METRICS_FILES; do
        echo "  - $file"
    done
fi

echo "Results processing completed for $BINARY_NAME"