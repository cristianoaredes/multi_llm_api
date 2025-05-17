/// Interface for the generative service.
abstract class IGenerativeService {
  /// Generates text based on a prompt.
  ///
  /// [prompt] is the text prompt to generate from.
  /// Returns the generated text.
  Future<String> generateText(String prompt);

  /// Generates text based on a prompt with streaming response.
  ///
  /// [prompt] is the text prompt to generate from.
  /// Returns a stream of generated text chunks.
  Stream<String> generateTextStream(String prompt);

  /// Continues a chat conversation.
  ///
  /// [history] is the chat history in the format:
  /// ```
  /// [
  ///   {'role': 'user', 'text': 'Hello'},
  ///   {'role': 'model', 'text': 'Hi there!'},
  ///   ...
  /// ]
  /// ```
  /// [newMessage] is the new message from the user.
  /// Returns the model's response.
  Future<String> continueChat(
    List<Map<String, String>> history,
    String newMessage,
  );

  /// Continues a chat conversation with streaming response.
  ///
  /// [history] is the chat history in the format:
  /// ```
  /// [
  ///   {'role': 'user', 'text': 'Hello'},
  ///   {'role': 'model', 'text': 'Hi there!'},
  ///   ...
  /// ]
  /// ```
  /// [newMessage] is the new message from the user.
  /// Returns a stream of response text chunks.
  Stream<String> continueChatStream(
    List<Map<String, String>> history,
    String newMessage,
  );

  /// Returns the current model name being used
  String get modelName;

  /// Returns the current model configuration
  Map<String, dynamic> get modelConfig;

  /// Clears the response cache
  void clearCache();
}
