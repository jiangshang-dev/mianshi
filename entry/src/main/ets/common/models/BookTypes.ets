import { mallNum, mallStr } from './MallTypes';

export interface BookCategory {
  id?: string;
  name?: string;
  icon?: string;
  intro?: string;
  bookCount?: number;
}

export interface BookItem {
  id?: string;
  categoryId?: string;
  categoryName?: string;
  title?: string;
  subtitle?: string;
  authorName?: string;
  coverUrl?: string;
  quoteText?: string;
  tag?: string;
  pageCount?: number;
  viewCount?: number;
  likeCount?: number;
  recommend?: boolean;
  featured?: boolean;
  lastPage?: number;
  percent?: number;
  fileUrl?: string;
}

export interface BookHome {
  continueReading?: BookItem;
  categories?: BookCategory[];
  weekly?: BookItem[];
  featured?: BookItem[];
}

export interface BookItemPage {
  records?: BookItem[];
  total?: number;
}

export interface BookTocItem {
  title: string;
  pageIndex: number;
  level: number;
}

export interface JeecgBookMsgResp {
  success?: boolean;
  message?: string;
  code?: number;
}

export interface JeecgBookCategoryListResp {
  success?: boolean;
  message?: string;
  result?: BookCategory[];
  code?: number;
}

export interface JeecgBookHomeResp {
  success?: boolean;
  message?: string;
  result?: BookHome;
  code?: number;
}

export interface JeecgBookPageResp {
  success?: boolean;
  message?: string;
  result?: BookItemPage;
  code?: number;
}

export interface JeecgBookItemResp {
  success?: boolean;
  message?: string;
  result?: BookItem;
  code?: number;
}

export function bookBool(value?: boolean): boolean {
  if (value === undefined) {
    return false;
  }
  return value === true;
}

export function copyBookCategory(raw: BookCategory): BookCategory {
  const item: BookCategory = {
    id: mallStr(raw.id),
    name: mallStr(raw.name),
    icon: mallStr(raw.icon),
    intro: mallStr(raw.intro),
    bookCount: mallNum(raw.bookCount)
  };
  return item;
}

export function copyBookItem(raw: BookItem): BookItem {
  const item: BookItem = {
    id: mallStr(raw.id),
    categoryId: mallStr(raw.categoryId),
    categoryName: mallStr(raw.categoryName),
    title: mallStr(raw.title),
    subtitle: mallStr(raw.subtitle),
    authorName: mallStr(raw.authorName),
    coverUrl: mallStr(raw.coverUrl),
    quoteText: mallStr(raw.quoteText),
    tag: mallStr(raw.tag),
    pageCount: mallNum(raw.pageCount),
    viewCount: mallNum(raw.viewCount),
    likeCount: mallNum(raw.likeCount),
    recommend: bookBool(raw.recommend),
    featured: bookBool(raw.featured),
    lastPage: mallNum(raw.lastPage, -1),
    percent: mallNum(raw.percent),
    fileUrl: mallStr(raw.fileUrl)
  };
  return item;
}

export function copyBookHome(raw: BookHome): BookHome {
  const cats: BookCategory[] = [];
  const weekly: BookItem[] = [];
  const featured: BookItem[] = [];
  const rawCats = raw.categories;
  if (rawCats !== undefined) {
    for (let i = 0; i < rawCats.length; i++) {
      cats.push(copyBookCategory(rawCats[i]));
    }
  }
  const rawWeekly = raw.weekly;
  if (rawWeekly !== undefined) {
    for (let i = 0; i < rawWeekly.length; i++) {
      weekly.push(copyBookItem(rawWeekly[i]));
    }
  }
  const rawFeatured = raw.featured;
  if (rawFeatured !== undefined) {
    for (let i = 0; i < rawFeatured.length; i++) {
      featured.push(copyBookItem(rawFeatured[i]));
    }
  }
  const home: BookHome = {
    continueReading: raw.continueReading !== undefined ? copyBookItem(raw.continueReading) : undefined,
    categories: cats,
    weekly: weekly,
    featured: featured
  };
  return home;
}
