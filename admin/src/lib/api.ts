import type {
  AdminStats,
  AuthUser,
  ContentCategory,
  ContentItem,
  ContentStatus,
  ContentType,
  LiveStreamConfig,
  ManagedUser,
  Paginated,
  StoryConfig,
  SubscriptionStatus,
  UserRole,
} from "../types";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, "") ??
  "https://15.207.112.236.sslip.io";

export class ApiError extends Error {
  status: number;
  body: unknown;

  constructor(status: number, body: unknown) {
    super(
      typeof body === "object" &&
        body &&
        "error" in body &&
        typeof (body as { error: unknown }).error === "string"
        ? (body as { error: string }).error
        : `Request failed (${status})`,
    );
    this.status = status;
    this.body = body;
  }
}

async function request<T>(
  path: string,
  token: string,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers,
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(response.status, body);
  }
  return body as T;
}

export function getApiBase() {
  return API_BASE;
}

export function fetchMe(token: string) {
  return request<{ user: AuthUser }>("/v1/auth/me", token);
}

export function fetchStats(token: string) {
  return request<AdminStats>("/v1/admin/stats", token);
}

export function fetchCategories(token: string, type?: ContentType) {
  const query = type ? `?type=${type}` : "";
  return request<{
    items: ContentCategory[];
    byType: { wallpaper: string[]; ringtone: string[] };
  }>(`/v1/admin/categories${query}`, token);
}

export function createCategory(
  token: string,
  payload: {
    type: ContentType;
    slug: string;
    label?: { hi: string; en: string };
  },
) {
  return request<{ item: ContentCategory }>("/v1/admin/categories", token, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function deleteCategory(token: string, id: string) {
  return request<void>(`/v1/admin/categories/${id}`, token, {
    method: "DELETE",
  });
}

export function fetchStory(token: string) {
  return request<{ story: StoryConfig }>("/v1/admin/story", token);
}

export function updateStory(
  token: string,
  payload: {
    title: { hi: string; en: string };
    summary: { hi: string; en: string };
    youtubeVideoId?: string | null;
    chapters: StoryConfig["chapters"];
  },
) {
  return request<{ story: StoryConfig }>("/v1/admin/story", token, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

export function fetchLive(token: string) {
  return request<{ live: LiveStreamConfig }>("/v1/admin/live", token);
}

export function updateLive(
  token: string,
  payload: {
    isLive: boolean;
    youtubeVideoId?: string | null;
    title?: { hi: string; en: string };
  },
) {
  return request<{ live: LiveStreamConfig }>("/v1/admin/live", token, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

export function fetchUsers(
  token: string,
  params: {
    q?: string;
    role?: string;
    subscriptionStatus?: string;
    page?: number;
  } = {},
) {
  const query = new URLSearchParams();
  if (params.q) query.set("q", params.q);
  if (params.role) query.set("role", params.role);
  if (params.subscriptionStatus) {
    query.set("subscriptionStatus", params.subscriptionStatus);
  }
  if (params.page) query.set("page", String(params.page));
  const suffix = query.toString() ? `?${query}` : "";
  return request<Paginated<ManagedUser>>(`/v1/admin/users${suffix}`, token);
}

export function updateUser(
  token: string,
  id: string,
  patch: {
    role?: UserRole;
    subscriptionStatus?: SubscriptionStatus;
    displayName?: string;
  },
) {
  return request<{ user: ManagedUser }>(`/v1/admin/users/${id}`, token, {
    method: "PATCH",
    body: JSON.stringify(patch),
  });
}

export function fetchContent(
  token: string,
  params: {
    q?: string;
    type?: string;
    category?: string;
    status?: string;
    page?: number;
  } = {},
) {
  const query = new URLSearchParams();
  if (params.q) query.set("q", params.q);
  if (params.type) query.set("type", params.type);
  if (params.category) query.set("category", params.category);
  if (params.status) query.set("status", params.status);
  if (params.page) query.set("page", String(params.page));
  const suffix = query.toString() ? `?${query}` : "";
  return request<
    Paginated<ContentItem> & {
      categories: { wallpaper: string[]; ringtone: string[] };
    }
  >(`/v1/admin/content${suffix}`, token);
}

export function createContent(
  token: string,
  payload: {
    slug: string;
    type: ContentType;
    category: string;
    title: { hi: string; en: string };
    fileKey: string;
    format: string;
    width?: number;
    height?: number;
    durationSeconds?: number;
    license?: string;
    attribution?: string;
    premium?: boolean;
    source?: string;
    status?: ContentStatus;
  },
) {
  return request<{ item: ContentItem }>("/v1/admin/content", token, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateContent(
  token: string,
  id: string,
  patch: Partial<{
    type: ContentType;
    category: string;
    title: { hi: string; en: string };
    fileKey: string;
    format: string;
    width?: number;
    height?: number;
    durationSeconds?: number;
    license?: string;
    attribution?: string;
    premium: boolean;
    source?: string;
    status: ContentStatus;
  }>,
) {
  return request<{ item: ContentItem }>(`/v1/admin/content/${id}`, token, {
    method: "PATCH",
    body: JSON.stringify(patch),
  });
}

export function archiveContent(token: string, id: string) {
  return request<{ item: ContentItem }>(`/v1/admin/content/${id}`, token, {
    method: "DELETE",
  });
}

export async function uploadLibraryFile(
  token: string,
  file: File,
  type: ContentType,
  category: string,
) {
  const contentType = normalizeContentType(file.type, file.name);
  const presign = await request<{
    key: string;
    uploadUrl: string;
    publicUrl: string;
  }>("/v1/admin/uploads/presign", token, {
    method: "POST",
    body: JSON.stringify({
      type,
      category,
      contentType,
      fileName: file.name,
    }),
  });

  const isLocalFake = presign.uploadUrl.includes("s3.example.com");
  if (!isLocalFake) {
    const uploadResponse = await fetch(presign.uploadUrl, {
      method: "PUT",
      headers: { "Content-Type": contentType },
      body: file,
    });
    if (!uploadResponse.ok) {
      throw new Error(`S3 upload failed (${uploadResponse.status})`);
    }
  }

  return {
    key: presign.key,
    publicUrl: presign.publicUrl,
    format: extensionFromName(file.name, contentType),
  };
}

function normalizeContentType(type: string, fileName: string) {
  if (type) {
    if (type === "audio/x-m4a" || type === "audio/mp4") return type;
    if (type.startsWith("image/") || type.startsWith("audio/")) return type;
  }
  const lower = fileName.toLowerCase();
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".mp3")) return "audio/mpeg";
  if (lower.endsWith(".m4a")) return "audio/mp4";
  throw new Error("Unsupported file type");
}

function extensionFromName(fileName: string, contentType: string) {
  const fromName = fileName.split(".").pop()?.toLowerCase();
  if (fromName) return fromName === "jpeg" ? "jpg" : fromName;
  if (contentType === "image/jpeg") return "jpg";
  if (contentType === "image/png") return "png";
  if (contentType === "image/webp") return "webp";
  if (contentType === "audio/mpeg") return "mp3";
  return "m4a";
}
