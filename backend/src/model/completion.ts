import { NoteElementIndexMap, NoteElementMap, NoteProfileMap } from "./note";

export interface Completion {
  modified: string;
}

export interface AddCompletion extends Completion {
  elements: NoteElementMap;
}

export interface MoveCompletion extends Completion {
  newIndices: NoteElementIndexMap;
}

export interface DeleteCompletion extends Completion {
  elementIds: string[];
}

export interface ChangeProfileCompletion extends Completion {
  profiles: NoteProfileMap;
}
