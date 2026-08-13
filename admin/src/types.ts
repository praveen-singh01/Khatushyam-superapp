export type SubscriptionStatus =
  | "inactive"
  | "pending"
  | "active"
  | "halted"
  | "cancelled";

export type UserRole = "user" | "admin";
export type ContentType = "wallpaper" | "ringtone" | "poster";
export type ContentStatus = "draft" | "published" | "archived";

export interface AuthUser {
  id: string;
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  role: UserRole;
  subscriptionStatus: SubscriptionStatus;
}

export interface AdminStats {
  users: { total: number; premium: number; admins: number };
  content: {
    total: number;
    wallpapers: number;
    ringtones: number;
    posters: number;
  };
  categories: {
    total: number;
    wallpapers: number;
    ringtones: number;
    posters: number;
  };
  chamatkars: { total: number };
}

export interface ContentCategory {
  id: string;
  type: ContentType;
  slug: string;
  label: { hi: string; en: string };
  createdAt?: string;
  updatedAt?: string;
}

export interface LiveStreamConfig {
  isLive: boolean;
  youtubeVideoId: string | null;
  title: { hi: string; en: string };
  embedUrl: string | null;
  updatedAt?: string | null;
}

export interface StoryChapter {
  title: { hi: string; en: string };
  body: { hi: string; en: string };
}

export interface StoryConfig {
  title: { hi: string; en: string };
  summary: { hi: string; en: string };
  youtubeVideoId: string | null;
  chapters: StoryChapter[];
  access?: "free";
  updatedAt?: string | null;
}

export interface TravelGuideItem {
  id: string;
  fromCity: { hi: string; en: string };
  title: { hi: string; en: string };
  steps: { hi: string; en: string }[];
}

export interface TravelGuidesConfig {
  guides: TravelGuideItem[];
  updatedAt?: string | null;
}

export interface ManagedUser {
  id: string;
  firebaseUid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;
  role: UserRole;
  subscriptionStatus: SubscriptionStatus;
  razorpaySubscriptionId?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface ContentItem {
  id: string;
  slug: string;
  type: ContentType;
  category: string;
  title: { hi: string; en: string };
  fileKey: string;
  url: string;
  format: string;
  width?: number;
  height?: number;
  durationSeconds?: number;
  license?: string;
  attribution?: string;
  premium: boolean;
  source?: string;
  status: ContentStatus;
  uploadedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface Paginated<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

