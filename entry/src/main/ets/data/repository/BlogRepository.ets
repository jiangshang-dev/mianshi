import { HttpClient } from '../../common/network/HttpClient';
import {
  BlogArticle,
  BlogArticlePage,
  BlogCategory,
  BlogComment,
  BlogCommentPostBody,
  BlogCommentVote,
  BlogCommentVoteBody,
  BlogToggle,
  JeecgBlogArticleListResp,
  JeecgBlogArticlePageResp,
  JeecgBlogArticleResp,
  JeecgBlogCategoryListResp,
  JeecgBlogCommentListResp,
  JeecgBlogCommentResp,
  JeecgBlogCommentVoteResp,
  JeecgBlogToggleResp,
  copyBlogArticle,
  copyBlogCategory,
  copyBlogComment
} from '../../common/models/BlogTypes';
import { mallStr } from '../../common/models/MallTypes';

export class BlogRepository {
  private static instance: BlogRepository | null = null;

  static getInstance(): BlogRepository {
    if (!BlogRepository.instance) {
      BlogRepository.instance = new BlogRepository();
    }
    return BlogRepository.instance;
  }

  static bumpComments(): void {
    const tick = Date.now();
    AppStorage.setOrCreate('blogCommentTick', tick);
    AppStorage.set('blogCommentTick', tick);
  }

  static bumpList(): void {
    const tick = Date.now();
    AppStorage.setOrCreate('blogListTick', tick);
    AppStorage.set('blogListTick', tick);
  }

  async categories(): Promise<BlogCategory[]> {
    const resp = await HttpClient.get('/api/blog/categories', '');
    const parsed: JeecgBlogCategoryListResp = JSON.parse(resp.body) as JeecgBlogCategoryListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '分类加载失败');
    const list: BlogCategory[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        const item = copyBlogCategory(raw[i]);
        if (mallStr(item.id).length > 0) {
          list.push(item);
        }
      }
    }
    return list;
  }

  async articles(categoryId: string, pageNo: number, keyword: string): Promise<BlogArticlePage> {
    const query = `categoryId=${encodeURIComponent(categoryId)}&pageNo=${pageNo}&pageSize=20` +
      `&q=${encodeURIComponent(keyword)}`;
    const resp = await HttpClient.get('/api/blog/articles', query);
    const parsed: JeecgBlogArticlePageResp = JSON.parse(resp.body) as JeecgBlogArticlePageResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '文章加载失败');
    const page: BlogArticlePage = { records: [], total: 0 };
    const raw = parsed.result;
    if (raw !== undefined) {
      page.total = raw.total !== undefined ? raw.total : 0;
      const records: BlogArticle[] = [];
      const src = raw.records;
      if (src !== undefined) {
        for (let i = 0; i < src.length; i++) {
          records.push(copyBlogArticle(src[i]));
        }
      }
      page.records = records;
    }
    return page;
  }

  async detail(id: string): Promise<BlogArticle> {
    const resp = await HttpClient.get(`/api/blog/articles/${id}`, '');
    const parsed: JeecgBlogArticleResp = JSON.parse(resp.body) as JeecgBlogArticleResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '文章不存在');
    if (parsed.result === undefined) {
      throw new Error('文章不存在');
    }
    return copyBlogArticle(parsed.result);
  }

  async toggleLike(id: string): Promise<BlogToggle> {
    const resp = await HttpClient.postJson(`/api/blog/articles/${id}/like`, '{}');
    const parsed: JeecgBlogToggleResp = JSON.parse(resp.body) as JeecgBlogToggleResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '点赞失败');
    const result = parsed.result;
    const empty: BlogToggle = { on: false, count: 0 };
    return result !== undefined ? result : empty;
  }

  async toggleFavorite(id: string): Promise<BlogToggle> {
    const resp = await HttpClient.postJson(`/api/blog/articles/${id}/favorite`, '{}');
    const parsed: JeecgBlogToggleResp = JSON.parse(resp.body) as JeecgBlogToggleResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '收藏失败');
    const result = parsed.result;
    const empty: BlogToggle = { on: false, count: 0 };
    return result !== undefined ? result : empty;
  }

  async listFavorites(): Promise<BlogArticle[]> {
    const resp = await HttpClient.get('/api/blog/favorites', '');
    const parsed: JeecgBlogArticleListResp = JSON.parse(resp.body) as JeecgBlogArticleListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '收藏加载失败');
    const list: BlogArticle[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        list.push(copyBlogArticle(raw[i]));
      }
    }
    return list;
  }

  async comments(articleId: string): Promise<BlogComment[]> {
    const resp = await HttpClient.get(`/api/blog/articles/${articleId}/comments`, '');
    const parsed: JeecgBlogCommentListResp = JSON.parse(resp.body) as JeecgBlogCommentListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '评论加载失败');
    const list: BlogComment[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        list.push(copyBlogComment(raw[i]));
      }
    }
    return list;
  }

  async postComment(articleId: string, content: string, parentId: string): Promise<BlogComment> {
    const payload: BlogCommentPostBody = {
      parentId: parentId,
      content: content
    };
    const resp = await HttpClient.postJson(`/api/blog/articles/${articleId}/comments`, JSON.stringify(payload));
    const parsed: JeecgBlogCommentResp = JSON.parse(resp.body) as JeecgBlogCommentResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '发布失败');
    if (parsed.result === undefined) {
      throw new Error('发布失败');
    }
    return copyBlogComment(parsed.result);
  }

  async voteComment(commentId: string, vote: number): Promise<BlogCommentVote> {
    const payload: BlogCommentVoteBody = {
      commentId: commentId,
      vote: vote
    };
    const resp = await HttpClient.postJson('/api/blog/comments/vote', JSON.stringify(payload));
    const parsed: JeecgBlogCommentVoteResp = JSON.parse(resp.body) as JeecgBlogCommentVoteResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '操作失败');
    const result = parsed.result;
    const empty: BlogCommentVote = { commentId: commentId, likeCount: 0, dislikeCount: 0, myVote: 0 };
    return result !== undefined ? result : empty;
  }

  private ensureOk(success: boolean | undefined, message: string | undefined, ok: boolean, fallback: string): void {
    if (success === false || !ok) {
      const text = mallStr(message);
      throw new Error(text.length > 0 ? text : fallback);
    }
  }
}
