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

export interface MdBlockNode {
  kind: string;
  inlines: MdInlineSpan[];
  code: string;
  bullet: string;
}

export class MdBlocks {
  static parse(md: string): MdBlockNode[] {
    const lines = md.split('\r\n').join('\n').split('\r').join('\n').split('\n');
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
          || MdBlocks.orderedItem(t).length > 0) {
          break;
        }
        para.push(lines[i]);
        i++;
      }
      const text = para.join('\n');
      if (text.length > 0) {
        blocks.push(MdBlocks.node('p', MdBlocks.parseInlines(text), '', ''));
      }
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
      result.push({ text: raw, bold: false, italic: false, code: false });
    }
    return result;
  }

  private static node(kind: string, inlines: MdInlineSpan[], code: string, bullet: string): MdBlockNode {
    return { kind: kind, inlines: inlines, code: code, bullet: bullet };
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
