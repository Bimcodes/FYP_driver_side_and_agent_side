// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;

const String outputFileName = 'codebase.txt';
const List<String> directoriesToInclude = ['lib'];
const List<String> fileExtensionsToInclude = ['.dart'];

void main() async {
  final outputFile = File(outputFileName);
  final outputSink = outputFile.openWrite();

  print('Starting to process project...');

  try {
    for (final dirPath in directoriesToInclude) {
      final directory = Directory(p.join(Directory.current.path, dirPath));
      if (await directory.exists()) {
        await processDirectory(directory, outputSink);
      } else {
        print('Warning: Directory "$dirPath" not found. Skipping.');
      }
    }
  } catch (e) {
    print('An error occurred: $e');
  } finally {
    await outputSink.close();
  }

  print('Processing complete. Codebase saved to "$outputFileName".');
  print('Total size: ${outputFile.lengthSync()} bytes');
}

Future<void> processDirectory(Directory dir, IOSink sink) async {
  await for (final fileSystemEntity in dir.list(
    recursive: true,
    followLinks: false,
  )) {
    if (fileSystemEntity is File) {
      if (isIncludedFile(fileSystemEntity.path)) {
        await writeFileContent(fileSystemEntity, sink);
      }
    }
  }
}

bool isIncludedFile(String filePath) {
  for (final ext in fileExtensionsToInclude) {
    if (filePath.endsWith(ext)) {
      return true;
    }
  }
  return false;
}

Future<void> writeFileContent(File file, IOSink sink) async {
  try {
    final content = await file.readAsString();
    sink.write('--- File: ${file.path} ---\n\n');
    sink.write(content);
    sink.write('\n\n--- End of File: ${file.path} ---\n\n');
    print('✅ Added: ${file.path}');
  } catch (e) {
    print('❌ Failed to read file: ${file.path}. Error: $e');
  }
}
