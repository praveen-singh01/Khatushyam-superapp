/** S3 key prefix for this app inside the shared bucket. Do not write outside it. */
export const S3_MEDIA_PREFIX = "khatu-shyam";

export function isS3MediaKey(fileKey: string): boolean {
  return fileKey.startsWith(`${S3_MEDIA_PREFIX}/`);
}

export function s3LibraryKey(
  type: "wallpaper" | "ringtone",
  category: string,
  fileName: string,
): string {
  const folder = type === "wallpaper" ? "wallpapers" : "ringtones";
  return `${S3_MEDIA_PREFIX}/${folder}/${category}/${fileName}`;
}

export function s3UserUploadKey(
  userId: string,
  purpose: string,
  fileName: string,
): string {
  return `${S3_MEDIA_PREFIX}/private/users/${userId}/${purpose}/${fileName}`;
}
