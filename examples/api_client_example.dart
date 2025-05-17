import 'dart:io';

import 'package:api_dart/generated_api/api.dart';
import 'package:api_dart/generated_api/models.dart';
import 'package:http/http.dart' as http;

/// Example client application that demonstrates how to use the generated API client.
///
/// This example shows:
/// 1. How to create an API client
/// 2. How to authenticate with the API
/// 3. How to make authenticated requests
/// 4. How to handle errors
void main() async {
  // Create a client with a custom base URL
  final baseUrl = 'http://localhost:8081/api/v1';
  final client = ApiClient(baseUrl: baseUrl);
  
  print('API Dart Client Example');
  print('======================');
  print('Base URL: $baseUrl');
  
  try {
    // Check if the API is running
    print('\nChecking API health...');
    final health = await client.healthGet();
    print('API Health: $health');
    
    // Authenticate with the API
    print('\nAuthenticating...');
    final loginRequest = LoginRequest(
      username: 'testuser',
      password: 'password123',
    );
    
    final loginResponse = await client.authLogin(
      loginRequest: loginRequest,
    );
    
    print('Authentication successful!');
    print('Token: ${_maskToken(loginResponse.token)}');
    
    // Set the auth token for subsequent requests
    client.setBearerAuth(loginResponse.token);
    
    // Create an item
    print('\nCreating an item...');
    final createItemRequest = CreateItemRequest(
      name: 'Example Item',
      description: 'This item was created using the generated API client',
    );
    
    final createdItem = await client.itemsPost(
      createItemRequest: createItemRequest,
    );
    
    print('Item created:');
    print('  ID: ${createdItem.id}');
    print('  Name: ${createdItem.name}');
    print('  Description: ${createdItem.description}');
    
    // Get all items
    print('\nFetching all items...');
    final items = await client.itemsGet();
    
    print('Items:');
    for (final item in items.items!) {
      print('  - ${item.id}: ${item.name}');
    }
    
    // Get a specific item
    print('\nFetching item ${createdItem.id}...');
    final item = await client.itemsIdGet(id: createdItem.id!);
    
    print('Item details:');
    print('  ID: ${item.id}');
    print('  Name: ${item.name}');
    print('  Description: ${item.description}');
    
    // Update the item
    print('\nUpdating item ${createdItem.id}...');
    final updateItemRequest = UpdateItemRequest(
      name: 'Updated Example Item',
      description: 'This item was updated using the generated API client',
    );
    
    final updatedItem = await client.itemsIdPut(
      id: createdItem.id!,
      updateItemRequest: updateItemRequest,
    );
    
    print('Item updated:');
    print('  ID: ${updatedItem.id}');
    print('  Name: ${updatedItem.name}');
    print('  Description: ${updatedItem.description}');
    
    // Delete the item
    print('\nDeleting item ${createdItem.id}...');
    await client.itemsIdDelete(id: createdItem.id!);
    print('Item deleted successfully!');
    
    // Try to get the deleted item (should fail)
    print('\nTrying to fetch deleted item...');
    try {
      await client.itemsIdGet(id: createdItem.id!);
      print('Error: Item still exists!');
    } catch (e) {
      print('Expected error: Item not found');
    }
    
    // Generate text with AI
    print('\nGenerating text with AI...');
    final generateTextRequest = GenerateTextRequest(
      prompt: 'Write a short poem about APIs',
    );
    
    final generatedText = await client.generateTextPost(
      generateTextRequest: generateTextRequest,
    );
    
    print('Generated text:');
    print(generatedText.text);
    
  } catch (e) {
    if (e is http.ClientException) {
      print('\nError: Could not connect to the API.');
      print('Make sure the API server is running at $baseUrl');
    } else {
      print('\nError: $e');
    }
    exit(1);
  }
  
  print('\nExample completed successfully!');
}

/// Masks a token for display purposes, showing only the first and last 4 characters.
String _maskToken(String token) {
  if (token.length <= 8) {
    return token;
  }
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}
