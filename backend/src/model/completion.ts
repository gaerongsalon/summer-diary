import { NoteElementIndexMap, NoteElementMap, NoteProfileMap } from "./note";

export interface Completion {
  modified: string;
}

export interface AddCompletion extends Completion {
  _type: "add";
  elements: NoteElementMap;
}

export interface MoveCompletion extends Completion {
  _type: "move";
  newIndices: NoteElementIndexMap;
}

export interface DeleteCompletion extends Completion {
  _type: "delete";
  elementIds: string[];
}

export interface ChangeProfileCompletion extends Completion {
  _type: "changeProfile";
  profiles: NoteProfileMap;
}
