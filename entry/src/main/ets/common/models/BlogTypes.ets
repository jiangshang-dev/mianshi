import { mallNum, mallStr } from './MallTypes';

export interface BlogCategory {
  id?: string;
  name?: string;
  icon?: string;
}

export interface BlogArticle {
  id?: string;
  categoryId?: string;
  categoryName?: string;
  title?: string;
  summary?: string;
  coverUrl?: string;
  content?: string;
  authorName?: string;
  vipOnly?: boolean;
  vipLocked?: boolean;
  liked?: boolean;
  favored?: boolean;
  recommend?: boolean;
  viewCount?: number;
  likeCount?: number;
  commentCount?: number;
  favoriteCount?: number;
  readPoints?: number;
  publishTime?: string;
  ipAddress?: string;
}

export interface BlogArticlePage {
  records?: BlogArticle[];
  total?: number;
}

export interface BlogToggle {
  on?: boolean;
  count?: number;
}

export interface JeecgBlogMsgResp {
  success?: boolean;
  message?: string;
  code?: number;
}

export interface JeecgBlogCategoryListResp {
  success?: boolean;
  message?: string;
  result?: BlogCategory[];
  code?: number;
}

export interface JeecgBlogArticlePageResp {
  success?: boolean;
  message?: string;
  result?: BlogArticlePage;
  code?: number;
}

export interface JeecgBlogArticleResp {
  success?: boolean;
  message?: string;
  result?: BlogArticle;
  code?: number;
}

export interface JeecgBlogArticleListResp {
  success?: boolean;
  message?: string;
  result?: BlogArticle[];
  code?: number;
}

export interface JeecgBlogToggleResp {
  success?: boolean;
  message?: string;
  result?: BlogToggle;
  code?: number;
}

export interface BlogComment {
  id?: string;
  articleId?: string;
  nickname?: string;
  avatar?: string;
  parentId?: string;
  rootId?: string;
  replyToNickname?: string;
  content?: string;
  status?: number;
  hint?: string;
  createTime?: string;
  likeCount?: number;
  dislikeCount?: number;
  myVote?: number;
  replyCount?: number;
  mine?: boolean;
  ipAddress?: string;
  replies?: BlogComment[];
}

export interface BlogCommentVote {
  commentId?: string;
  likeCount?: number;
  dislikeCount?: number;
  myVote?: number;
}

export interface BlogCommentVoteBody {
  commentId: string;
  vote: number;
}

export interface BlogCommentPostBody {
  parentId: string;
  content: string;
}

export interface JeecgBlogCommentListResp {
  success?: boolean;
  message?: string;
  result?: BlogComment[];
  code?: number;
}

export interface JeecgBlogCommentResp {
  success?: boolean;
  message?: string;
  result?: BlogComment;
  code?: number;
}

export interface JeecgBlogCommentVoteResp {
  success?: boolean;
  message?: string;
  result?: BlogCommentVote;
  code?: number;
}

export interface BlogTab {
  id: string;
  name: string;
}

export function mallBool(value?: boolean, fallback: boolean = false): boolean {
  if (value === undefined) {
    return fallback;
  }
  return value === true;
}

export function copyBlogCategory(raw: BlogCategory): BlogCategory {
  const item: BlogCategory = {
    id: mallStr(raw.id),
    name: mallStr(raw.name),
    icon: mallStr(raw.icon)
  };
  return item;
}

export function copyBlogArticle(raw: BlogArticle): BlogArticle {
  const item: BlogArticle = {
    id: mallStr(raw.id),
    categoryId: mallStr(raw.categoryId),
    categoryName: mallStr(raw.categoryName),
    title: mallStr(raw.title),
    summary: mallStr(raw.summary),
    coverUrl: mallStr(raw.coverUrl),
    content: mallStr(raw.content),
    authorName: mallStr(raw.authorName),
    vipOnly: mallBool(raw.vipOnly),
    vipLocked: mallBool(raw.vipLocked),
    liked: mallBool(raw.liked),
    favored: mallBool(raw.favored),
    recommend: mallBool(raw.recommend),
    viewCount: mallNum(raw.viewCount),
    likeCount: mallNum(raw.likeCount),
    commentCount: mallNum(raw.commentCount),
    favoriteCount: mallNum(raw.favoriteCount),
    readPoints: mallNum(raw.readPoints),
    publishTime: mallStr(raw.publishTime),
    ipAddress: mallStr(raw.ipAddress)
  };
  return item;
}

export function copyBlogComment(raw: BlogComment): BlogComment {
  const replies: BlogComment[] = [];
  const src = raw.replies;
  if (src !== undefined) {
    for (let i = 0; i < src.length; i++) {
      replies.push(copyBlogComment(src[i]));
    }
  }
  const item: BlogComment = {
    id: mallStr(raw.id),
    articleId: mallStr(raw.articleId),
    nickname: mallStr(raw.nickname),
    avatar: mallStr(raw.avatar),
    parentId: mallStr(raw.parentId),
    rootId: mallStr(raw.rootId),
    replyToNickname: mallStr(raw.replyToNickname),
    content: mallStr(raw.content),
    status: mallNum(raw.status, 1),
    hint: mallStr(raw.hint),
    createTime: mallStr(raw.createTime),
    likeCount: mallNum(raw.likeCount),
    dislikeCount: mallNum(raw.dislikeCount),
    myVote: mallNum(raw.myVote),
    replyCount: mallNum(raw.replyCount),
    mine: mallBool(raw.mine),
    ipAddress: mallStr(raw.ipAddress),
    replies: replies
  };
  return item;
}
