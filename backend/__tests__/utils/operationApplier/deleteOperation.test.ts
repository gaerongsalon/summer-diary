import { applyDeleteOperation } from "../../../src/utils/operationApplier";
import { TestSet } from "./utils";

test("delete-nothing", () => {
  const t = new TestSet(10);
  const result = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id()
  });
  expect(result.newElements).toEqual(t.elements);
  expect(result.newIndices).toEqual({});
});

test("delete-one", () => {
  const t = new TestSet(10);

  // First one
  const first = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(0)
  });
  expect(first.newElements).toEqual(t.expectedDeleted(0));
  expect(first.newIndices).toEqual(
    t.expectedMovedIndices({
      1: 0,
      2: 1,
      3: 2,
      4: 3,
      5: 4,
      6: 5,
      7: 6,
      8: 7,
      9: 8
    })
  );

  // Middle one
  const middle = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(5)
  });
  expect(middle.newElements).toEqual(t.expectedDeleted(5));
  expect(middle.newIndices).toEqual(
    t.expectedMovedIndices({ 6: 5, 7: 6, 8: 7, 9: 8 })
  );

  // Last one
  const last = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(9)
  });
  expect(last.newElements).toEqual(t.expectedDeleted(9));
  expect(last.newIndices).toEqual({});
});

test("delete-many", () => {
  const t = new TestSet(10);
  const case1 = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(0, 2, 4, 6, 8)
  });
  expect(case1.newElements).toEqual(t.expectedDeleted(0, 2, 4, 6, 8));
  expect(case1.newIndices).toEqual(
    t.expectedMovedIndices({ 1: 0, 3: 1, 5: 2, 7: 3, 9: 4 })
  );

  const case2 = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(1, 3, 5, 7, 9)
  });
  expect(case2.newElements).toEqual(t.expectedDeleted(1, 3, 5, 7, 9));
  expect(case2.newIndices).toEqual(
    t.expectedMovedIndices({ 2: 1, 4: 2, 6: 3, 8: 4 })
  );
});

test("delete-all", () => {
  const t = new TestSet(10);
  const result = applyDeleteOperation(t.elements, {
    _type: "delete",
    elementIds: t.id(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  });
  expect(result.newElements).toEqual({});
  expect(result.newIndices).toEqual({});
});
