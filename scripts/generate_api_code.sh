#!/bin/bash

# Exit on error
set -e

echo "Starting API code generation..."

# Clean up previous generated code
if [ -d "lib/generated_api" ]; then
  echo "Cleaning up previous generated code..."
  rm -rf lib/generated_api
fi

# Run build_runner to generate code
echo "Running build_runner..."
dart run build_runner build --delete-conflicting-outputs

# Check if generation was successful
if [ -d "lib/generated_api" ]; then
  echo "API code generation completed successfully!"
  echo "Generated files are in lib/generated_api/"
  
  # Count generated files
  FILE_COUNT=$(find lib/generated_api -type f | wc -l)
  echo "Generated $FILE_COUNT files."
  
  # List generated files
  echo "Generated files:"
  find lib/generated_api -type f -name "*.dart" | sort
else
  echo "Error: API code generation failed. Check the build_runner output for errors."
  exit 1
fi

echo "Done!"
