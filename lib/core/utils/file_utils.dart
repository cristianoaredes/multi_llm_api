import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

/// Utility class for file operations.
class FileUtils {
  /// Private constructor to prevent instantiation.
  FileUtils._();

  /// Logger for file operations.
  static final _log = Logger('FileUtils');

  /// Reads the contents of a file as a string.
  ///
  /// [filePath] is the path to the file.
  /// [encoding] is the encoding to use (defaults to UTF-8).
  ///
  /// Returns the contents of the file as a string.
  /// Throws a [FileSystemException] if the file cannot be read.
  static Future<String> readFileAsString(
    String filePath, {
    Encoding encoding = utf8,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }
      return await file.readAsString(encoding: encoding);
    } catch (e) {
      _log.severe('Error reading file: $filePath', e);
      rethrow;
    }
  }

  /// Reads the contents of a file as bytes.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the contents of the file as a list of bytes.
  /// Throws a [FileSystemException] if the file cannot be read.
  static Future<List<int>> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }
      return await file.readAsBytes();
    } catch (e) {
      _log.severe('Error reading file: $filePath', e);
      rethrow;
    }
  }

  /// Writes a string to a file.
  ///
  /// [filePath] is the path to the file.
  /// [content] is the string to write.
  /// [encoding] is the encoding to use (defaults to UTF-8).
  /// [mode] is the file mode (defaults to write).
  ///
  /// Returns the file that was written to.
  /// Throws a [FileSystemException] if the file cannot be written to.
  static Future<File> writeFile(
    String filePath,
    String content, {
    Encoding encoding = utf8,
    FileMode mode = FileMode.write,
  }) async {
    try {
      final file = File(filePath);
      
      // Create the directory if it doesn't exist
      final directory = path.dirname(filePath);
      await Directory(directory).create(recursive: true);
      
      return await file.writeAsString(content, encoding: encoding, mode: mode);
    } catch (e) {
      _log.severe('Error writing to file: $filePath', e);
      rethrow;
    }
  }

  /// Appends a string to a file.
  ///
  /// [filePath] is the path to the file.
  /// [content] is the string to append.
  /// [encoding] is the encoding to use (defaults to UTF-8).
  ///
  /// Returns the file that was written to.
  /// Throws a [FileSystemException] if the file cannot be written to.
  static Future<File> appendToFile(
    String filePath,
    String content, {
    Encoding encoding = utf8,
  }) {
    return writeFile(
      filePath,
      content,
      encoding: encoding,
      mode: FileMode.append,
    );
  }

  /// Copies a file from one location to another.
  ///
  /// [sourcePath] is the path to the source file.
  /// [destinationPath] is the path to the destination file.
  ///
  /// Returns the new file.
  /// Throws a [FileSystemException] if the file cannot be copied.
  static Future<File> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file not found', sourcePath);
      }
      
      // Create the directory if it doesn't exist
      final directory = path.dirname(destinationPath);
      await Directory(directory).create(recursive: true);
      
      return await sourceFile.copy(destinationPath);
    } catch (e) {
      _log.severe(
        'Error copying file from $sourcePath to $destinationPath',
        e,
      );
      rethrow;
    }
  }

  /// Deletes a file.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns true if the file was deleted successfully.
  /// Throws a [FileSystemException] if the file cannot be deleted.
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      await file.delete();
      return true;
    } catch (e) {
      _log.severe('Error deleting file: $filePath', e);
      rethrow;
    }
  }

  /// Checks if a file exists.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns true if the file exists.
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      _log.warning('Error checking if file exists: $filePath', e);
      return false;
    }
  }

  /// Gets the size of a file in bytes.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the size of the file in bytes.
  /// Throws a [FileSystemException] if the file cannot be accessed.
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }
      
      return await file.length();
    } catch (e) {
      _log.severe('Error getting file size: $filePath', e);
      rethrow;
    }
  }

  /// Gets the extension of a file.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the extension of the file (including the dot).
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Gets the name of a file without the extension.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the name of the file without the extension.
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Gets the name of a file with the extension.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the name of the file with the extension.
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Gets the directory of a file.
  ///
  /// [filePath] is the path to the file.
  ///
  /// Returns the directory of the file.
  static String getDirectory(String filePath) {
    return path.dirname(filePath);
  }

  /// Creates a directory if it doesn't exist.
  ///
  /// [directoryPath] is the path to the directory.
  /// [recursive] is whether to create parent directories if they don't exist.
  ///
  /// Returns the directory that was created.
  /// Throws a [FileSystemException] if the directory cannot be created.
  static Future<Directory> createDirectory(
    String directoryPath, {
    bool recursive = true,
  }) async {
    try {
      return await Directory(directoryPath).create(recursive: recursive);
    } catch (e) {
      _log.severe('Error creating directory: $directoryPath', e);
      rethrow;
    }
  }

  /// Lists the files in a directory.
  ///
  /// [directoryPath] is the path to the directory.
  /// [recursive] is whether to list files in subdirectories.
  /// [followLinks] is whether to follow symbolic links.
  ///
  /// Returns a list of files in the directory.
  /// Throws a [FileSystemException] if the directory cannot be accessed.
  static Future<List<FileSystemEntity>> listFiles(
    String directoryPath, {
    bool recursive = false,
    bool followLinks = false,
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw FileSystemException('Directory not found', directoryPath);
      }
      
      final files = <FileSystemEntity>[];
      await for (final entity in directory.list(
        recursive: recursive,
        followLinks: followLinks,
      )) {
        files.add(entity);
      }
      
      return files;
    } catch (e) {
      _log.severe('Error listing files in directory: $directoryPath', e);
      rethrow;
    }
  }
}
