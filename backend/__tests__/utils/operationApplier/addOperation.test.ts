import { v4 as uuidv4 } from "uuid";
import { NoteText } from "../../../src/model/note";
import { applyAddOperation } from "../../../src/utils/operationApplier";
import { newText } from "./utils";

test("pushfront-1", () => {
  const id1 = uuidv4();
  const text1 = newText("one", 0);
  const text2 = newText("zero", 0);

  const result = applyAddOperation(
    {
      [id1]: text1
    },
    {
      _type: "add",
      indexToInsert: 0,
      elements: [text2]
    }
  );
  const id2 = Object.keys(result.elementsToAdd)[0];
  expect(Object.keys(result.elementsToAdd).length).toBe(1);
  expect(id1).not.toEqual(id2);

  expect(Object.keys(result.newIndices).length).toBe(1);
  expect(result.newIndices[id1]).toBe(1);

  expect((result.newElements[id1] as NoteText).index).toBe(1);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(0);
  expect((result.newElements[id2] as NoteText).text).toEqual("zero");
});

test("pushfront-2", () => {
  const id1 = uuidv4();
  const id2 = uuidv4();
  const text1 = newText("one", 0);
  const text2 = newText("two", 1);
  const text3 = newText("three", 0);

  const result = applyAddOperation(
    {
      [id1]: text1,
      [id2]: text2
    },
    {
      _type: "add",
      indexToInsert: 0,
      elements: [text3]
    }
  );

  const id3 = Object.keys(result.elementsToAdd)[0];
  expect(Object.keys(result.elementsToAdd).length).toBe(1);
  expect(id1).not.toEqual(id3);
  expect(id2).not.toEqual(id3);

  expect(Object.keys(result.newIndices).length).toBe(2);
  expect(result.newIndices[id1]).toBe(1);
  expect(result.newIndices[id2]).toBe(2);

  expect((result.newElements[id1] as NoteText).index).toBe(1);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(2);
  expect((result.newElements[id2] as NoteText).text).toEqual("two");

  expect((result.newElements[id3] as NoteText).index).toBe(0);
  expect((result.newElements[id3] as NoteText).text).toEqual("three");
});

test("pushback-1", () => {
  const id1 = uuidv4();
  const text1 = newText("one", 0);
  const text2 = newText("two", 0);

  const result = applyAddOperation(
    {
      [id1]: text1
    },
    {
      _type: "add",
      indexToInsert: 1,
      elements: [text2]
    }
  );
  const id2 = Object.keys(result.elementsToAdd)[0];
  expect(Object.keys(result.elementsToAdd).length).toBe(1);
  expect(id1).not.toEqual(id2);

  expect(result.newIndices).toEqual({});

  expect((result.newElements[id1] as NoteText).index).toBe(0);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(1);
  expect((result.newElements[id2] as NoteText).text).toEqual("two");
});

test("pushback-2", () => {
  const id1 = uuidv4();
  const id2 = uuidv4();
  const text1 = newText("one", 0);
  const text2 = newText("two", 1);
  const text3 = newText("three", 0);

  const result = applyAddOperation(
    {
      [id1]: text1,
      [id2]: text2
    },
    {
      _type: "add",
      indexToInsert: 2,
      elements: [text3]
    }
  );

  const id3 = Object.keys(result.elementsToAdd)[0];
  expect(Object.keys(result.elementsToAdd).length).toBe(1);
  expect(id1).not.toEqual(id3);
  expect(id2).not.toEqual(id3);

  expect(result.newIndices).toEqual({});

  expect((result.newElements[id1] as NoteText).index).toBe(0);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(1);
  expect((result.newElements[id2] as NoteText).text).toEqual("two");

  expect((result.newElements[id3] as NoteText).index).toBe(2);
  expect((result.newElements[id3] as NoteText).text).toEqual("three");
});

test("insert-2", () => {
  const id1 = uuidv4();
  const id3 = uuidv4();
  const text1 = newText("one", 0);
  const text3 = newText("three", 1);
  const text2 = newText("two", 0);

  const result = applyAddOperation(
    {
      [id1]: text1,
      [id3]: text3
    },
    {
      _type: "add",
      indexToInsert: 1,
      elements: [text2]
    }
  );

  const id2 = Object.keys(result.elementsToAdd)[0];
  expect(Object.keys(result.elementsToAdd).length).toBe(1);
  expect(id1).not.toEqual(id2);
  expect(id3).not.toEqual(id2);

  expect(result.newIndices).toEqual({ [id3]: 2 });

  expect((result.newElements[id1] as NoteText).index).toBe(0);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(1);
  expect((result.newElements[id2] as NoteText).text).toEqual("two");

  expect((result.newElements[id3] as NoteText).index).toBe(2);
  expect((result.newElements[id3] as NoteText).text).toEqual("three");
});

test("insert-many", () => {
  const id1 = uuidv4();
  const id4 = uuidv4();
  const text1 = newText("one", 0);
  const text4 = newText("four", 1);
  const text2 = newText("two", 0);
  const text3 = newText("three", 0);

  const result = applyAddOperation(
    {
      [id1]: text1,
      [id4]: text4
    },
    {
      _type: "add",
      indexToInsert: 1,
      elements: [text2, text3]
    }
  );

  const id2 = Object.entries(result.elementsToAdd).find(
    each => each[1].index === 1
  )![0];
  const id3 = Object.entries(result.elementsToAdd).find(
    each => each[1].index === 2
  )![0];
  expect(result.elementsToAdd).toEqual({
    [id2]: { ...text2, index: 1 },
    [id3]: { ...text3, index: 2 }
  });

  expect(result.newIndices).toEqual({ [id4]: 3 });

  expect((result.newElements[id1] as NoteText).index).toBe(0);
  expect((result.newElements[id1] as NoteText).text).toEqual("one");

  expect((result.newElements[id2] as NoteText).index).toBe(1);
  expect((result.newElements[id2] as NoteText).text).toEqual("two");

  expect((result.newElements[id3] as NoteText).index).toBe(2);
  expect((result.newElements[id3] as NoteText).text).toEqual("three");

  expect((result.newElements[id4] as NoteText).index).toBe(3);
  expect((result.newElements[id4] as NoteText).text).toEqual("four");
});
