import { v4 as uuidv4 } from "uuid";
import {
  NoteElementIndexMap,
  NoteElementMap,
  NoteText
} from "../../../src/model/note";

export const newText = (value: string, index: number): NoteText => ({
  _type: "text",
  index,
  text: value,
  level: 15
});

export class TestSet {
  public readonly elements: NoteElementMap;
  private readonly values: Array<{ id: string; text: NoteText }>;

  constructor(count: number = 10) {
    this.values = Array(count)
      .fill(0)
      .map((_, index) => ({
        id: uuidv4(),
        text: newText(index.toString(), index)
      }));
    this.elements = this.values.reduce(
      (map, el) => Object.assign(map, { [el.id]: el.text }),
      {} as NoteElementMap
    );
  }
  public id(...indices: number[]) {
    return (indices || []).map(index => this.values[index].id);
  }

  public expectedMovedIndices(answer: { [id: number]: number }) {
    return Object.entries(answer)
      .map(([idIndex, index]) => [this.values[+idIndex].id, index])
      .reduce(
        (map, [id, index]) => Object.assign(map, { [id]: index }),
        {} as NoteElementIndexMap
      );
  }

  public expectedMoved(answer: { [id: number]: number }) {
    const moved: NoteElementMap = {};
    this.values.forEach(({ id, text }, index) => {
      moved[id] = {
        ...text,
        index: answer[index] !== undefined ? answer[index] : text.index
      };
    });
    return moved;
  }

  public expectedDeleted(...deletedIndices: number[]) {
    const deleted: NoteElementMap = {};
    let newIndex = 0;
    this.values.forEach(({ id, text }, index) => {
      if ((deletedIndices || []).includes(index)) {
        return;
      }
      const reindexed = { ...text, index: newIndex++ };
      deleted[id] = reindexed;
    });
    return deleted;
  }
}
