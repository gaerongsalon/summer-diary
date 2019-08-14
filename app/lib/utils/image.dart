import 'dart:io';
import 'dart:typed_data';

Uint8List loadImageBytes(String sourcePath) {
  final watch = Stopwatch()..start();

  ////////// Original
  final imageBytes = Uint8List.fromList(File(sourcePath).readAsBytesSync());

  print('Took ${watch.elapsedMilliseconds} ms');
  return imageBytes;
}
