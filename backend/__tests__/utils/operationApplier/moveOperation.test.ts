import { applyMoveOperation } from "../../../src/utils/operationApplier";
import { TestSet } from "./utils";

const check = (
  t: TestSet,
  result: ReturnType<typeof applyMoveOperation>,
  answer: { [id: number]: number }
) => {
  expect(result.newElements).toEqual(t.expectedMoved(answer));
  expect(result.newIndices).toEqual(t.expectedMovedIndices(answer));
};

test("no-move", () => {
  const t = new TestSet(10);
  const result = applyMoveOperation(t.elements, {
    _type: "move",
    elementIds: t.id(0, 1),
    toIndex: 0
  });
  check(t, result, {});
});

test("move-to-first", () => {
  const t = new TestSet(10);
  const result = applyMoveOperation(t.elements, {
    _type: "move",
    elementIds: t.id(3, 5),
    toIndex: 0
  });
  check(t, result, { 0: 2, 1: 3, 2: 4, 4: 5, 3: 0, 5: 1 });
});

test("move-to-end", () => {
  const t = new TestSet(10);
  const result = applyMoveOperation(t.elements, {
    _type: "move",
    elementIds: t.id(6, 8),
    toIndex: 10
  });
  check(t, result, { 7: 6, 9: 7, 6: 8, 8: 9 });
});

test("move-to-anywhere-exclusive", () => {
  const t = new TestSet(10);
  const result = applyMoveOperation(t.elements, {
    _type: "move",
    elementIds: t.id(1, 3, 5),
    toIndex: 4
  });
  check(t, result, { 2: 1, 1: 2, 5: 4, 4: 5 });
});

test("move-to-anywhere-inclusive", () => {
  const t = new TestSet(10);
  const result = applyMoveOperation(t.elements, {
    _type: "move",
    elementIds: t.id(1, 3, 5),
    toIndex: 3
  });
  check(t, result, { 2: 1, 1: 2, 5: 4, 4: 5 });
});
