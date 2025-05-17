# Test Coverage Guide

This document provides information about test coverage in the API Dart project.

## Overview

Test coverage is an important metric that helps us ensure our code is properly tested. It measures the percentage of code that is executed during tests. High test coverage gives us confidence that our code works as expected and helps catch regressions when making changes.

## Coverage Requirements

- **Minimum Coverage Threshold**: 80%
- **Target Coverage**: 90%+

## Running Tests with Coverage

### Using the Script

We've provided a script to run tests with coverage and generate reports:

```bash
./scripts/run_tests_with_coverage.sh
```

This script will:
1. Run all tests with coverage collection
2. Generate an LCOV report
3. Create an HTML report (if lcov is installed)
4. Check if coverage meets the minimum threshold

### Manual Steps

If you prefer to run the steps manually:

```bash
# Run tests with coverage
dart run coverage:test_with_coverage

# Format coverage data to LCOV
dart run coverage:format_coverage --lcov --in=coverage/coverage.json --out=coverage/lcov.info --report-on=lib

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

## Viewing Coverage Reports

After running the tests with coverage, you can view the reports in several ways:

1. **HTML Report**: Open `coverage/html/index.html` in your browser for a detailed visual report
2. **LCOV Report**: The raw LCOV data is available in `coverage/lcov.info`
3. **Console Output**: The script will print a summary of the coverage to the console

## Continuous Integration

Test coverage is automatically checked in our CI pipeline:

1. GitHub Actions runs tests with coverage on every push and pull request
2. Coverage reports are uploaded to Codecov
3. The build will fail if coverage falls below the minimum threshold

## Improving Coverage

If coverage is below the threshold, here are some strategies to improve it:

1. **Identify Uncovered Code**: Look at the HTML report to find uncovered lines
2. **Write Missing Tests**: Focus on adding tests for uncovered code paths
3. **Test Edge Cases**: Ensure your tests cover error conditions and edge cases
4. **Integration Tests**: Add integration tests to cover code that unit tests miss

## Excluding Code from Coverage

Sometimes it makes sense to exclude certain code from coverage calculations:

```dart
// coverage:ignore-start
void debugOnly() {
  // This code won't be counted in coverage
}
// coverage:ignore-end
```

Use this sparingly and only for code that genuinely doesn't need testing, such as:
- Debug-only utilities
- Platform-specific code that can't be tested in the current environment
- Generated code

## Best Practices

1. **Write Tests First**: Follow TDD principles when possible
2. **Test Behavior, Not Implementation**: Focus on testing what the code does, not how it does it
3. **Keep Tests Focused**: Each test should verify a specific behavior
4. **Maintain Test Quality**: Tests should be readable, maintainable, and reliable
5. **Don't Chase Coverage**: Don't write tests just to increase coverage; write meaningful tests
