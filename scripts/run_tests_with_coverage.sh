#!/bin/bash

# Exit on error
set -e

# Clean up previous coverage data
rm -rf coverage
mkdir -p coverage

# Run tests with coverage
dart run coverage:test_with_coverage

# Generate LCOV report
dart run coverage:format_coverage --lcov --in=coverage/coverage.json --out=coverage/lcov.info --report-on=lib

# Print coverage summary
echo "Coverage report generated at coverage/lcov.info"
echo "To view the HTML report, install lcov and run:"
echo "  genhtml coverage/lcov.info -o coverage/html"
echo "Then open coverage/html/index.html in your browser"

# Check if lcov is installed
if command -v genhtml &> /dev/null; then
  # Generate HTML report
  genhtml coverage/lcov.info -o coverage/html
  echo "HTML report generated at coverage/html/index.html"
  
  # Open the report in the default browser if on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
  fi
else
  echo "lcov not installed. To install on macOS: brew install lcov"
  echo "To install on Ubuntu: sudo apt-get install lcov"
fi

# Calculate coverage percentage
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')
echo "Current test coverage: $COVERAGE"

# Define minimum coverage threshold
MIN_COVERAGE="80.0%"
MIN_COVERAGE_NUM=$(echo $MIN_COVERAGE | sed 's/%//')

# Extract numeric value from coverage percentage
COVERAGE_NUM=$(echo $COVERAGE | sed 's/%//')

# Compare coverage with threshold
if (( $(echo "$COVERAGE_NUM < $MIN_COVERAGE_NUM" | bc -l) )); then
  echo "Coverage is below the minimum threshold of $MIN_COVERAGE"
  echo "Please add more tests to improve coverage"
  exit 1
else
  echo "Coverage meets the minimum threshold of $MIN_COVERAGE"
fi
