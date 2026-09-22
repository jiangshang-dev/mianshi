import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { HttpClient } from '../network/HttpClient';
import { BookBookmark } from '../models/BookTypes';
import { mallNum } from '../models/MallTypes';

const PREF_NAME = 'book_progress';
const BOOKMARK_PREF = 'book_bookmarks';

export interface LocalBookProgress {
  pageIndex: number;
  pageCount: number;
  percent: number;
}

export class BookCache {
  static async ensureFile(ctx: common.UIAbilityContext, bookId: string, fileUrl: string): Promise<string> {
    const dir = `${ctx.filesDir}/books`;
    try {
      fileIo.mkdirSync(dir, true);
    } catch (_e) {
    }
    const dest = `${dir}/${bookId}.book`;
    const meta = `${dir}/${bookId}.src`;
    if (BookCache.fileExists(dest) && BookCache.readText(meta) === fileUrl) {
      return dest;
    }
    const ok = await HttpClient.downloadToFile(fileUrl, dest);
    if (!ok) {
      throw new Error('open_fail');
    }
    BookCache.writeText(meta, fileUrl);
    return dest;
  }

  static copyFile(src: string, dest: string): boolean {
    // 优先系统拷贝，避免整文件进内存
    try {
      fileIo.copyFileSync(src, dest);
      return true;
    } catch (_e) {
    }
    // 分块读写兜底
    try {
      const srcFile = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      try {
        const destFile = fileIo.openSync(dest,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          const bufSize = 1024 * 1024;
          const buffer = new ArrayBuffer(bufSize);
          let offset = 0;
          let len = fileIo.readSync(srcFile.fd, buffer, { offset: offset, length: bufSize });
          while (len > 0) {
            fileIo.writeSync(destFile.fd, buffer, { length: len });
            offset += len;
            len = fileIo.readSync(srcFile.fd, buffer, { offset: offset, length: bufSize });
          }
        } finally {
          fileIo.closeSync(destFile);
        }
      } finally {
        fileIo.closeSync(srcFile);
      }
      return true;
    } catch (_e) {
      return false;
    }
  }

  static removeFile(path: string): void {
    try {
      fileIo.unlinkSync(path);
    } catch (_e) {
    }
  }

  static async loadProgress(ctx: common.UIAbilityContext, bookId: string): Promise<LocalBookProgress> {
    const empty: LocalBookProgress = { pageIndex: 0, pageCount: 0, percent: 0 };
    try {
      const store = await preferences.getPreferences(ctx, PREF_NAME);
      const raw = await store.get(bookId, '') as string;
      if (raw.length === 0) {
        return empty;
      }
      const parsed = JSON.parse(raw) as LocalBookProgress;
      return {
        pageIndex: mallNum(parsed.pageIndex),
        pageCount: mallNum(parsed.pageCount),
        percent: mallNum(parsed.percent)
      };
    } catch (_e) {
      return empty;
    }
  }

  static async saveProgress(ctx: common.UIAbilityContext, bookId: string, pageIndex: number, pageCount: number): Promise<void> {
    const percent = pageCount <= 0 ? 0 : Math.min(100, Math.round((pageIndex + 1) * 100 / pageCount));
    const payload: LocalBookProgress = { pageIndex: pageIndex, pageCount: pageCount, percent: percent };
    try {
      const store = await preferences.getPreferences(ctx, PREF_NAME);
      await store.put(bookId, JSON.stringify(payload));
      await store.flush();
    } catch (_e) {
    }
  }

  static async loadBookmarks(ctx: common.UIAbilityContext, bookId: string): Promise<BookBookmark[]> {
    try {
      const store = await preferences.getPreferences(ctx, BOOKMARK_PREF);
      const raw = await store.get(bookId, '') as string;
      if (raw.length === 0) {
        return [];
      }
      const parsed = JSON.parse(raw) as BookBookmark[];
      if (parsed === null || parsed === undefined) {
        return [];
      }
      const out: BookBookmark[] = [];
      for (let i = 0; i < parsed.length; i++) {
        const item = parsed[i];
        if (item === undefined || item === null) {
          continue;
        }
        const title = item.title !== undefined && item.title !== null ? `${item.title}` : '';
        const id = item.id !== undefined && item.id !== null ? `${item.id}` : '';
        if (id.length === 0) {
          continue;
        }
        out.push({
          id: id,
          title: title.length > 0 ? title : `P${mallNum(item.pageIndex) + 1}`,
          pageIndex: mallNum(item.pageIndex),
          createdAt: mallNum(item.createdAt)
        });
      }
      return out;
    } catch (_e) {
      return [];
    }
  }

  static async saveBookmarks(ctx: common.UIAbilityContext, bookId: string, list: BookBookmark[]): Promise<void> {
    try {
      const store = await preferences.getPreferences(ctx, BOOKMARK_PREF);
      await store.put(bookId, JSON.stringify(list));
      await store.flush();
    } catch (_e) {
    }
  }

  static async addBookmark(ctx: common.UIAbilityContext, bookId: string, title: string, pageIndex: number): Promise<BookBookmark[]> {
    const list = await BookCache.loadBookmarks(ctx, bookId);
    const name = title.trim().length > 0 ? title.trim() : `P${pageIndex + 1}`;
    // 同页已有则更新标题
    for (let i = 0; i < list.length; i++) {
      if (list[i].pageIndex === pageIndex) {
        list[i].title = name;
        list[i].createdAt = Date.now();
        await BookCache.saveBookmarks(ctx, bookId, list);
        return list;
      }
    }
    const item: BookBookmark = {
      id: `${Date.now()}_${pageIndex}`,
      title: name.slice(0, 48),
      pageIndex: pageIndex,
      createdAt: Date.now()
    };
    list.unshift(item);
    // 单书最多 100 条
    while (list.length > 100) {
      list.pop();
    }
    await BookCache.saveBookmarks(ctx, bookId, list);
    return list;
  }

  static async removeBookmark(ctx: common.UIAbilityContext, bookId: string, id: string): Promise<BookBookmark[]> {
    const list = await BookCache.loadBookmarks(ctx, bookId);
    const next: BookBookmark[] = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].id !== id) {
        next.push(list[i]);
      }
    }
    await BookCache.saveBookmarks(ctx, bookId, next);
    return next;
  }

  private static fileExists(path: string): boolean {
    try {
      fileIo.accessSync(path);
      return true;
    } catch (_e) {
      return false;
    }
  }

  private static readText(path: string): string {
    try {
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      try {
        const stat = fileIo.statSync(file.fd);
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(file.fd, buffer);
        const arr = new Uint8Array(buffer);
        let text = '';
        for (let i = 0; i < arr.length; i++) {
          text += String.fromCharCode(arr[i]);
        }
        return text;
      } finally {
        fileIo.closeSync(file);
      }
    } catch (_e) {
      return '';
    }
  }

  private static writeText(path: string, text: string): void {
    try {
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        const bytes = new Uint8Array(text.length);
        for (let i = 0; i < text.length; i++) {
          bytes[i] = text.charCodeAt(i);
        }
        fileIo.writeSync(file.fd, bytes.buffer);
      } finally {
        fileIo.closeSync(file);
      }
    } catch (_e) {
    }
  }
}
