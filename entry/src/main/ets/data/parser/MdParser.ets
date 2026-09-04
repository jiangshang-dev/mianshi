import { HtmlCompat } from './HtmlCompat';

export interface MdFrontMatter {
  title: string;
  description: string;
  category: string;
  tags: string[];
}

export interface ParsedMarkdown {
  frontMatter: MdFrontMatter;
  body: string;
}

export interface MdSection {
  title: string;
  level: number;
  content: string;
}

export class MdParser {
  static parse(raw: string): ParsedMarkdown {
    const empty: MdFrontMatter = { title: '', description: '', category: '', tags: [] };
    if (!raw.startsWith('---')) {
      return { frontMatter: empty, body: raw };
    }
    const end = raw.indexOf('\n---', 3);
    if (end < 0) {
      return { frontMatter: empty, body: raw };
    }
    const fmBlock = raw.substring(3, end).trim();
    const body = raw.substring(end + 4).replace(/^\n+/, '');
    return { frontMatter: MdParser.parseFrontMatter(fmBlock), body };
  }

  private static parseFrontMatter(block: string): MdFrontMatter {
    const result: MdFrontMatter = { title: '', description: '', category: '', tags: [] };
    const lines = block.split('\n');
    let inTags = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (line.startsWith('title:')) {
        result.title = line.substring(6).trim().replace(/^['"]|['"]$/g, '');
        inTags = false;
      } else if (line.startsWith('description:')) {
        result.description = line.substring(12).trim().replace(/^['"]|['"]$/g, '');
        inTags = false;
      } else if (line.startsWith('category:')) {
        result.category = line.substring(9).trim().replace(/^['"]|['"]$/g, '');
        inTags = false;
      } else if (line.startsWith('tag:')) {
        inTags = true;
      } else if (inTags && line.trim().startsWith('-')) {
        result.tags.push(line.trim().substring(1).trim());
      } else if (line.length > 0 && !line.startsWith(' ') && !line.startsWith('-')) {
        inTags = false;
      }
    }
    return result;
  }

  static splitSections(body: string): MdSection[] {
    const lines = body.split('\n');
    const sections: MdSection[] = [];
    let current: MdSection | null = null;
    const contentLines: string[] = [];
    const flush = () => {
      if (current) {
        current.content = contentLines.join('\n').trim();
        sections.push(current);
      }
      contentLines.length = 0;
    };
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const h3 = line.match(/^###\s+(.+)$/);
      const h2 = line.match(/^##\s+(.+)$/);
      if (h3) {
        flush();
        current = { title: MdParser.cleanHeading(h3[1]), level: 3, content: '' };
      } else if (h2) {
        flush();
        current = { title: MdParser.cleanHeading(h2[1]), level: 2, content: '' };
      } else if (current) {
        contentLines.push(line);
      }
    }
    flush();
    return sections;
  }

  static cleanHeading(title: string): string {
    return title.replace(/[⭐️🌈🐛*`#]/g, '').trim();
  }

  static toPlainReadable(md: string): string {
    let text = md;
    text = text.replace(/```[\w]*\n([\s\S]*?)```/g, '\n$1\n');
    text = text.replace(/!\[([^\]]*)\]\([^)]+\)/g, '');
    text = text.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
    text = text.replace(/^#{1,6}\s+/gm, '');
    text = text.replace(/\*\*([^*]+)\*\*/g, '$1');
    text = text.replace(/\*([^*]+)\*/g, '$1');
    text = text.replace(/`([^`]+)`/g, '$1');
    text = text.replace(/^>\s?/gm, '');
    text = text.replace(/^\s*[-*]\s+/gm, '• ');
    text = text.replace(/\n{3,}/g, '\n\n');
    return text.trim();
  }
}

export interface MdInlineSpan {
  text: string;
  bold: boolean;
  italic: boolean;
  code: boolean;
}

export interface MdTableCell {
  inlines: MdInlineSpan[];
}

export interface MdTableRow {
  cells: MdTableCell[];
}

export interface MdTextChunk {
  kind: string;
  text: string;
  src: string;
}

export interface MdBlockNode {
  kind: string;
  inlines: MdInlineSpan[];
  code: string;
  bullet: string;
  src: string;
  rows: MdTableRow[];
}

export class MdBlocks {
  static parse(md: string): MdBlockNode[] {
    const source = HtmlCompat.toMarkdown(md);
    const lines = source.split('\r\n').join('\n').split('\r').join('\n').split('\n');
    const blocks: MdBlockNode[] = [];
    let i = 0;
    while (i < lines.length) {
      const raw = lines[i];
      const trimmed = raw.trim();
      if (trimmed.length === 0) {
        i++;
        continue;
      }
      if (trimmed.startsWith('```')) {
        const codeLines: string[] = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.push(lines[i]);
          i++;
        }
        if (i < lines.length) {
          i++;
        }
        blocks.push(MdBlocks.node('code', [], codeLines.join('\n'), ''));
        continue;
      }
      if (trimmed === '---' || trimmed === '***' || trimmed === '___') {
        blocks.push(MdBlocks.node('hr', [], '', ''));
        i++;
        continue;
      }
      const heading = MdBlocks.headingLevel(trimmed);
      if (heading > 0) {
        const title = trimmed.replace(/^#{1,6}\s+/, '');
        const kind = heading <= 1 ? 'h1' : (heading === 2 ? 'h2' : 'h3');
        blocks.push(MdBlocks.node(kind, MdBlocks.parseInlines(title), '', ''));
        i++;
        continue;
      }
      const imgSrc = MdBlocks.lineImageSrc(trimmed);
      if (imgSrc.length > 0) {
        blocks.push(MdBlocks.imageNode(imgSrc));
        i++;
        continue;
      }
      if (MdBlocks.isTableRow(trimmed)) {
        const tableLines: string[] = [];
        while (i < lines.length && MdBlocks.isTableRow(lines[i].trim())) {
          tableLines.push(lines[i].trim());
          i++;
        }
        const rows = MdBlocks.parseTable(tableLines);
        if (rows.length > 0) {
          blocks.push(MdBlocks.tableNode(rows));
        }
        continue;
      }
      if (trimmed.startsWith('>')) {
        const quoteLines: string[] = [];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quoteLines.push(lines[i].trim().replace(/^>\s?/, ''));
          i++;
        }
        const text = quoteLines.join('\n');
        blocks.push(MdBlocks.node('quote', MdBlocks.parseInlines(text), '', ''));
        continue;
      }
      const ulBullet = MdBlocks.unorderedBullet(trimmed);
      if (ulBullet.length > 0) {
        while (i < lines.length && MdBlocks.unorderedBullet(lines[i].trim()).length > 0) {
          const item = MdBlocks.unorderedBullet(lines[i].trim());
          blocks.push(MdBlocks.node('li', MdBlocks.parseInlines(item), '', '•'));
          i++;
        }
        continue;
      }
      const olItem = MdBlocks.orderedItem(trimmed);
      if (olItem.length > 0) {
        while (i < lines.length) {
          const next = MdBlocks.orderedItem(lines[i].trim());
          if (next.length === 0) {
            break;
          }
          const num = lines[i].trim().match(/^(\d+)\.\s+/);
          const bullet = num ? `${num[1]}.` : '•';
          blocks.push(MdBlocks.node('li', MdBlocks.parseInlines(next), '', bullet));
          i++;
        }
        continue;
      }
      const para: string[] = [];
      while (i < lines.length) {
        const t = lines[i].trim();
        if (t.length === 0 || t.startsWith('```') || MdBlocks.headingLevel(t) > 0
          || t.startsWith('>') || MdBlocks.unorderedBullet(t).length > 0
          || MdBlocks.orderedItem(t).length > 0 || MdBlocks.isTableRow(t)
          || MdBlocks.lineImageSrc(t).length > 0) {
          break;
        }
        para.push(lines[i]);
        i++;
      }
      MdBlocks.flushParagraph(para.join('\n'), blocks);
    }
    return blocks;
  }

  static parseInlines(raw: string): MdInlineSpan[] {
    let s = raw;
    s = s.replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1');
    s = s.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1');
    const result: MdInlineSpan[] = [];
    let bold = false;
    let italic = false;
    let code = false;
    let buf = '';
    const flush = (): void => {
      if (buf.length === 0) {
        return;
      }
      result.push({ text: buf, bold: bold, italic: italic, code: code });
      buf = '';
    };
    let i = 0;
    while (i < s.length) {
      if (!code && s.substring(i, i + 2) === '**') {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
      if (!code && s.substring(i, i + 2) === '__') {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
      if (s.charAt(i) === '`') {
        flush();
        code = !code;
        i += 1;
        continue;
      }
      if (!code && s.charAt(i) === '*' && (i + 1 >= s.length || s.charAt(i + 1) !== '*')) {
        flush();
        italic = !italic;
        i += 1;
        continue;
      }
      buf += s.charAt(i);
      i += 1;
    }
    flush();
    if (result.length === 0) {
      result.push({ text: s, bold: false, italic: false, code: false });
    }
    return result;
  }

  private static node(kind: string, inlines: MdInlineSpan[], code: string, bullet: string): MdBlockNode {
    return { kind: kind, inlines: inlines, code: code, bullet: bullet, src: '', rows: [] };
  }

  private static imageNode(src: string): MdBlockNode {
    return { kind: 'img', inlines: [], code: '', bullet: '', src: src, rows: [] };
  }

  private static tableNode(rows: MdTableRow[]): MdBlockNode {
    return { kind: 'table', inlines: [], code: '', bullet: '', src: '', rows: rows };
  }

  /** 整行就是一张图：Markdown / HTML / 裸图片地址 */
  static lineImageSrc(line: string): string {
    const t = line.trim();
    if (t.length === 0) {
      return '';
    }
    if (t.startsWith('![') && t.indexOf('](') > 1) {
      const rb = t.indexOf('](');
      const close = t.lastIndexOf(')');
      if (close > rb + 2 && close === t.length - 1) {
        return MdBlocks.cleanImageSrc(t.substring(rb + 2, close));
      }
      const raw = t.substring(rb + 2);
      const src = MdBlocks.cleanImageSrc(raw.endsWith(')') ? raw.substring(0, raw.length - 1) : raw);
      if (src.indexOf('http://') === 0 || src.indexOf('https://') === 0) {
        return src;
      }
    }
    const lower = t.toLowerCase();
    if (lower.startsWith('<img')) {
      return MdBlocks.htmlImgSrc(t);
    }
    if (MdBlocks.isBareImageUrl(t)) {
      return t;
    }
    return '';
  }

  static isTableRow(line: string): boolean {
    const t = line.trim();
    if (t.length < 3 || !t.startsWith('|')) {
      return false;
    }
    return t.indexOf('|', 1) > 0;
  }

  static parseTable(lines: string[]): MdTableRow[] {
    const rows: MdTableRow[] = [];
    let colCount = 0;
    for (let i = 0; i < lines.length; i++) {
      if (MdBlocks.isTableSep(lines[i])) {
        continue;
      }
      const cells = MdBlocks.splitTableCells(lines[i]);
      if (cells.length > colCount) {
        colCount = cells.length;
      }
      const rowCells: MdTableCell[] = [];
      for (let c = 0; c < cells.length; c++) {
        rowCells.push({ inlines: MdBlocks.parseInlines(cells[c]) });
      }
      rows.push({ cells: rowCells });
    }
    for (let r = 0; r < rows.length; r++) {
      while (rows[r].cells.length < colCount) {
        rows[r].cells.push({ inlines: [{ text: '', bold: false, italic: false, code: false }] });
      }
    }
    return rows;
  }

  private static isTableSep(line: string): boolean {
    const t = line.trim().split(' ').join('');
    if (!t.startsWith('|')) {
      return false;
    }
    let inner = t;
    if (inner.startsWith('|')) {
      inner = inner.substring(1);
    }
    if (inner.endsWith('|')) {
      inner = inner.substring(0, inner.length - 1);
    }
    const parts = inner.split('|');
    if (parts.length === 0) {
      return false;
    }
    for (let i = 0; i < parts.length; i++) {
      if (!/^:?-{3,}:?$/.test(parts[i])) {
        return false;
      }
    }
    return true;
  }

  private static splitTableCells(line: string): string[] {
    let t = line.trim();
    if (t.startsWith('|')) {
      t = t.substring(1);
    }
    if (t.endsWith('|')) {
      t = t.substring(0, t.length - 1);
    }
    const raw = t.split('|');
    const cells: string[] = [];
    for (let i = 0; i < raw.length; i++) {
      cells.push(raw[i].trim());
    }
    return cells;
  }

  private static flushParagraph(text: string, blocks: MdBlockNode[]): void {
    if (text.trim().length === 0) {
      return;
    }
    const chunks = MdBlocks.splitImages(text);
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      if (chunk.kind === 'img' && chunk.src.length > 0) {
        blocks.push(MdBlocks.imageNode(chunk.src));
      } else if (chunk.text.trim().length > 0) {
        blocks.push(MdBlocks.node('p', MdBlocks.parseInlines(chunk.text), '', ''));
      }
    }
  }

  private static splitImages(text: string): MdTextChunk[] {
    const out: MdTextChunk[] = [];
    let i = 0;
    let buf = '';
    const flushText = (): void => {
      if (buf.length > 0) {
        out.push({ kind: 'text', text: buf, src: '' });
        buf = '';
      }
    };
    while (i < text.length) {
      if (text.substring(i, i + 2) === '![') {
        const rb = text.indexOf('](', i + 2);
        if (rb > i) {
          const close = text.indexOf(')', rb + 2);
          if (close > rb) {
            const src = MdBlocks.cleanImageSrc(text.substring(rb + 2, close));
            if (src.length > 0) {
              flushText();
              out.push({ kind: 'img', text: '', src: src });
              i = close + 1;
              continue;
            }
          } else {
            const src = MdBlocks.cleanImageSrc(text.substring(rb + 2).trim());
            if (src.indexOf('http://') === 0 || src.indexOf('https://') === 0) {
              flushText();
              out.push({ kind: 'img', text: '', src: src });
              i = text.length;
              continue;
            }
          }
        }
      }
      if (text.substring(i, i + 8) === 'https://' || text.substring(i, i + 7) === 'http://') {
        let end = i;
        while (end < text.length && !MdBlocks.isUrlEnd(text.charAt(end))) {
          end++;
        }
        const url = text.substring(i, end);
        if (MdBlocks.isBareImageUrl(url)) {
          flushText();
          out.push({ kind: 'img', text: '', src: url });
          i = end;
          continue;
        }
      }
      buf += text.charAt(i);
      i++;
    }
    flushText();
    return out;
  }

  private static cleanImageSrc(raw: string): string {
    let src = raw.trim();
    const space = src.indexOf(' ');
    if (space > 0) {
      src = src.substring(0, space);
    }
    if ((src.startsWith('"') && src.endsWith('"')) || (src.startsWith("'") && src.endsWith("'"))) {
      src = src.substring(1, src.length - 1);
    }
    return src;
  }

  private static htmlImgSrc(tag: string): string {
    const lower = tag.toLowerCase();
    const key = 'src=';
    const at = lower.indexOf(key);
    if (at < 0) {
      return '';
    }
    let i = at + key.length;
    while (i < tag.length && tag.charAt(i) === ' ') {
      i++;
    }
    if (i >= tag.length) {
      return '';
    }
    const q = tag.charAt(i);
    if (q === '"' || q === "'") {
      const end = tag.indexOf(q, i + 1);
      return end > i ? MdBlocks.cleanImageSrc(tag.substring(i + 1, end)) : '';
    }
    let end = i;
    while (end < tag.length && tag.charAt(end) !== ' ' && tag.charAt(end) !== '>') {
      end++;
    }
    return MdBlocks.cleanImageSrc(tag.substring(i, end));
  }

  static isBareImageUrl(t: string): boolean {
    const lower = t.toLowerCase();
    if (lower.indexOf('http://') !== 0 && lower.indexOf('https://') !== 0) {
      return false;
    }
    let path = t;
    const hash = path.indexOf('#');
    if (hash > 0) {
      path = path.substring(0, hash);
    }
    const query = path.indexOf('?');
    if (query > 0) {
      path = path.substring(0, query);
    }
    const dot = path.lastIndexOf('.');
    if (dot < 0 || dot < path.lastIndexOf('/')) {
      return false;
    }
    const ext = path.substring(dot).toLowerCase();
    return ext === '.png' || ext === '.jpg' || ext === '.jpeg' || ext === '.gif'
      || ext === '.webp' || ext === '.bmp' || ext === '.svg';
  }

  private static isUrlEnd(ch: string): boolean {
    return ch === ' ' || ch === '\n' || ch === '\t' || ch === ')' || ch === ']' || ch === '<'
      || ch === '"' || ch === "'" || ch === '>';
  }

  private static headingLevel(line: string): number {
    if (line.startsWith('###### ')) {
      return 6;
    }
    if (line.startsWith('##### ')) {
      return 5;
    }
    if (line.startsWith('#### ')) {
      return 4;
    }
    if (line.startsWith('### ')) {
      return 3;
    }
    if (line.startsWith('## ')) {
      return 2;
    }
    if (line.startsWith('# ')) {
      return 1;
    }
    return 0;
  }

  private static unorderedBullet(line: string): string {
    if (line.startsWith('- ')) {
      return line.substring(2);
    }
    if (line.startsWith('* ')) {
      return line.substring(2);
    }
    if (line.startsWith('+ ')) {
      return line.substring(2);
    }
    return '';
  }

  private static orderedItem(line: string): string {
    const m = line.match(/^(\d+)\.\s+(.*)$/);
    return m ? m[2] : '';
  }
}
