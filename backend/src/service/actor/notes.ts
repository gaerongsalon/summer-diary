import { NoteListItem } from "../../model/note";
import { getRepository } from "../../system/external";
import logger from "../../system/logger";
import { ActorMessage } from "./message";

export class NotesProcessor {
  private items: NoteListItem[] = [];

  constructor(private readonly s3Key: string) {}

  public onBeforeAct = async () => {
    this.items =
      (await getRepository().document.get<NoteListItem[]>(this.s3Key)) || [];
  };

  public onAfterAct = async () => {
    await getRepository().document.set(this.s3Key, this.items);
  };

  public onAct = ({ message }: { message: ActorMessage }) => {
    switch (message.type) {
      case "addNote":
        this.items.push(message.payload);
        break;
      case "deleteNote":
        this.items = this.items.filter(
          each => each.noteId !== message.payload.noteId
        );
        break;
      default:
        logger.error(`Unknown message for NotesActor`, message);
        break;
    }
  };
}
