import {
  NoteElement,
  NoteElementIndexMap,
  NoteElementMap
} from "../model/note";

type MapEntry = [/* elementId */ string, NoteElement];

const compareMapEntry = (a: MapEntry, b: MapEntry) =>
  (a[1].index || 0) - (b[1].index || 0);

export const getOrderedElementIds = (elementMap: NoteElementMap) =>
  Object.entries(elementMap)
    .sort(compareMapEntry)
    .map(([elementId]) => elementId);

export const reorderElementIds = (
  orderedElementIds: string[],
  maybeElementIdsToMove: string[],
  desireTargetIndex: number
) => {
  const {
    stickyElementIds,
    elementIdsToMove,
    indexToInsert
  } = convertToExclusiveForm(
    orderedElementIds,
    maybeElementIdsToMove,
    desireTargetIndex
  );
  const result = [...stickyElementIds];
  result.splice(indexToInsert, 0, ...elementIdsToMove);
  return result;
};

const convertToExclusiveForm = (
  orderedElementIds: string[],
  maybeElementIdsToMove: string[],
  desireTargetIndex: number
) => {
  const stickyElementIds = orderedElementIds.filter(
    each => !maybeElementIdsToMove.includes(each)
  );
  const elementIdsToMove = maybeElementIdsToMove.filter(each =>
    orderedElementIds.includes(each)
  );
  const countOfElements = orderedElementIds.length;
  let maybeTargetIndex =
    desireTargetIndex === undefined
      ? countOfElements
      : Math.max(0, Math.min(countOfElements, desireTargetIndex));

  if (maybeTargetIndex === countOfElements) {
    return {
      stickyElementIds,
      elementIdsToMove,
      indexToInsert: maybeTargetIndex
    };
  }

  // Find the proper position if a target will be moved.
  let targetMoving = false;
  while (
    maybeTargetIndex >= 0 &&
    elementIdsToMove.includes(orderedElementIds[maybeTargetIndex])
  ) {
    --maybeTargetIndex;
    targetMoving = true;
  }
  // Move to the next of target.
  let indexToInsert = stickyElementIds.indexOf(
    orderedElementIds[maybeTargetIndex]
  );
  if (targetMoving) {
    ++indexToInsert;
  }
  return { stickyElementIds, elementIdsToMove, indexToInsert };
};

export const elementIdsToIndexMap = (
  elementIds: string[]
): NoteElementIndexMap => {
  const indices: NoteElementIndexMap = {};
  for (let index = 0; index < elementIds.length; ++index) {
    indices[elementIds[index]] = index;
  }
  return indices;
};

export const findAndUpdateNewIndices = (
  elementMap: NoteElementMap,
  updatedIndexMap: NoteElementIndexMap
) => {
  const newIndices: NoteElementIndexMap = {};
  for (const [elementId, element] of Object.entries(elementMap)) {
    if (updatedIndexMap[elementId] === undefined) {
      continue;
    }
    if (element.index !== updatedIndexMap[elementId]) {
      newIndices[elementId] = updatedIndexMap[elementId];
      element.index = updatedIndexMap[elementId];
    }
  }
  return newIndices;
};

export const reorderElementMap = (elementMap: NoteElementMap) => {
  const newIndices: NoteElementIndexMap = {};
  let index = 0;
  for (const [elementId, element] of Object.entries(elementMap).sort(
    compareMapEntry
  )) {
    if (element.index !== index) {
      newIndices[elementId] = index;
      element.index = index;
    }
    ++index;
  }
  return newIndices;
};

export const deepCopyElements = (
  source: NoteElementMap,
  dest: NoteElementMap = {},
  filter: (entry: MapEntry) => boolean = () => true
) => {
  const newElements: NoteElementMap = dest;
  for (const entry of Object.entries(source)) {
    if (filter(entry)) {
      newElements[entry[0]] = { ...entry[1] };
    }
  }
  return newElements;
};
