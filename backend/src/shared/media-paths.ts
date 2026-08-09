/** S3 key prefix for this app inside the shared bucket. Do not write outside it. */
export const S3_MEDIA_PREFIX = "khatu-shyam";

export type LibraryMediaType = "wallpaper" | "ringtone" | "poster";

export function isS3MediaKey(fileKey: string): boolean {
  return fileKey.startsWith(`${S3_MEDIA_PREFIX}/`);
}

export function s3LibraryKey(
  type: LibraryMediaType,
  category: string,
  fileName: string,
): string {
  const folder =
    type === "wallpaper"
      ? "wallpapers"
      : type === "ringtone"
        ? "ringtones"
        : "posters";
  return `${S3_MEDIA_PREFIX}/${folder}/${category}/${fileName}`;
}

export function s3UserUploadKey(
  userId: string,
  purpose: string,
  fileName: string,
): string {
  return `${S3_MEDIA_PREFIX}/private/users/${userId}/${purpose}/${fileName}`;
}
