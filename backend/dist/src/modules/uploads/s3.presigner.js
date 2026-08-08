import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
export function createS3UploadPresigner(region) {
    const s3 = new S3Client({ region });
    return {
        async createUploadUrl({ bucket, key, contentType, metadata, expiresInSeconds, }) {
            const command = new PutObjectCommand({
                Bucket: bucket,
                Key: key,
                ContentType: contentType,
                Metadata: metadata,
            });
            return getSignedUrl(s3, command, { expiresIn: expiresInSeconds });
        },
    };
}
