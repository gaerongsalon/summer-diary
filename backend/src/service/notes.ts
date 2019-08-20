import mem from "mem";
import { NoteListItem } from "../model/note";
import { getRepository } from "../system/external";
import logger from "../system/logger";
import { requestToActor } from "./actor";

// TODO Read from the repository of each user.
const globalNotesS3Key = "notes/global";

class NotesService {
  constructor(
    private readonly userId: string,
    private readonly s3Key = globalNotesS3Key
  ) {}

  public async getNotes() {
    logger.info(`getNotes`, this.userId);
    const notes =
      (await getRepository().document.get<NoteListItem[]>(this.s3Key)) || [];
    logger.debug(`notes`, notes);
    return notes.sort((a, b) => b.created.localeCompare(a.created));
  }

  public async addNote(noteId: string, title: string) {
    logger.info(`addNote`, noteId, title, "by", this.userId);
    const now = new Date().toISOString();
    const newNote: NoteListItem = {
      noteId,
      title,
      created: now,
      modified: now
    };
    await requestToActor(this.s3Key, {
      type: "addNote",
      payload: newNote
    });
    return newNote;
  }

  public async deleteNote(noteId: string) {
    logger.info(`deleteNote`, noteId, "by", this.userId);
    await requestToActor(this.s3Key, {
      type: "deleteNote",
      payload: { noteId }
    });
  }
}

export const getNotesService = mem(
  (userId: string) => new NotesService(userId)
);
