import { HttpClient, MultipartPart } from '../../common/network/HttpClient';
import {
  ForumCategory,
  ForumPost,
  ForumPostCreateBody,
  ForumPostPage,
  ForumReply,
  ForumReplyCreateBody,
  ForumToggle,
  JeecgForumCategoryListResp,
  JeecgForumPostPageResp,
  JeecgForumPostListResp,
  JeecgForumMsgResp,
  JeecgForumPostResp,
  JeecgForumReplyResp,
  JeecgForumToggleResp,
  JeecgUploadResp,
  copyForumCategory,
  copyForumPost,
  copyForumReply
} from '../../common/models/ForumTypes';
import { mallStr } from '../../common/models/MallTypes';

export class ForumRepository {
  private static instance: ForumRepository | null = null;

  static getInstance(): ForumRepository {
    if (!ForumRepository.instance) {
      ForumRepository.instance = new ForumRepository();
    }
    return ForumRepository.instance;
  }

  static bumpList(): void {
    const tick = Date.now();
    AppStorage.setOrCreate('forumListTick', tick);
    AppStorage.set('forumListTick', tick);
  }

  async categories(): Promise<ForumCategory[]> {
    const resp = await HttpClient.get('/api/forum/categories', '');
    const parsed: JeecgForumCategoryListResp = JSON.parse(resp.body) as JeecgForumCategoryListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '分类加载失败');
    const list: ForumCategory[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        const item = copyForumCategory(raw[i]);
        if (mallStr(item.id).length > 0) {
          list.push(item);
        }
      }
    }
    return list;
  }

  async posts(categoryId: string, pageNo: number, sort: string, keyword: string): Promise<ForumPostPage> {
    const query = `categoryId=${encodeURIComponent(categoryId)}&pageNo=${pageNo}&pageSize=20` +
      `&sort=${encodeURIComponent(sort)}&keyword=${encodeURIComponent(keyword)}`;
    const resp = await HttpClient.get('/api/forum/posts', query);
    const parsed: JeecgForumPostPageResp = JSON.parse(resp.body) as JeecgForumPostPageResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '帖子加载失败');
    const page: ForumPostPage = { records: [], total: 0 };
    const raw = parsed.result;
    if (raw !== undefined) {
      page.total = raw.total !== undefined ? raw.total : 0;
      const records: ForumPost[] = [];
      const src = raw.records;
      if (src !== undefined) {
        for (let i = 0; i < src.length; i++) {
          records.push(copyForumPost(src[i]));
        }
      }
      page.records = records;
    }
    return page;
  }

  async detail(id: string): Promise<ForumPost> {
    const resp = await HttpClient.get(`/api/forum/posts/${id}`, '');
    const parsed: JeecgForumPostResp = JSON.parse(resp.body) as JeecgForumPostResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '帖子不存在');
    if (parsed.result === undefined) {
      throw new Error('帖子不存在');
    }
    return copyForumPost(parsed.result);
  }

  async deletePost(id: string): Promise<void> {
    const resp = await HttpClient.postJson(`/api/forum/posts/${id}/delete`, '{}');
    const parsed: JeecgForumMsgResp = JSON.parse(resp.body) as JeecgForumMsgResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '删除失败');
  }

  async createPost(categoryId: string, title: string, content: string, images: string[]): Promise<ForumPost> {
    const payload: ForumPostCreateBody = {
      categoryId: categoryId,
      title: title,
      content: content,
      images: images
    };
    const resp = await HttpClient.postJson('/api/forum/posts', JSON.stringify(payload));
    const parsed: JeecgForumPostResp = JSON.parse(resp.body) as JeecgForumPostResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '发帖失败');
    if (parsed.result === undefined) {
      throw new Error('发帖失败');
    }
    return copyForumPost(parsed.result);
  }

  async uploadImage(filePath: string, fileName: string): Promise<string> {
    const biz: MultipartPart = { name: 'biz', data: 'forum' };
    const file: MultipartPart = {
      name: 'file',
      filePath: filePath,
      fileName: fileName,
      mimeType: 'image/jpeg'
    };
    const parts: MultipartPart[] = [biz, file];
    const resp = await HttpClient.postMultipart('/user/upload', parts);
    const parsed: JeecgUploadResp = JSON.parse(resp.body) as JeecgUploadResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '图片上传失败');
    const result = parsed.result;
    if (result === undefined) {
      throw new Error('图片上传失败');
    }
    const url = mallStr(result.url);
    if (url.length > 0) {
      return url;
    }
    const path = mallStr(result.path);
    if (path.indexOf('http://') === 0 || path.indexOf('https://') === 0) {
      return path;
    }
    throw new Error('图片上传失败');
  }

  async createReply(postId: string, content: string, parentId: string): Promise<ForumReply> {
    const payload: ForumReplyCreateBody = {
      postId: postId,
      parentId: parentId,
      content: content
    };
    const resp = await HttpClient.postJson('/api/forum/replies', JSON.stringify(payload));
    const parsed: JeecgForumReplyResp = JSON.parse(resp.body) as JeecgForumReplyResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '回复失败');
    if (parsed.result === undefined) {
      throw new Error('回复失败');
    }
    return copyForumReply(parsed.result);
  }

  async deleteReply(id: string): Promise<void> {
    const resp = await HttpClient.postJson(`/api/forum/replies/${id}/delete`, '{}');
    const parsed: JeecgForumMsgResp = JSON.parse(resp.body) as JeecgForumMsgResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '删除失败');
  }

  async toggleLike(targetType: string, targetId: string): Promise<ForumToggle> {
    const resp = await HttpClient.postJson(`/api/forum/like?targetType=${targetType}&targetId=${targetId}`, '{}');
    const parsed: JeecgForumToggleResp = JSON.parse(resp.body) as JeecgForumToggleResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '点赞失败');
    const empty: ForumToggle = { on: false, count: 0 };
    return parsed.result !== undefined ? parsed.result : empty;
  }

  async toggleFavorite(id: string): Promise<ForumToggle> {
    const resp = await HttpClient.postJson(`/api/forum/posts/${id}/favorite`, '{}');
    const parsed: JeecgForumToggleResp = JSON.parse(resp.body) as JeecgForumToggleResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '收藏失败');
    const empty: ForumToggle = { on: false, count: 0 };
    return parsed.result !== undefined ? parsed.result : empty;
  }

  async listFavorites(): Promise<ForumPost[]> {
    const resp = await HttpClient.get('/api/forum/favorites', '');
    const parsed: JeecgForumPostListResp = JSON.parse(resp.body) as JeecgForumPostListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '收藏加载失败');
    const list: ForumPost[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        list.push(copyForumPost(raw[i]));
      }
    }
    return list;
  }

  private ensureOk(success: boolean | undefined, message: string | undefined, ok: boolean, fallback: string): void {
    if (success === false || !ok) {
      const text = mallStr(message);
      throw new Error(text.length > 0 ? text : fallback);
    }
  }
}
