export interface NoteListItem {
  noteId: string;
  title: string;
  created: string;
  modified: string;
}

export interface Note {
  noteId: string;
  title: string;
  profiles: NoteProfileMap;
  elements: NoteElementMap;
  created: string;
  modified: string;
}

export interface NoteProfile {
  name: string;
  imageUrl: string;
}

export interface NoteElement {
  _type: string;
  index: number;
}

export interface NotePadding extends NoteElement {
  _type: "padding";
  height: number;
}

export interface NoteImage extends NoteElement {
  _type: "image";
  url: string;
}

export interface NoteText extends NoteElement {
  _type: "text";
  text: string;
  level: number;
}

export interface NoteChat extends NoteElement {
  _type: "chat";
  userId: string;
  text: string;
  level: number;
}

export interface NoteElementIndexMap {
  [elementId: string]: number;
}

export interface NoteElementMap {
  [elementId: string]: NoteElement;
}

export interface NoteProfileMap {
  [userId: string]: NoteProfile;
}
