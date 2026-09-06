import { HttpClient } from '../../common/network/HttpClient';
import { LoginGate } from '../../common/utils/LoginGate';

export interface QuestionComment {
  id: string;
  questionId: string;
  userId: string;
  nickname: string;
  avatar: string;
  parentId: string;
  rootId: string;
  replyToNickname: string;
  content: string;
  status: number;
  rejectReason: string;
  hint: string;
  createTime: string;
  likeCount: number;
  dislikeCount: number;
  myVote: number;
  replyCount: number;
  ipAddress: string;
  replies: QuestionComment[];
}

export interface CommentVoteResult {
  commentId: string;
  likeCount: number;
  dislikeCount: number;
  myVote: number;
}

export interface CommentFlatRow {
  key: string;
  depth: number;
  item: QuestionComment;
}

export function emptyQuestionComment(): QuestionComment {
  const item: QuestionComment = {
    id: '',
    questionId: '',
    userId: '',
    nickname: '',
    avatar: '',
    parentId: '',
    rootId: '',
    replyToNickname: '',
    content: '',
    status: 1,
    rejectReason: '',
    hint: '',
    createTime: '',
    likeCount: 0,
    dislikeCount: 0,
    myVote: 0,
    replyCount: 0,
    ipAddress: '',
    replies: []
  };
  return item;
}

interface CommentListResponse {
  code: number;
  message?: string;
  result?: QuestionComment[];
  data?: QuestionComment[];
}

interface CommentPostResponse {
  code: number;
  message?: string;
  success?: boolean;
  result?: QuestionComment;
  data?: QuestionComment;
}

interface CommentVoteResponse {
  code: number;
  message?: string;
  success?: boolean;
  result?: CommentVoteResult;
  data?: CommentVoteResult;
}

interface CommentPostRequest {
  userId: string;
  questionId: string;
  parentId: string;
  content: string;
}

interface CommentVoteRequest {
  userId: string;
  commentId: string;
  vote: number;
}

export class CommentRepository {
  private static instance: CommentRepository | null = null;

  static getInstance(): CommentRepository {
    if (!CommentRepository.instance) {
      CommentRepository.instance = new CommentRepository();
    }
    return CommentRepository.instance;
  }

  async list(questionId: string): Promise<QuestionComment[]> {
    const userId = LoginGate.currentUserId();
    let query = `questionId=${encodeURIComponent(questionId)}`;
    if (userId.length > 0) {
      query = `${query}&userId=${encodeURIComponent(userId)}`;
    }
    const resp = await HttpClient.get('/api/comments', query);
    if (!resp.ok) {
      return [];
    }
    try {
      const parsed = JSON.parse(resp.body) as CommentListResponse;
      const list = parsed.result ?? parsed.data;
      if (!list) {
        return [];
      }
      return list.map((item: QuestionComment) => this.normalize(item));
    } catch (_e) {
      return [];
    }
  }

  async post(questionId: string, content: string, parentId: string): Promise<QuestionComment | string> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      return '请先登录';
    }
    const body: CommentPostRequest = {
      userId: userId,
      questionId: questionId,
      parentId: parentId,
      content: content
    };
    const resp = await HttpClient.postJson('/api/comments', JSON.stringify(body));
    try {
      const parsed = JSON.parse(resp.body) as CommentPostResponse;
      if (parsed.success === false || (parsed.code !== undefined && parsed.code !== 200 && parsed.code !== 0)) {
        return parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '发布失败';
      }
      const item = parsed.result ?? parsed.data;
      if (!item) {
        return parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '发布失败';
      }
      return this.normalize(item);
    } catch (_e) {
      return '发布失败';
    }
  }

  async vote(commentId: string, vote: number): Promise<CommentVoteResult | string> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      return '请先登录';
    }
    const body: CommentVoteRequest = {
      userId: userId,
      commentId: commentId,
      vote: vote
    };
    const resp = await HttpClient.postJson('/api/comments/vote', JSON.stringify(body));
    try {
      const parsed = JSON.parse(resp.body) as CommentVoteResponse;
      if (parsed.success === false || (parsed.code !== undefined && parsed.code !== 200 && parsed.code !== 0)) {
        return parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '操作失败';
      }
      const item = parsed.result ?? parsed.data;
      if (!item) {
        return parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '操作失败';
      }
      const result: CommentVoteResult = {
        commentId: item.commentId ?? commentId,
        likeCount: item.likeCount ?? 0,
        dislikeCount: item.dislikeCount ?? 0,
        myVote: item.myVote ?? 0
      };
      return result;
    } catch (_e) {
      return '操作失败';
    }
  }

  normalize(item: QuestionComment): QuestionComment {
    const repliesRaw = item.replies;
    const replies: QuestionComment[] = [];
    if (repliesRaw) {
      for (let i = 0; i < repliesRaw.length; i++) {
        replies.push(this.normalize(repliesRaw[i]));
      }
    }
    const result: QuestionComment = {
      id: item.id,
      questionId: item.questionId,
      userId: item.userId ?? '',
      nickname: item.nickname ?? '用户',
      avatar: item.avatar ?? '',
      parentId: item.parentId ?? '',
      rootId: item.rootId ?? '',
      replyToNickname: item.replyToNickname ?? '',
      content: item.content ?? '',
      status: item.status ?? 1,
      rejectReason: item.rejectReason ?? '',
      hint: item.hint ?? '',
      createTime: item.createTime ?? '',
      likeCount: item.likeCount ?? 0,
      dislikeCount: item.dislikeCount ?? 0,
      myVote: item.myVote ?? 0,
      replyCount: item.replyCount ?? replies.length,
      ipAddress: item.ipAddress ?? '',
      replies: replies
    };
    return result;
  }
}
