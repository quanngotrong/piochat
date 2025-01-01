import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3Client = new S3Client({
  region: "ap-southeast-1",
  forcePathStyle: true,
});
const bucket = "piochat-s3-quan-test";

export const genUploadPresignedUrl = async (key, expiresIn = 600) => {
  const url = await getSignedUrl(
    s3Client,
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
    }),
    { expiresIn },
  );

  return {
    url,
    bucket,
  };
};
