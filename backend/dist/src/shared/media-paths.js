/** S3 key prefix for this app inside the shared bucket. Do not write outside it. */
export const S3_MEDIA_PREFIX = "khatu-shyam";
export function isS3MediaKey(fileKey) {
    return fileKey.startsWith(`${S3_MEDIA_PREFIX}/`);
}
export function s3LibraryKey(type, category, fileName) {
    const folder = type === "wallpaper"
        ? "wallpapers"
        : type === "ringtone"
            ? "ringtones"
            : "posters";
    return `${S3_MEDIA_PREFIX}/${folder}/${category}/${fileName}`;
}
export function s3UserUploadKey(userId, purpose, fileName) {
    return `${S3_MEDIA_PREFIX}/private/users/${userId}/${purpose}/${fileName}`;
}
