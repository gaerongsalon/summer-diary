import { v4 as uuidv4 } from "uuid";
import { NoteElementMap } from "../model/note";
import {
  AddOperation,
  DeleteOperation,
  MoveOperation
} from "../model/operation";
import {
  deepCopyElements,
  elementIdsToIndexMap,
  findAndUpdateNewIndices,
  getOrderedElementIds,
  reorderElementIds,
  reorderElementMap
} from "./noteElement";

export const applyAddOperation = (
  elements: NoteElementMap,
  operation: AddOperation
) => {
  // Step 1. Add all elements into the back of existing elements.
  const elementsToAdd: NoteElementMap = {};
  let index = Object.keys(elements).length;
  for (const element of operation.elements) {
    elementsToAdd[uuidv4()] = { ...element, index: index++ };
  }

  // Even if the `elementId` is overwritten, at least the old ones survive.
  const newElements = deepCopyElements(elements, { ...elementsToAdd });

  // Step 2. Build a new index map from total elements with an index to insert.
  const updatedIndexMap = elementIdsToIndexMap(
    reorderElementIds(
      getOrderedElementIds(newElements),
      Object.keys(elementsToAdd),
      operation.indexToInsert
    )
  );

  // Step 3. Update added elements to have a proper inded.
  for (const newElementId of Object.keys(elementsToAdd)) {
    if (updatedIndexMap[newElementId] === undefined) {
      continue;
    }
    newElements[newElementId].index = updatedIndexMap[newElementId];
  }

  // Step 4. Update elements' index and find differences.
  const newIndices = findAndUpdateNewIndices(newElements, updatedIndexMap);
  return { elementsToAdd, newElements, newIndices };
};

export const applyMoveOperation = (
  elements: NoteElementMap,
  operation: MoveOperation
) => {
  const newElements = deepCopyElements(elements);
  const movedIndices = elementIdsToIndexMap(
    reorderElementIds(
      getOrderedElementIds(newElements),
      operation.elementIds,
      operation.toIndex
    )
  );
  const newIndices = findAndUpdateNewIndices(newElements, movedIndices);
  return { newElements, newIndices };
};

export const applyDeleteOperation = (
  elements: NoteElementMap,
  operation: DeleteOperation
) => {
  const newElements = deepCopyElements(
    elements,
    {},
    ([elementId]) => !operation.elementIds.includes(elementId)
  );
  const newIndices = reorderElementMap(newElements);
  return { newElements, newIndices };
};
