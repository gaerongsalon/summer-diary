import {
  handleActorLambdaEvent,
  IActorLambdaEvent,
  shiftToNextLambda
} from "@yingyeothon/actor-system-aws-lambda-support";
import mem from "mem";
import envars from "../../system/envars";
import { getActorSystem } from "../../system/external";
import logger from "../../system/logger";
import { ActorMessage } from "./message";
import { NoteProcessor } from "./note";
import { NotesProcessor } from "./notes";

const getActor = mem((s3Key: string) => {
  const [type] = s3Key.split("/");
  const processor =
    type === "notes" ? new NotesProcessor(s3Key) : new NoteProcessor(s3Key);
  return getActorSystem().spawn<ActorMessage>(s3Key, actor =>
    actor
      .on("beforeAct", processor.onBeforeAct)
      .on("afterAct", processor.onAfterAct)
      .on("act", processor.onAct)
      .on("error", error => logger.error(`ActorError`, s3Key, error))
      .on(
        "shift",
        shiftToNextLambda({ functionName: envars.actor.bottomHalfLambda })
      )
  );
});

const topHalfTimeout = 1 * 1000;
const bottomHalfTimeout = 890 * 1000;

export const requestToActor = (s3Key: string, message: ActorMessage) =>
  getActor(s3Key).send(message, { shiftTimeout: topHalfTimeout });

export const bottomHalf = handleActorLambdaEvent<IActorLambdaEvent>({
  spawn: ({ actorName }) => getActor(actorName),
  functionTimeout: bottomHalfTimeout,
  logger
});
