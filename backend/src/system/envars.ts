const envars = {
  redis: {
    host: process.env.REDIS_HOST!,
    password: process.env.REDIS_PASSWORD
  },
  s3: {
    documentBucketName: process.env.DOCUMENT_BUCKET_NAME!,
    imageBucketName: process.env.IMAGE_BUCKET_NAME!,
    imageCdnUrlPrefix: process.env.IMAGE_CDN_URL_PREFIX!
  },
  websocket: {
    endpoint: process.env.WEBSOCKET_ENDPOINT!
  },
  actor: {
    bottomHalfLambda: process.env.BOTTOM_HALF_LAMBDA!
  },
  external: {
    production:
      process.env.NODE_ENV !== "test" || process.env.EXTERNAL === "production"
  },
  logging: {
    debug: process.env.DEBUG === "1",
    elapsed: process.env.ELAPSED === "1"
  }
};

export default envars;
