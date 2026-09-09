import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { HttpClient } from '../../common/network/HttpClient';
import { mallNum } from '../../common/models/MallTypes';

const PREF_NAME = 'book_progress';

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
    try {
      const srcFile = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      try {
        const stat = fileIo.statSync(srcFile.fd);
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(srcFile.fd, buffer);
        const destFile = fileIo.openSync(dest,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(destFile.fd, buffer);
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
