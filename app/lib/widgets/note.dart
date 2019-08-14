import 'package:flutter/widgets.dart';

import '../models/note.dart';
import 'note/note_padding.dart';
import 'note/note_text.dart';
import 'note/note_image.dart';
import 'note/note_chat.dart';

Widget buildNoteElementWidget(BuildContext context, NoteElement element) {
  if (element is NoteImageElement) {
    return NoteImage(element: element);
  } else if (element is NoteTextElement) {
    return NoteText(element: element);
  } else if (element is NotePaddingElement) {
    return NotePadding(element: element);
  } else if (element is NoteChatElement) {
    return NoteChat(element: element);
  }
  return Container();
}
