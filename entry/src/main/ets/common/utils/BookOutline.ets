import { pdfService } from '@kit.PDFKit';
import { BookTocItem } from '../models/BookTypes';

export class BookOutline {
  static load(path: string, pageLabel: (pageNo: number) => string): BookTocItem[] {
    const items: BookTocItem[] = [];
    const doc: pdfService.PdfDocument = new pdfService.PdfDocument();
    try {
      const result = doc.loadDocument(path);
      if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
        return items;
      }
      BookOutline.collectBookmarks(doc, items);
      if (items.length === 0) {
        BookOutline.collectPageTitles(doc, items, pageLabel);
      }
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
      if (mark.hasChild()) {
        const kids = mark.getChildren();
        for (let i = 0; i < kids.length; i++) {
          BookOutline.walkBookmark(kids[i], level + 1, out);
        }
      }
    } catch (_e) {
    }
  }

  private static collectPageTitles(doc: pdfService.PdfDocument, out: BookTocItem[],
    pageLabel: (pageNo: number) => string): void {
    let count = 0;
    try {
      count = doc.getPageCount();
    } catch (_e) {
      return;
    }
    for (let i = 0; i < count; i++) {
      let title = '';
      try {
        const page = doc.getPage(i);
        try {
          title = BookOutline.pageHeading(page);
        } finally {
          page.release();
        }
      } catch (_e) {
      }
      if (title.length === 0) {
        title = pageLabel(i + 1);
      }
      const item: BookTocItem = { title: title, pageIndex: i, level: 0 };
      out.push(item);
    }
  }

  private static pageHeading(page: pdfService.PdfPage): string {
    let best = '';
    let bestScore = -1;
    try {
      const objs = page.getGraphicsObjects();
      const limit = objs.length > 48 ? 48 : objs.length;
      for (let i = 0; i < limit; i++) {
        const obj = objs[i];
        if (obj.type !== pdfService.GraphicsObjectType.OBJECT_TEXT) {
          continue;
        }
        const textObj = obj as pdfService.TextObject;
        const title = BookOutline.cleanTitle(textObj.text);
        if (title.length < 2) {
          continue;
        }
        const score = textObj.textSize * 1000 + textObj.y;
        if (score > bestScore) {
          bestScore = score;
          best = title;
        }
      }
    } catch (_e) {
    }
    return best;
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
      if (out.length >= 36) {
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
