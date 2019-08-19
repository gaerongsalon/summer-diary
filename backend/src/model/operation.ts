import { NoteElement } from "./note";

export interface AddOperation {
  _type: "add";
  indexToInsert: number;
  elements: NoteElement[];
}

export interface MoveOperation {
  _type: "move";
  toIndex: number;
  elementIds: string[];
}

export interface DeleteOperation {
  _type: "delete";
  elementIds: string[];
}

export interface ChangeProfileOperation {
  _type: "changeProfile";
  userId: string;
  name: string;
  imageUrl: string;
}

export type Operation =
  | AddOperation
  | MoveOperation
  | DeleteOperation
  | ChangeProfileOperation;
