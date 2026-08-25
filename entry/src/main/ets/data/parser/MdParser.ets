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
