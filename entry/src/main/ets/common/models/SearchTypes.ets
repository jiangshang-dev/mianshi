import { mallStr } from './MallTypes';

/** 全局搜索单条命中 */
export interface GlobalSearchHit {
  id?: string;
  type?: string;
  typeLabel?: string;
  title?: string;
  summary?: string;
  categoryName?: string;
  coverUrl?: string;
  authorName?: string;
}

/** 全局搜索分组结果 */
export interface GlobalSearchResult {
  keyword?: string;
  all?: GlobalSearchHit[];
  questions?: GlobalSearchHit[];
  books?: GlobalSearchHit[];
  blogs?: GlobalSearchHit[];
  forums?: GlobalSearchHit[];
}

export interface JeecgGlobalSearchResp {
  success?: boolean;
  message?: string;
  result?: GlobalSearchResult;
  code?: number;
}

export function copySearchHit(raw: GlobalSearchHit): GlobalSearchHit {
  const item: GlobalSearchHit = {
    id: mallStr(raw.id),
    type: mallStr(raw.type),
    typeLabel: mallStr(raw.typeLabel),
    title: mallStr(raw.title),
    summary: mallStr(raw.summary),
    categoryName: mallStr(raw.categoryName),
    coverUrl: mallStr(raw.coverUrl),
    authorName: mallStr(raw.authorName)
  };
  return item;
}

export function copyGlobalSearch(raw: GlobalSearchResult): GlobalSearchResult {
  const mapList = (src?: GlobalSearchHit[]): GlobalSearchHit[] => {
    const out: GlobalSearchHit[] = [];
    if (src === undefined) {
      return out;
    }
    for (let i = 0; i < src.length; i++) {
      out.push(copySearchHit(src[i]));
    }
    return out;
  };
  const result: GlobalSearchResult = {
    keyword: mallStr(raw.keyword),
    all: mapList(raw.all),
    questions: mapList(raw.questions),
    books: mapList(raw.books),
    blogs: mapList(raw.blogs),
    forums: mapList(raw.forums)
  };
  return result;
}
