import {
  elementIdsToIndexMap,
  findAndUpdateNewIndices,
  getOrderedElementIds,
  reorderElementIds,
  reorderElementMap
} from "../../src/utils/noteElement";

test("getOrderedElementIds", () => {
  expect(getOrderedElementIds({})).toEqual([]);
  expect(
    getOrderedElementIds({
      test3: { _type: "unknown", index: 2 },
      test1: { _type: "unknown", index: 0 },
      test4: { _type: "unknown", index: 3 },
      test2: { _type: "unknown", index: 1 }
    })
  ).toEqual(["test1", "test2", "test3", "test4"]);
});

type FromTo = [number, number];
const range = (from: number, to: number) =>
  Array(to - from + 1)
    .fill(0)
    .map((_, index) => (from + index).toString());
const ranges = (...tuples: FromTo[]) =>
  tuples.reduce(
    (acc, [from, to]) => acc.concat(range(from, to)),
    [] as string[]
  );
const str = (...values: number[]) => values.map(each => each.toString());

test("reorderElementIds-moveToFirst", () => {
  expect(reorderElementIds([], [], 0)).toEqual([]);

  // Exclusive
  expect(reorderElementIds(ranges([5, 10], [1, 4]), range(1, 4), 0)).toEqual(
    range(1, 10)
  );
  expect(
    reorderElementIds(ranges([5, 7], [1, 4], [8, 10]), range(1, 4), 0)
  ).toEqual(range(1, 10));
  expect(
    reorderElementIds(ranges([2, 7], [1, 1], [8, 10]), range(1, 1), 0)
  ).toEqual(range(1, 10));
  expect(
    reorderElementIds(ranges([3, 7], [1, 2], [8, 10]), range(1, 2), 0)
  ).toEqual(range(1, 10));

  // Inclusive
  expect(reorderElementIds(range(1, 10), range(1, 10), 0)).toEqual(
    range(1, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 0)).toEqual(
    str(1, 3, 5, 7, 9, 2, 4, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), range(1, 5), 0)).toEqual(range(1, 10));
});

test("reorderElementIds-moveToEnd", () => {
  expect(reorderElementIds([], [], 1)).toEqual([]);

  // Exclusive
  expect(reorderElementIds(ranges([5, 10], [1, 4]), range(5, 10), 10)).toEqual(
    range(1, 10)
  );
  expect(reorderElementIds(ranges([9, 10], [1, 8]), range(9, 10), 10)).toEqual(
    range(1, 10)
  );
  expect(
    reorderElementIds(ranges([10, 10], [1, 9]), range(10, 10), 10)
  ).toEqual(range(1, 10));

  // Inclusive
  expect(reorderElementIds(range(1, 10), range(1, 10), 10)).toEqual(
    range(1, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 10)).toEqual(
    str(2, 4, 6, 8, 10, 1, 3, 5, 7, 9)
  );
  expect(reorderElementIds(range(1, 10), range(6, 10), 10)).toEqual(
    range(1, 10)
  );
});

test("reorderElementIds-moveToTarget", () => {
  // Exclusive
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 1)).toEqual(
    str(1, 3, 5, 7, 9, 2, 4, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 3)).toEqual(
    str(2, 1, 3, 5, 7, 9, 4, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 5)).toEqual(
    str(2, 4, 1, 3, 5, 7, 9, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 7)).toEqual(
    str(2, 4, 6, 1, 3, 5, 7, 9, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 9)).toEqual(
    str(2, 4, 6, 8, 1, 3, 5, 7, 9, 10)
  );
  // Inclusive
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 2)).toEqual(
    str(2, 1, 3, 5, 7, 9, 4, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 4)).toEqual(
    str(2, 4, 1, 3, 5, 7, 9, 6, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 6)).toEqual(
    str(2, 4, 6, 1, 3, 5, 7, 9, 8, 10)
  );
  expect(reorderElementIds(range(1, 10), str(1, 3, 5, 7, 9), 8)).toEqual(
    str(2, 4, 6, 8, 1, 3, 5, 7, 9, 10)
  );
});

test("elementIdsToIndexMap", () => {
  expect(elementIdsToIndexMap([])).toEqual({});
  expect(elementIdsToIndexMap(["test1", "test2", "test3", "test4"])).toEqual({
    test1: 0,
    test2: 1,
    test3: 2,
    test4: 3
  });
});

test("findAndUpdateNewIndices", () => {
  // Fix all things
  const case1 = {
    test4: { _type: "unknown", index: 7 },
    test2: { _type: "unknown", index: 3 },
    test1: { _type: "unknown", index: undefined as any },
    test3: { _type: "unknown", index: 5 }
  };
  expect(
    findAndUpdateNewIndices(case1, { test1: 0, test2: 1, test3: 2, test4: 3 })
  ).toEqual({ test1: 0, test2: 1, test3: 2, test4: 3 });
  expect(case1).toEqual({
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  });

  // There is nothing to fix
  const case2 = {
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  };
  expect(
    findAndUpdateNewIndices(case2, { test1: 0, test2: 1, test3: 2, test4: 3 })
  ).toEqual({});
  expect(case2).toEqual({
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  });

  // There is no patch.
  const case3 = {
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  };
  expect(findAndUpdateNewIndices(case2, {})).toEqual({});
  expect(case3).toEqual({
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  });

  // There is something to change.
  const case4 = {
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 2 },
    test3: { _type: "unknown", index: 1 },
    test4: { _type: "unknown", index: 3 }
  };
  expect(
    findAndUpdateNewIndices(case4, { test1: 0, test2: 1, test3: 2 })
  ).toEqual({ test2: 1, test3: 2 });
  expect(case4).toEqual({
    test1: { _type: "unknown", index: 0 },
    test2: { _type: "unknown", index: 1 },
    test3: { _type: "unknown", index: 2 },
    test4: { _type: "unknown", index: 3 }
  });
});

test("reorderElementMap", () => {
  expect(reorderElementMap({})).toEqual({});
  expect(
    reorderElementMap({
      test4: { _type: "unknown", index: 7 },
      test2: { _type: "unknown", index: 3 },
      test1: { _type: "unknown", index: undefined as any },
      test3: { _type: "unknown", index: 5 }
    })
  ).toEqual({ test1: 0, test2: 1, test3: 2, test4: 3 });
});
