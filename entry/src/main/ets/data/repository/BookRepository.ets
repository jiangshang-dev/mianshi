import { HttpClient } from '../../common/network/HttpClient';
import {
  BookCategory,
  BookHome,
  BookItem,
  BookItemPage,
  JeecgBookCategoryListResp,
  JeecgBookHomeResp,
  JeecgBookItemResp,
  JeecgBookPageResp,
  copyBookCategory,
  copyBookHome,
  copyBookItem
} from '../../common/models/BookTypes';
import { mallStr } from '../../common/models/MallTypes';
import { BookMedia } from '../../common/utils/BookMedia';

export class BookRepository {
  private static instance: BookRepository | null = null;

  static getInstance(): BookRepository {
    if (!BookRepository.instance) {
      BookRepository.instance = new BookRepository();
    }
    return BookRepository.instance;
  }

  async categories(): Promise<BookCategory[]> {
    const resp = await HttpClient.get('/api/book/categories', '');
    const parsed: JeecgBookCategoryListResp = JSON.parse(resp.body) as JeecgBookCategoryListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '分类加载失败');
    const list: BookCategory[] = [];
    const raw = parsed.result;
    if (raw !== undefined) {
      for (let i = 0; i < raw.length; i++) {
        const item = copyBookCategory(raw[i]);
        if (mallStr(item.id).length > 0) {
          list.push(item);
        }
      }
    }
    return list;
  }

  async home(): Promise<BookHome> {
    const resp = await HttpClient.get('/api/book/home', '');
    const parsed: JeecgBookHomeResp = JSON.parse(resp.body) as JeecgBookHomeResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '书库加载失败');
    if (parsed.result === undefined) {
      const empty: BookHome = { categories: [], weekly: [], featured: [] };
      return empty;
    }
    return copyBookHome(parsed.result);
  }

  async list(tab: string, categoryId: string, pageNo: number, filter: string = ''): Promise<BookItemPage> {
    const query = `tab=${encodeURIComponent(tab)}&categoryId=${encodeURIComponent(categoryId)}` +
      `&filter=${encodeURIComponent(filter)}&pageNo=${pageNo}&pageSize=20`;
    const resp = await HttpClient.get('/api/book/list', query);
    const parsed: JeecgBookPageResp = JSON.parse(resp.body) as JeecgBookPageResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '图书加载失败');
    const page: BookItemPage = { records: [], total: 0 };
    const raw = parsed.result;
    if (raw !== undefined) {
      page.total = raw.total !== undefined ? raw.total : 0;
      const records: BookItem[] = [];
      const src = raw.records;
      if (src !== undefined) {
        for (let i = 0; i < src.length; i++) {
          records.push(copyBookItem(src[i]));
        }
      }
      page.records = records;
    }
    return page;
  }

  async detail(id: string): Promise<BookItem> {
    const resp = await HttpClient.get(`/api/book/${encodeURIComponent(id)}`, '');
    const parsed: JeecgBookItemResp = JSON.parse(resp.body) as JeecgBookItemResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '打开失败');
    if (parsed.result === undefined) {
      throw new Error('打开失败');
    }
    return copyBookItem(parsed.result);
  }

  async saveProgress(id: string, pageIndex: number, pageCount: number): Promise<void> {
    const body = JSON.stringify({ pageIndex: pageIndex, pageCount: pageCount });
    await HttpClient.postJson(`/api/book/${encodeURIComponent(id)}/progress`, body);
  }

  fileUrl(item: BookItem): string {
    return BookMedia.resolve(mallStr(item.fileUrl));
  }

  coverUrl(item: BookItem): string {
    return BookMedia.resolve(mallStr(item.coverUrl));
  }

  private ensureOk(success?: boolean, message?: string, httpOk?: boolean, fallback: string = '请求失败'): void {
    if (httpOk === false || success === false) {
      throw new Error(mallStr(message).length > 0 ? mallStr(message) : fallback);
    }
  }
}
