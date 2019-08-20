import { APIGatewayProxyEvent, APIGatewayProxyHandler } from "aws-lambda";
import { AddNoteRequest, JoinNoteRequest } from "../model/handler";
import { Operation } from "../model/operation";
import { getNoteService, getNotesService } from "../service";
import { getS3ImageUploader } from "../system/external";
import logger from "../system/logger";

const parseRequest = (event: APIGatewayProxyEvent) => {
  const noteId = (event.pathParameters || {}).noteId;
  if (!noteId) {
    throw new Error("Not Found");
  }
  const userId = event.headers["x-user"];
  if (!userId) {
    throw new Error("Unauthorized");
  }
  return { noteId, userId };
};

export const put: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const body = JSON.parse(event.body || "{}") as AddNoteRequest;
  if (!body || !body.title) {
    logger.error(`Invalid request`, noteId, userId, event.body);
    throw new Error("Not Found");
  }

  const note = await getNotesService(userId).addNote(noteId, body.title);
  await getNoteService(noteId).addNote(note, userId);
  return { statusCode: 200, body: JSON.stringify(note) };
};

export const join: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const body = JSON.parse(event.body || "{}") as JoinNoteRequest;
  if (!body || !body.name || !body.imageUrl) {
    logger.error(`Invalid request`, noteId, userId, event.body);
    throw new Error("Not Found");
  }

  await getNoteService(noteId).joinUser(userId, body.name, body.imageUrl);
  return { statusCode: 200, body: JSON.stringify(true) };
};

export const purge: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  await Promise.all([
    getNotesService(userId).deleteNote(noteId),
    getNoteService(noteId).deleteNote(userId)
  ]);
  return { statusCode: 200, body: JSON.stringify(true) };
};

export const get: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const note = await getNoteService(noteId).getNote(userId);
  return { statusCode: 200, body: JSON.stringify(note) };
};

export const uploadImage: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const uploader = getS3ImageUploader();
  const fileLocations = JSON.parse(event.body || "[]") as string[];
  logger.info(`uploadImage`, noteId, userId, fileLocations);

  if (!fileLocations || !fileLocations.length) {
    return { statusCode: 200, body: "{}" };
  }

  const result = fileLocations.reduce(
    (acc, each) => Object.assign(acc, { [each]: uploader(noteId, "jpg") }),
    {} as { [fileLocation: string]: ReturnType<typeof uploader> }
  );
  logger.info(`uploadImage`, noteId, userId, result);
  return { statusCode: 200, body: JSON.stringify(result) };
};

export const uploadProfileImage: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const result = getS3ImageUploader()(noteId, "jpg");
  logger.info(`uploadProfileImage`, noteId, userId, result);
  return { statusCode: 200, body: JSON.stringify(result) };
};

export const patch: APIGatewayProxyHandler = async event => {
  const { noteId, userId } = parseRequest(event);
  const operations = JSON.parse(event.body || "[]") as Operation[];
  await getNoteService(noteId).applyOperations(userId, operations);
  return { statusCode: 200, body: JSON.stringify(true) };
};

export { bottomHalf } from "../service/actor";
