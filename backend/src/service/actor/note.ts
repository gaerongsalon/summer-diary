import {
  AddCompletion,
  ChangeProfileCompletion,
  Completion,
  DeleteCompletion,
  MoveCompletion
} from "../../model/completion";
import { Note, NoteElementIndexMap } from "../../model/note";
import {
  AddOperation,
  ChangeProfileOperation,
  DeleteOperation,
  MoveOperation,
  Operation
} from "../../model/operation";
import { getRepository, getSocketResponder } from "../../system/external";
import logger from "../../system/logger";
import {
  applyAddOperation,
  applyDeleteOperation,
  applyMoveOperation
} from "../../utils/operationApplier";
import { valueOf } from "../../utils/typeGuard";
import { ActorMessage } from "./message";

export class NoteProcessor {
  private note: Note | undefined;

  constructor(private readonly s3Key: string) {}

  public onBeforeAct = async () => {
    this.note = await getRepository().document.get<Note>(this.s3Key);
  };

  public onAfterAct = async () => {
    if (this.note) {
      await getRepository().document.set(this.s3Key, this.note);
    } else {
      await getRepository().document.delete(this.s3Key);
    }
  };

  public onAct = async ({ message }: { message: ActorMessage }) => {
    switch (message.type) {
      case "addNote":
        this.note = {
          ...message.payload,
          profiles: {},
          elements: {}
        };
        break;
      case "deleteNote":
        // It will be erased at `onAfterAct`.
        this.note = undefined;
        break;
      case "applyOperations":
        await this.onApplyOperations(message.payload);
        break;
      default:
        logger.error(`Unknown message for NoteActor`, message);
        break;
    }
  };

  private async onApplyOperations(operations: Operation[]) {
    if (!this.note) {
      throw new Error(`No document[${this.s3Key}]`);
    }
    const completions = operations
      .map(operation => this.onApplyOperation(operation))
      .reduce((a, b) => a.concat(b), []);
    logger.info(`completions`, completions);
    await getSocketResponder()(this.note.noteId, completions);
  }

  private onApplyOperation(operation: Operation): Completion[] {
    if (!this.note) {
      throw new Error(`No document[${this.s3Key}]`);
    }
    switch (operation._type) {
      case "add":
        return this.onApplyToAddElements(operation);
      case "move":
        return this.onApplyToMoveElements(operation);
      case "delete":
        return this.onApplyToDeleteElements(operation);
      case "changeProfile":
        return this.onApplyToChangeProfile(operation);
    }
    return [];
  }

  private onApplyToAddElements(operation: AddOperation) {
    const { elementsToAdd, newElements, newIndices } = applyAddOperation(
      this.note!.elements,
      operation
    );
    this.note!.elements = newElements;
    return withMaybeMoved(
      [
        valueOf<AddCompletion>({
          _type: "add",
          elements: elementsToAdd,
          modified: now()
        })
      ],
      newIndices
    );
  }

  private onApplyToMoveElements(operation: MoveOperation) {
    const { newElements, newIndices } = applyMoveOperation(
      this.note!.elements,
      operation
    );
    this.note!.elements = newElements;
    return withMaybeMoved([], newIndices);
  }

  private onApplyToDeleteElements(operation: DeleteOperation) {
    const { newElements, newIndices } = applyDeleteOperation(
      this.note!.elements,
      operation
    );
    this.note!.elements = newElements;
    return withMaybeMoved(
      [
        valueOf<DeleteCompletion>({
          _type: "delete",
          modified: now(),
          elementIds: operation.elementIds
        })
      ],
      newIndices
    );
  }

  private onApplyToChangeProfile(operation: ChangeProfileOperation) {
    const profile = {
      name: operation.name,
      imageUrl: operation.imageUrl
    };
    this.note!.profiles[operation.userId] = profile;
    return [
      valueOf<ChangeProfileCompletion>({
        _type: "changeProfile",
        modified: now(),
        profiles: { [operation.userId]: profile }
      })
    ];
  }
}

const now = () => new Date().toISOString();

const withMaybeMoved = (
  completions: Completion[],
  newIndices: NoteElementIndexMap
) => {
  if (Object.keys(newIndices).length > 0) {
    completions.push(
      valueOf<MoveCompletion>({ _type: "move", newIndices, modified: now() })
    );
  }
  return completions;
};
