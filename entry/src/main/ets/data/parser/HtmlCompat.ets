interface HtmlSlice {
  start: number;
  end: number;
  inner: string;
}

/** 把后台粘贴的 HTML（含 ChatGPT/编辑器代码块）转成 App 能渲染的 Markdown */
export class HtmlCompat {
  static toMarkdown(raw: string): string {
    if (raw.length === 0 || !HtmlCompat.hasHtml(raw)) {
      return raw;
    }
    let s = raw.split('\r\n').join('\n').split('\r').join('\n');
    s = HtmlCompat.replacePreBlocks(s);
    s = HtmlCompat.replaceInlines(s);
    s = HtmlCompat.stripTags(s);
    s = HtmlCompat.decodeEntities(s);
    return HtmlCompat.cleanNoise(s);
  }

  private static hasHtml(raw: string): boolean {
    const lower = raw.toLowerCase();
    return lower.indexOf('<pre') >= 0 || lower.indexOf('<div') >= 0 || lower.indexOf('<p>') >= 0
      || lower.indexOf('<p ') >= 0 || lower.indexOf('<br') >= 0 || lower.indexOf('<span') >= 0
      || lower.indexOf('<h1') >= 0 || lower.indexOf('<h2') >= 0 || lower.indexOf('<h3') >= 0
      || lower.indexOf('<ul') >= 0 || lower.indexOf('<ol') >= 0 || lower.indexOf('<li') >= 0
      || lower.indexOf('<code') >= 0 || lower.indexOf('<strong') >= 0 || lower.indexOf('<table') >= 0;
  }

  private static replacePreBlocks(s: string): string {
    let out = s;
    let guard = 0;
    while (guard < 40) {
      guard++;
      const found = HtmlCompat.extractFirst(out, 'pre');
      if (found.start < 0) {
        break;
      }
      let code = HtmlCompat.innermost(found.inner, 'code');
      if (code.length === 0) {
        code = found.inner;
      }
      code = HtmlCompat.stripTags(code);
      code = HtmlCompat.decodeEntities(code).trim();
      code = HtmlCompat.dropNoiseLines(code);
      const fence = `\n\n\`\`\`\n${code}\n\`\`\`\n\n`;
      out = out.substring(0, found.start) + fence + out.substring(found.end);
    }
    return out;
  }

  private static innermost(html: string, tag: string): string {
    let current = html;
    let last = '';
    let guard = 0;
    while (guard < 20) {
      guard++;
      const found = HtmlCompat.extractFirst(current, tag);
      if (found.start < 0) {
        break;
      }
      last = found.inner;
      current = found.inner;
    }
    return last;
  }

  private static extractFirst(html: string, tag: string): HtmlSlice {
    const miss: HtmlSlice = { start: -1, end: -1, inner: '' };
    const lower = html.toLowerCase();
    const start = HtmlCompat.indexOfOpen(lower, tag);
    if (start < 0) {
      return miss;
    }
    const afterOpen = html.indexOf('>', start);
    if (afterOpen < 0) {
      return miss;
    }
    const innerStart = afterOpen + 1;
    const open = '<' + tag;
    const close = '</' + tag;
    let depth = 1;
    let i = innerStart;
    while (i < lower.length && depth > 0) {
      const nextOpen = HtmlCompat.indexOfOpenFrom(lower, tag, i);
      const nextClose = lower.indexOf(close, i);
      if (nextClose < 0) {
        return {
          start: start,
          end: html.length,
          inner: html.substring(innerStart)
        };
      }
      if (nextOpen >= 0 && nextOpen < nextClose) {
        depth++;
        i = nextOpen + open.length;
      } else {
        depth--;
        if (depth === 0) {
          const closeEnd = html.indexOf('>', nextClose);
          const end = closeEnd >= 0 ? closeEnd + 1 : nextClose + close.length;
          return {
            start: start,
            end: end,
            inner: html.substring(innerStart, nextClose)
          };
        }
        i = nextClose + close.length;
      }
    }
    return miss;
  }

  private static indexOfOpen(lower: string, tag: string): number {
    return HtmlCompat.indexOfOpenFrom(lower, tag, 0);
  }

  private static indexOfOpenFrom(lower: string, tag: string, from: number): number {
    const key = '<' + tag;
    let i = from;
    while (i < lower.length) {
      const at = lower.indexOf(key, i);
      if (at < 0) {
        return -1;
      }
      const next = at + key.length;
      if (next >= lower.length) {
        return -1;
      }
      const ch = lower.charAt(next);
      if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '>' || ch === '/') {
        return at;
      }
      i = next;
    }
    return -1;
  }

  private static replaceInlines(s: string): string {
    let out = s;
    out = out.replace(/<br\s*\/?>/gi, '\n');
    out = out.replace(/<h1[^>]*>/gi, '\n# ');
    out = out.replace(/<h2[^>]*>/gi, '\n## ');
    out = out.replace(/<h3[^>]*>/gi, '\n### ');
    out = out.replace(/<\/h[1-6]>/gi, '\n');
    out = out.replace(/<\/p>/gi, '\n\n');
    out = out.replace(/<\/div>/gi, '\n');
    out = out.replace(/<li[^>]*>/gi, '\n- ');
    out = out.replace(/<\/li>/gi, '\n');
    out = out.replace(/<blockquote[^>]*>/gi, '\n> ');
    out = out.replace(/<\/blockquote>/gi, '\n');
    out = out.replace(/<(strong|b)(\s[^>]*)?>/gi, '**');
    out = out.replace(/<\/(strong|b)>/gi, '**');
    out = out.replace(/<(em|i)(\s[^>]*)?>/gi, '*');
    out = out.replace(/<\/(em|i)>/gi, '*');
    out = out.replace(/<code[^>]*>/gi, '`');
    out = out.replace(/<\/code>/gi, '`');
    out = out.replace(/<tr[^>]*>/gi, '\n');
    out = out.replace(/<\/t[dh]>/gi, '  ');
    return out;
  }

  private static stripTags(s: string): string {
    return s.replace(/<[^>]+>/g, '');
  }

  private static decodeEntities(s: string): string {
    let out = s;
    out = out.replace(/&nbsp;/gi, ' ');
    out = out.replace(/&lt;/gi, '<');
    out = out.replace(/&gt;/gi, '>');
    out = out.replace(/&quot;/gi, '"');
    out = out.replace(/&#39;/g, "'");
    out = out.replace(/&apos;/gi, "'");
    out = HtmlCompat.decodeNumeric(out);
    out = out.replace(/&amp;/gi, '&');
    return out;
  }

  private static decodeNumeric(s: string): string {
    let out = '';
    let i = 0;
    while (i < s.length) {
      if (s.substring(i, i + 2) === '&#') {
        const semi = s.indexOf(';', i + 2);
        if (semi > i + 2 && semi - i < 12) {
          const body = s.substring(i + 2, semi);
          const hex = body.startsWith('x') || body.startsWith('X');
          const num = hex ? parseInt(body.substring(1), 16) : parseInt(body, 10);
          if (!isNaN(num)) {
            out += String.fromCharCode(num);
            i = semi + 1;
            continue;
          }
        }
      }
      out += s.charAt(i);
      i++;
    }
    return out;
  }

  private static dropNoiseLines(s: string): string {
    const lines = s.split('\n');
    const kept: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      if (!HtmlCompat.isNoiseLine(lines[i])) {
        kept.push(lines[i]);
      }
    }
    return kept.join('\n').trim();
  }

  private static isNoiseLine(line: string): boolean {
    const t = line.trim();
    if (t.length === 0) {
      return false;
    }
    if (t.startsWith('[--')) {
      return true;
    }
    if (t.indexOf('var(--') >= 0 && t.indexOf(':') > 0) {
      return true;
    }
    if (t.indexOf('data-start=') >= 0 || t.indexOf('data-end=') >= 0) {
      return true;
    }
    if (t.indexOf('overflow-visible') >= 0) {
      return true;
    }
    return false;
  }

  private static cleanNoise(s: string): string {
    const lines = s.split('\n');
    const kept: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      if (!HtmlCompat.isNoiseLine(lines[i])) {
        kept.push(lines[i].replace(/[ \t]+$/g, ''));
      }
    }
    let out = kept.join('\n');
    out = out.replace(/\n{3,}/g, '\n\n');
    return out.trim();
  }
}
