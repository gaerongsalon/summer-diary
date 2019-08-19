import { APIGatewayProxyHandler } from "aws-lambda";
import { getNotesService } from "../service";

export const getNotes: APIGatewayProxyHandler = async event => {
  const userId = event.headers["x-user"];
  if (!userId) {
    return { statusCode: 401, body: "Unauthorized" };
  }
  const notes = await getNotesService(userId).getNotes();
  return { statusCode: 200, body: JSON.stringify(notes) };
};
