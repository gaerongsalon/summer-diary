import { APIGatewayProxyHandler } from "aws-lambda";
import { getRepository } from "../system/external";
import logger from "../system/logger";

const expiration = 2 * 60 * 60 * 1000;

export const connect: APIGatewayProxyHandler = async event => {
  const userId = (event.headers["x-user"] || "").trim();
  const noteId = (event.headers["x-note"] || "").trim();
  if (!userId || noteId) {
    logger.error(`Unauthorized`, event.headers);
    return { statusCode: 401, body: "Unauthorized" };
  }

  const connectionId = event.requestContext.connectionId!;
  const connectionRepo = getRepository().connection;
  try {
    await Promise.all([
      connectionRepo.toNote.setWithExpire(connectionId, noteId, expiration),
      // TODO It will be break if there are concurrent updates.
      connectionRepo.fromNote.set(noteId, [
        ...((await connectionRepo.fromNote.get<string[]>(noteId)) || []),
        connectionId
      ])
    ]);

    logger.info(`UpdateUserConnection`, userId, noteId, connectionId);
    return { statusCode: 200, body: "OK" };
  } catch (error) {
    logger.error(`CannotUpdateConnection`, userId, noteId, connectionId, error);
    return { statusCode: 500, body: "Internal Error" };
  }
};

export const disconnect: APIGatewayProxyHandler = async event => {
  const connectionId = event.requestContext.connectionId!;
  const connectionRepo = getRepository().connection;
  let noteId: string | undefined = "<Unknown>";
  try {
    noteId = await connectionRepo.toNote.get<string>(connectionId);
    if (!noteId) {
      logger.error(`No note mapped connection[${connectionId}]`);
    } else {
      await Promise.all([
        connectionRepo.toNote.delete(connectionId),

        // TODO It will be break if there are concurrent updates.
        connectionRepo.fromNote.set(
          noteId,
          ((await connectionRepo.fromNote.get<string[]>(noteId)) || []).filter(
            each => each !== connectionId
          )
        )
      ]);
      logger.info(`DeleteUserConnection`, noteId, connectionId);
    }
    return { statusCode: 200, body: "OK" };
  } catch (error) {
    logger.error(`CannotDeleteConnection`, noteId, connectionId, error);
    return { statusCode: 500, body: "Internal Error" };
  }
};

export const message: APIGatewayProxyHandler = async event => {
  const connectionId = event.requestContext.connectionId;
  logger.info(`SocketPayload`, connectionId, (event.body || "").length);
  return { statusCode: 200, body: "OK" };
};
