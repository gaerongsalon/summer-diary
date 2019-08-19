import {
  ActorSystem,
  InMemoryLock,
  InMemoryQueue
} from "@yingyeothon/actor-system";
import { RedisLock, RedisQueue } from "@yingyeothon/actor-system-redis-support";
import {
  IExpirableRepository,
  InMemoryRepository,
  IRepository
} from "@yingyeothon/repository";
import { RedisRepository } from "@yingyeothon/repository-redis";
import { S3Repository } from "@yingyeothon/repository-s3";
import { ApiGatewayManagementApi, S3 } from "aws-sdk";
import IORedis from "ioredis";
import mem from "mem";
import { v4 as uuidv4 } from "uuid";
import envars from "./envars";
import logger from "./logger";

export const getRedis = mem(() => {
  if (!envars.external.production) {
    throw new Error(`Do not use Redis while testing.`);
  }
  return new IORedis(envars.redis);
});

export const getActorSystem = mem(() =>
  envars.external.production
    ? new ActorSystem({
        queue: new RedisQueue({ redis: getRedis(), logger }),
        lock: new RedisLock({ redis: getRedis(), logger }),
        logger
      })
    : new ActorSystem({
        queue: new InMemoryQueue(),
        lock: new InMemoryLock(),
        logger
      })
);

interface IRepositories {
  connection: {
    toNote: IExpirableRepository;
    fromNote: IExpirableRepository;
  };
  document: IRepository;
}

export const getRepository = mem(
  (): IRepositories => {
    if (envars.external.production) {
      const redis = new RedisRepository({ redis: getRedis() });
      return {
        connection: {
          toNote: redis.withPrefix("c2n:"),
          fromNote: redis.withPrefix("n2c:")
        },
        document: new S3Repository({ bucketName: envars.s3.documentBucketName })
      };
    } else {
      const inMemory = new InMemoryRepository();
      return {
        connection: {
          toNote: inMemory,
          fromNote: inMemory
        },
        document: inMemory
      };
    }
  }
);

export const getS3ImageUploader = mem(() => {
  if (!envars.external.production) {
    throw new Error(`Do not use S3 while testing.`);
  }
  const s3 = new S3();
  return (noteId: string, type: "jpg" | "png" = "jpg") => {
    const imageId = [uuidv4(), uuidv4()].join("-") + `.${type}`;
    const uploadUrl = s3.getSignedUrl("putObject", {
      Bucket: envars.s3.imageBucketName,
      Key: [noteId, imageId].join("/"),
      ContentType: `image/${type}`,
      Expires: 10 * 60
    });
    const cdnUrl = `${envars.s3.imageCdnUrlPrefix}/${imageId}`;
    return { uploadUrl, cdnUrl };
  };
});

export const getSocketResponder = mem(() => {
  if (!envars.external.production) {
    throw new Error(`Do not use WebSocket while testing.`);
  }
  const apimgmt = new ApiGatewayManagementApi({
    endpoint: envars.websocket.endpoint
  });
  return async <T>(noteId: string, payload: T) => {
    if (!payload) {
      logger.error(`Invalid payload for note[${noteId}]`);
      return false;
    }
    const connectionIds = await getRepository().connection.fromNote.get<
      string[]
    >(noteId);
    if (!connectionIds || connectionIds.length === 0) {
      logger.info(`No connections for note[${noteId}]`);
      return false;
    }
    const data = JSON.stringify(payload);
    return Promise.all(
      connectionIds.map(connectionId =>
        apimgmt
          .postToConnection({ ConnectionId: connectionId, Data: data })
          .promise()
      )
    );
  };
});
