import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../constants/env.dart';
import '../models/backend.dart';
import '../models/note_list.dart';
import '../store/preference.dart';

Map<String, String> defaultHeader() =>
    {'Content-Type': 'application/json', 'X-User': getUserId()};

final utf8Encoding = Encoding.getByName('utf-8');

T decodeBody<T>(http.Response response) =>
    jsonDecode(utf8.decode(response.bodyBytes)) as T;

Future<List<NoteListItemElement>> loadNoteItemList() async {
  final response = await http.get(EnvironmentVariables.serverUrl + '/notes',
      headers: defaultHeader());
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }

  final json = decodeBody<List<dynamic>>(response);
  return json
      .map((item) => NoteListItemElement(
          noteId: item['noteId'],
          title: item['title'],
          created: DateTime.parse(item['created']),
          modified: DateTime.parse(item['modified'])))
      .toList();
}

Future<NoteListItemElement> addNote(String title) async {
  final noteId = Uuid().v4().toString();
  final response =
      await http.put(EnvironmentVariables.serverUrl + '/note/$noteId',
          headers: defaultHeader(),
          body: jsonEncode({
            "title": title,
          }),
          encoding: utf8Encoding);
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }

  final json = decodeBody<Map<String, dynamic>>(response);
  return NoteListItemElement(
    noteId: json['noteId'],
    title: json['title'],
    created: DateTime.parse(json['created']),
    modified: DateTime.parse(json['created']),
  );
}

Future<bool> deleteNote(String noteId) async {
  final response = await http.delete(
    EnvironmentVariables.serverUrl + '/note/$noteId',
    headers: defaultHeader(),
  );
  return response.statusCode == 200;
}

Future<NoteVO> loadNoteDocument(String noteId) async {
  final response = await http.get(
      EnvironmentVariables.serverUrl + '/note/$noteId',
      headers: defaultHeader());
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }

  final json = decodeBody<dynamic>(response);
  return jsonToNoteVO(json);
}

Future<Map<String, String>> uploadImages(
    String noteId, List<String> fileLocations) async {
  final response = await http.post(
      EnvironmentVariables.serverUrl + '/note/$noteId/uploadImage',
      headers: defaultHeader(),
      body: jsonEncode(fileLocations),
      encoding: utf8Encoding);
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }

  final result = <String, String>{};
  final json = decodeBody<Map<String, dynamic>>(response);
  for (final fileLocation in fileLocations) {
    final info = json[fileLocation];

    final compressed = await FlutterImageCompress.compressWithFile(
      fileLocation,
      minWidth: 512,
      minHeight: 512,
      quality: 90,
    );
    print('Upload an image of ${compressed.length}bytes');
    print('Upload url: ' + info['uploadUrl']);
    print('CDN url: ' + info['cdnUrl']);

    final uploaded = await http.put(info['uploadUrl'], body: compressed);
    if (uploaded.statusCode == 200) {
      result[fileLocation] = info['cdnUrl'];
    } else {
      print('Cannot upload $fileLocation due to ${uploaded.statusCode}');
    }
  }
  return result;
}

Future<String> uploadNoteProfileImage(
    String userId, String noteId, String fileLocation) async {
  final response = await http.post(
      EnvironmentVariables.serverUrl + '/note/$noteId/uploadProfileImage',
      headers: defaultHeader(),
      encoding: utf8Encoding);
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }

  final compressed = await FlutterImageCompress.compressWithFile(
    fileLocation,
    minWidth: 128,
    minHeight: 128,
    quality: 90,
  );

  final info = decodeBody<Map<String, dynamic>>(response);
  print('Upload an image of ${compressed.length}bytes');
  print('Upload url: ' + info['uploadUrl']);
  print('CDN url: ' + info['cdnUrl']);

  final uploaded = await http.put(info['uploadUrl'], body: compressed);
  if (uploaded.statusCode != 200) {
    throw new Exception(
        'Cannot upload $fileLocation due to ${uploaded.statusCode}');
  }
  return info['cdnUrl'];
}

Future<void> requestOperation(String noteId, List<Operation> operations) async {
  final json = operationsToJson(operations);
  final response = await http.post(
      EnvironmentVariables.serverUrl + '/note/$noteId',
      headers: defaultHeader(),
      body: jsonEncode(json),
      encoding: utf8Encoding);
  if (response.statusCode != 200) {
    throw new Exception('Server error ${response.statusCode}');
  }
}

typedef CompletionsCallback = void Function(List<Completion> completions);

class CallbackSocket {
  final String noteId;
  final CompletionsCallback onData;

  bool _active;
  WebSocket _socket;

  CallbackSocket({@required this.noteId, @required this.onData})
      : assert(noteId != null),
        assert(onData != null);

  bool get closed {
    return this._socket == null;
  }

  Future<void> connect() async {
    assert(this._socket == null);
    this._socket =
        await WebSocket.connect(EnvironmentVariables.callbackUrl, headers: {
      'X-User': getUserId(),
      'X-Note': this.noteId,
    });
    this._active = true;
    this._socket.map((value) => jsonDecode(value)).listen((json) {
      this.onData(jsonToCompletions(json as List));
    }, onError: (error) {
      print(error);
      this._clearSocket();
      if (this._active) {
        this.connect();
      }
    }, cancelOnError: true);
  }

  void close() {
    this._active = false;
    this._clearSocket();
  }

  void _clearSocket() {
    if (this._socket != null) {
      try {
        _socket.close();
      } catch (closeError) {
        print('Error occurred while close a socket: $closeError');
      }
      this._socket = null;
    }
  }
}
