import { HttpClient } from '../../common/network/HttpClient';
import {
  GlobalSearchHit,
  GlobalSearchResult,
  JeecgGlobalSearchResp,
  copyGlobalSearch
} from '../../common/models/SearchTypes';
import { mallStr } from '../../common/models/MallTypes';

/**
 * App 首页全局搜索仓库：走 Jeecg /api/search（ES）
 */
export class GlobalSearchRepository {
  private static instance: GlobalSearchRepository | null = null;

  static getInstance(): GlobalSearchRepository {
    if (!GlobalSearchRepository.instance) {
      GlobalSearchRepository.instance = new GlobalSearchRepository();
    }
    return GlobalSearchRepository.instance;
  }

  /**
   * 按关键词搜索题目/图书/专栏/广场
   */
  async search(keyword: string): Promise<GlobalSearchResult> {
    // 拼查询参数
    const query = `keyword=${encodeURIComponent(keyword)}&size=30`;
    // 调后端全局搜索
    const resp = await HttpClient.get('/api/search', query);
    // 解析 Jeecg Result
    const parsed: JeecgGlobalSearchResp = JSON.parse(resp.body) as JeecgGlobalSearchResp;
    // 失败抛错给页面
    if (resp.ok === false || parsed.success === false) {
      throw new Error(mallStr(parsed.message).length > 0 ? mallStr(parsed.message) : '搜索失败');
    }
    // 空结果兜底
    if (parsed.result === undefined) {
      const empty: GlobalSearchResult = {
        keyword: keyword,
        all: [],
        questions: [],
        books: [],
        blogs: [],
        forums: []
      };
      return empty;
    }
    return copyGlobalSearch(parsed.result);
  }

  /**
   * 按当前 Tab 取列表
   */
  static listOf(result: GlobalSearchResult, tab: string): GlobalSearchHit[] {
    if (tab === 'question') {
      return result.questions !== undefined ? result.questions : [];
    }
    if (tab === 'book') {
      return result.books !== undefined ? result.books : [];
    }
    if (tab === 'blog') {
      return result.blogs !== undefined ? result.blogs : [];
    }
    if (tab === 'forum') {
      return result.forums !== undefined ? result.forums : [];
    }
    return result.all !== undefined ? result.all : [];
  }
}
