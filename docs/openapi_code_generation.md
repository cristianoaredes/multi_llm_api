# OpenAPI Code Generation Guide

This document provides information about OpenAPI code generation in the API Dart project.

## Overview

The API Dart project uses the `swagger_dart_code_generator` package to generate Dart code from the OpenAPI specification. This allows us to maintain a single source of truth for our API definition and automatically generate client-side code for API consumption.

## OpenAPI Specification

The OpenAPI specification is located at `openapi/openapi.yaml`. This file defines:

- API endpoints
- Request and response schemas
- Authentication methods
- Data models

## Code Generation Configuration

The code generation is configured in the `build.yaml` file at the root of the project. The configuration includes:

- Input and output paths
- Code generation options
- Type mappings
- Response overrides
- Class name mappings

## Generated Code Structure

The generated code is placed in the `lib/generated_api/` directory and includes:

- **Models**: Data classes for request and response objects
- **API Clients**: Classes for making API requests
- **Enums**: Enumeration types defined in the OpenAPI spec
- **Converters**: JSON serialization/deserialization utilities

## Running Code Generation

### Using the Script

We've provided a script to run the code generation:

```bash
./scripts/generate_api_code.sh
```

This script will:
1. Clean up previously generated code
2. Run the build_runner to generate new code
3. Verify the generation was successful
4. List the generated files

### Manual Generation

If you prefer to run the steps manually:

```bash
# Clean up previous generated code (optional)
rm -rf lib/generated_api

# Run build_runner
dart run build_runner build --delete-conflicting-outputs
```

## Using Generated Code

### API Client

The generated API client can be used to make requests to the API:

```dart
import 'package:multi_llm_api/generated_api/api.dart';

void main() async {
  final api = ApiClient(baseUrl: 'http://localhost:8081/api/v1');
  
  // Authentication
  final loginResponse = await api.authLogin(
    loginRequest: LoginRequest(username: 'user', password: 'password'),
  );
  
  // Set the auth token for subsequent requests
  api.setBearerAuth(loginResponse.token);
  
  // Make authenticated requests
  final items = await api.itemsGet();
  print(items);
}
```

### Models

The generated models can be used for request and response objects:

```dart
import 'package:multi_llm_api/generated_api/models.dart';

// Create a request model
final createItemRequest = CreateItemRequest(
  name: 'New Item',
  description: 'This is a new item',
);

// Parse a response model from JSON
final item = Item.fromJson(jsonMap);
```

## Updating the API

When the OpenAPI specification is updated, follow these steps:

1. Update the `openapi/openapi.yaml` file
2. Run the code generation script: `./scripts/generate_api_code.sh`
3. Update any code that uses the generated API client or models

## Best Practices

1. **Don't modify generated code**: The generated code is overwritten each time the code generation runs. If you need to customize behavior, create wrapper classes.

2. **Keep the OpenAPI spec up to date**: The OpenAPI specification should be the source of truth for the API. When you make changes to the API, update the spec first.

3. **Use type-safe models**: The generated models provide type safety. Use them instead of raw JSON maps.

4. **Handle errors properly**: The generated API client throws exceptions for error responses. Make sure to handle these exceptions in your code.

5. **Test with generated code**: Write tests that use the generated API client to ensure it works as expected.

## Troubleshooting

### Common Issues

1. **Generation fails with errors**:
   - Check the OpenAPI specification for syntax errors
   - Ensure the specification follows the OpenAPI 3.x standard
   - Check for circular references in the schema definitions

2. **Generated code doesn't match expectations**:
   - Review the configuration in `build.yaml`
   - Check the OpenAPI specification for inconsistencies
   - Ensure the response types are correctly defined

3. **Runtime errors when using generated code**:
   - Check if the API implementation matches the OpenAPI specification
   - Ensure the server returns responses in the expected format
   - Verify that required fields are properly defined in the specification

### Getting Help

If you encounter issues with the code generation, check the following resources:

- [swagger_dart_code_generator documentation](https://pub.dev/packages/swagger_dart_code_generator)
- [OpenAPI Specification](https://swagger.io/specification/)
- Project issue tracker
