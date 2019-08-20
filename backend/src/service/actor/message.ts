import { NoteListItem } from "../../model/note";
import { Operation } from "../../model/operation";

export interface AddNote {
  type: "addNote";
  payload: NoteListItem;
}

export interface DeleteNote {
  type: "deleteNote";
  payload: {
    noteId: string;
  };
}

export interface ApplyOperations {
  type: "applyOperations";
  payload: Operation[];
}

export type ActorMessage = AddNote | DeleteNote | ApplyOperations;
