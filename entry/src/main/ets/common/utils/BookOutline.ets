import { pdfService } from '@kit.PDFKit';
import { BookTocItem } from '../models/BookTypes';

/**
 * 只解析 PDF 书签大纲。
 * 大 PDF 禁止逐页扫文字标题（会卡死/OOM）。
 */
export class BookOutline {
  static load(path: string, _pageLabel: (pageNo: number) => string): BookTocItem[] {
    const items: BookTocItem[] = [];
    const doc: pdfService.PdfDocument = new pdfService.PdfDocument();
    try {
      const result = doc.loadDocument(path);
      if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
        return items;
      }
      BookOutline.collectBookmarks(doc, items);
    } catch (_e) {
    } finally {
      try {
        doc.releaseDocument();
      } catch (_e) {
      }
    }
    return items;
  }

  private static collectBookmarks(doc: pdfService.PdfDocument, out: BookTocItem[]): void {
    try {
      const roots = doc.getRootBookmarks();
      if (roots !== undefined && roots.length > 0) {
        for (let i = 0; i < roots.length; i++) {
          BookOutline.walkBookmark(roots[i], 0, out);
        }
        if (out.length > 0) {
          return;
        }
      }
    } catch (_e) {
    }
    try {
      const root = doc.getRootBookmark();
      if (root !== undefined && root.hasChild()) {
        const kids = root.getChildren();
        for (let i = 0; i < kids.length; i++) {
          BookOutline.walkBookmark(kids[i], 0, out);
        }
      }
    } catch (_e) {
    }
  }

  private static walkBookmark(mark: pdfService.Bookmark, level: number, out: BookTocItem[]): void {
    try {
      const info = mark.getBookmarkInfo();
      const dest = mark.getDestInfo();
      const title = BookOutline.cleanTitle(info !== undefined ? info.title : '');
      let page = dest !== undefined ? dest.pageIndex : 0;
      if (page < 0) {
        page = 0;
      }
      if (title.length > 0) {
        const item: BookTocItem = { title: title, pageIndex: page, level: level };
        out.push(item);
      }
      if (out.length >= 800) {
        return;
      }
      if (level < 6 && mark.hasChild()) {
        const kids = mark.getChildren();
        for (let i = 0; i < kids.length; i++) {
          BookOutline.walkBookmark(kids[i], level + 1, out);
          if (out.length >= 800) {
            return;
          }
        }
      }
    } catch (_e) {
    }
  }

  private static cleanTitle(raw: string): string {
    if (raw === undefined || raw.length === 0) {
      return '';
    }
    let out = '';
    let space = false;
    for (let i = 0; i < raw.length; i++) {
      const ch = raw.charAt(i);
      const code = raw.charCodeAt(i);
      if (code <= 32) {
        space = true;
        continue;
      }
      if (space && out.length > 0) {
        out += ' ';
      }
      space = false;
      out += ch;
      if (out.length >= 48) {
        break;
      }
    }
    const lower = out.toLowerCase();
    if (lower.indexOf('mianshiya') >= 0 || lower.indexOf('.pdf') >= 0) {
      return '';
    }
    return out;
  }
}
