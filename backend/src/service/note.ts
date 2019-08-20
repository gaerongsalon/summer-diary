import mem from "mem";
import { Note, NoteListItem } from "../model/note";
import { Operation } from "../model/operation";
import { getRepository } from "../system/external";
import logger from "../system/logger";
import { requestToActor } from "./actor";

class NoteService {
  private readonly s3Key: string;
  constructor(private readonly noteId: string) {
    this.s3Key = `note/${noteId}`;
  }

  public async getNote(userId: string) {
    logger.info(`getNote`, this.noteId, userId, this.s3Key);
    const note = await getRepository().document.get<Note>(this.s3Key);
    logger.debug(`note`, this.noteId, note);
    return note;
  }

  public async addNote(note: NoteListItem, userId: string) {
    logger.info(`addNote`, this.s3Key, note, userId);
    await requestToActor(this.s3Key, {
      type: "addNote",
      payload: note
    });
  }

  public async deleteNote(userId: string) {
    logger.info(`deleteNote`, this.noteId, "by", userId);
    await requestToActor(this.s3Key, {
      type: "deleteNote",
      payload: { noteId: this.noteId }
    });
  }

  public async applyOperations(userId: string, operations: Operation[]) {
    logger.info(`applyOperations`, userId, operations);
    await requestToActor(this.s3Key, {
      type: "applyOperations",
      payload: operations
    });
  }
}

export const getNoteService = mem((noteId: string) => new NoteService(noteId));
