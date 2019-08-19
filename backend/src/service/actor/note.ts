import { v4 as uuidv4 } from "uuid";
import {
  AddCompletion,
  ChangeProfileCompletion,
  Completion,
  DeleteCompletion,
  MoveCompletion
} from "../../model/completion";
import { Note, NoteElementIndexMap, NoteElementMap } from "../../model/note";
import {
  AddOperation,
  ChangeProfileOperation,
  DeleteOperation,
  MoveOperation,
  Operation
} from "../../model/operation";
import { getRepository, getSocketResponder } from "../../system/external";
import logger from "../../system/logger";
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
      case "joinUserToNote":
        if (!this.note) {
          throw new Error(`No document[${this.s3Key}]`);
        }
        this.note.profiles[message.payload.userId] = {
          ...message.payload.profile
        };
        break;
      case "deleteNote":
        // It will be erased at `onAfterAct`.
        this.note = undefined;
        break;
      case "applyOperations":
        if (!this.note) {
          throw new Error(`No document[${this.s3Key}]`);
        }
        await getSocketResponder()(
          this.note.noteId,
          message.payload
            .map(operation => this.onApplyOperation(operation))
            .reduce((a, b) => a.concat(b), [])
        );
        break;
      default:
        logger.error(`Unknown message for NoteActor`, message);
        break;
    }
  };

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
    const newIndices: NoteElementIndexMap = {};
    for (const [elementId, element] of Object.entries(this.note!.elements)) {
      if (element.index >= operation.indexToInsert) {
        element.index += operation.elements.length;
        newIndices[elementId] = element.index;
      }
    }
    const newElements: NoteElementMap = {};
    let index = operation.indexToInsert;
    for (const element of operation.elements) {
      element.index = index++;
      newElements[uuidv4()] = element;
    }
    this.note!.elements = { ...this.note!.elements, ...newElements };
    const now = new Date().toISOString();
    return [
      valueOf<AddCompletion>({ elements: newElements, modified: now }),
      valueOf<MoveCompletion>({ newIndices, modified: now })
    ];
  }

  private onApplyToMoveElements(operation: MoveOperation) {
    const orderedElementIds = Object.entries(this.note!.elements)
      .sort((a, b) => a[1].index - b[1].index)
      .map(([elementId]) => elementId);
    const movedElementIds = reorderElementIds(operation, orderedElementIds);
    const indices: NoteElementIndexMap = {};
    for (let index = 0; index < movedElementIds.length; ++index) {
      indices[movedElementIds[index]] = index;
    }
    const newIndices: NoteElementIndexMap = {};
    for (const [elementId, element] of Object.entries(this.note!.elements)) {
      if (element.index !== indices[elementId]) {
        newIndices[elementId] = indices[elementId];
      }
      element.index = indices[elementId];
    }
    const now = new Date().toISOString();
    return [valueOf<MoveCompletion>({ modified: now, newIndices })];
  }

  private onApplyToDeleteElements(operation: DeleteOperation) {
    const now = new Date().toISOString();
    for (const elementId of operation.elementIds) {
      delete this.note!.elements[elementId];
    }
    return [
      valueOf<DeleteCompletion>({
        modified: now,
        elementIds: operation.elementIds
      })
    ];
  }

  private onApplyToChangeProfile(operation: ChangeProfileOperation) {
    const now = new Date().toISOString();
    const profile = {
      name: operation.name,
      imageUrl: operation.imageUrl
    };
    this.note!.profiles[operation.userId] = profile;
    return [
      valueOf<ChangeProfileCompletion>({
        modified: now,
        profiles: { [operation.userId]: profile }
      })
    ];
  }
}

const reorderElementIds = (
  operation: MoveOperation,
  orderedElementIds: string[]
) => {
  let toIndex = operation.toIndex;
  const stickyElementIds = orderedElementIds.filter(
    each => !operation.elementIds.includes(each)
  );
  const elementIdsToMove = orderedElementIds.filter(
    each => !operation.elementIds.includes(each)
  );
  if (!orderedElementIds[toIndex]) {
    // Move to end.
    return [...stickyElementIds, ...elementIdsToMove];
  } else {
    while (
      toIndex >= 0 &&
      operation.elementIds.includes(orderedElementIds[toIndex])
    ) {
      --toIndex;
    }
    if (toIndex < 0) {
      // Move to first
      return [...elementIdsToMove, ...stickyElementIds];
    } else {
      // Move to the next of target.
      const toElementId = orderedElementIds[toIndex];
      const indexToInsert = stickyElementIds.indexOf(toElementId);
      return [
        ...stickyElementIds.slice(0, indexToInsert),
        ...elementIdsToMove,
        ...stickyElementIds.slice(indexToInsert)
      ];
    }
  }
};
