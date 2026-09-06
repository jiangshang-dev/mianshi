import { mallBool } from './BlogTypes';
import { mallNum, mallStr } from './MallTypes';

export interface ForumCategory {
  id?: string;
  name?: string;
  icon?: string;
}

export interface ForumPost {
  id?: string;
  categoryId?: string;
  categoryName?: string;
  userId?: number;
  nickname?: string;
  avatar?: string;
  member?: boolean;
  title?: string;
  summary?: string;
  content?: string;
  coverUrl?: string;
  images?: string[];
  pinned?: boolean;
  featured?: boolean;
  rejected?: boolean;
  pending?: boolean;
  rejectHint?: string;
  liked?: boolean;
  favored?: boolean;
  mine?: boolean;
  viewCount?: number;
  likeCount?: number;
  replyCount?: number;
  favoriteCount?: number;
  postPoints?: number;
  createTime?: string;
  ipAddress?: string;
  replies?: ForumReply[];
}

export interface ForumReply {
  id?: string;
  postId?: string;
  userId?: number;
  nickname?: string;
  avatar?: string;
  parentId?: string;
  replyToNickname?: string;
  content?: string;
  rejected?: boolean;
  pending?: boolean;
  author?: boolean;
  featured?: boolean;
  rejectHint?: string;
  liked?: boolean;
  mine?: boolean;
  likeCount?: number;
  createTime?: string;
  ipAddress?: string;
}

export interface ForumReplyRow {
  reply: ForumReply;
  depth: number;
}

export interface ForumReplyThread {
  root: ForumReply;
  children: ForumReplyRow[];
  floor: number;
}

export interface ForumPostPage {
  records?: ForumPost[];
  total?: number;
}

export interface ForumToggle {
  on?: boolean;
  count?: number;
}

export interface ForumDraftImage {
  key: string;
  preview: string;
  url: string;
}

export interface UploadFileResult {
  path?: string;
  url?: string;
}

export interface JeecgUploadResp {
  success?: boolean;
  message?: string;
  result?: UploadFileResult;
  code?: number;
}

export interface ForumTab {
  id: string;
  name: string;
}

export interface ForumFilter {
  id: string;
  name: string;
}

export interface ForumCatTone {
  bg: string;
  fg: string;
}

export interface JeecgForumCategoryListResp {
  success?: boolean;
  message?: string;
  result?: ForumCategory[];
  code?: number;
}

export interface JeecgForumPostPageResp {
  success?: boolean;
  message?: string;
  result?: ForumPostPage;
  code?: number;
}

export interface JeecgForumPostResp {
  success?: boolean;
  message?: string;
  result?: ForumPost;
  code?: number;
}

export interface JeecgForumPostListResp {
  success?: boolean;
  message?: string;
  result?: ForumPost[];
  code?: number;
}

export interface JeecgForumReplyResp {
  success?: boolean;
  message?: string;
  result?: ForumReply;
  code?: number;
}

export interface JeecgForumToggleResp {
  success?: boolean;
  message?: string;
  result?: ForumToggle;
  code?: number;
}

export interface JeecgForumMsgResp {
  success?: boolean;
  message?: string;
  code?: number;
}

export function copyForumCategory(raw: ForumCategory): ForumCategory {
  const item: ForumCategory = {
    id: mallStr(raw.id),
    name: mallStr(raw.name),
    icon: mallStr(raw.icon)
  };
  return item;
}

export function copyForumReply(raw: ForumReply): ForumReply {
  const item: ForumReply = {
    id: mallStr(raw.id),
    postId: mallStr(raw.postId),
    userId: mallNum(raw.userId),
    nickname: mallStr(raw.nickname),
    avatar: mallStr(raw.avatar),
    parentId: mallStr(raw.parentId),
    replyToNickname: mallStr(raw.replyToNickname),
    content: mallStr(raw.content),
    rejected: mallBool(raw.rejected),
    pending: mallBool(raw.pending),
    author: mallBool(raw.author),
    featured: mallBool(raw.featured),
    rejectHint: mallStr(raw.rejectHint),
    liked: mallBool(raw.liked),
    mine: mallBool(raw.mine),
    likeCount: mallNum(raw.likeCount),
    createTime: mallStr(raw.createTime),
    ipAddress: mallStr(raw.ipAddress)
  };
  return item;
}

export function copyForumPost(raw: ForumPost): ForumPost {
  const replies: ForumReply[] = [];
  const src = raw.replies;
  if (src !== undefined) {
    for (let i = 0; i < src.length; i++) {
      replies.push(copyForumReply(src[i]));
    }
  }
  const item: ForumPost = {
    id: mallStr(raw.id),
    categoryId: mallStr(raw.categoryId),
    categoryName: mallStr(raw.categoryName),
    userId: mallNum(raw.userId),
    nickname: mallStr(raw.nickname),
    avatar: mallStr(raw.avatar),
    member: mallBool(raw.member),
    title: mallStr(raw.title),
    summary: mallStr(raw.summary),
    content: mallStr(raw.content),
    coverUrl: mallStr(raw.coverUrl),
    images: copyForumImages(raw.images),
    pinned: mallBool(raw.pinned),
    featured: mallBool(raw.featured),
    rejected: mallBool(raw.rejected),
    pending: mallBool(raw.pending),
    rejectHint: mallStr(raw.rejectHint),
    liked: mallBool(raw.liked),
    favored: mallBool(raw.favored),
    mine: mallBool(raw.mine),
    viewCount: mallNum(raw.viewCount),
    likeCount: mallNum(raw.likeCount),
    replyCount: mallNum(raw.replyCount),
    favoriteCount: mallNum(raw.favoriteCount),
    postPoints: mallNum(raw.postPoints),
    createTime: mallStr(raw.createTime),
    ipAddress: mallStr(raw.ipAddress),
    replies: replies
  };
  return item;
}

export function copyForumImages(raw?: string[]): string[] {
  const list: string[] = [];
  if (raw === undefined) {
    return list;
  }
  for (let i = 0; i < raw.length; i++) {
    const url = mallStr(raw[i]);
    if (url.length > 0) {
      list.push(url);
    }
  }
  return list;
}

export interface ForumPostCreateBody {
  categoryId: string;
  title: string;
  content: string;
  images: string[];
}

export interface ForumReplyCreateBody {
  postId: string;
  parentId: string;
  content: string;
}
