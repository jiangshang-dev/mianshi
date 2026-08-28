export interface BilibiliVideoItem {
  title: string;
  bvid: string;
  playUrl: string;
  embedUrl: string;
  appUrl: string;
}

/** 从后台配置的 B 站链接 / iframe / 分享文案解析可播放条目 */
export class BilibiliLink {
  static parseList(raw: string[]): BilibiliVideoItem[] {
    const out: BilibiliVideoItem[] = [];
    for (let i = 0; i < raw.length; i++) {
      const item = BilibiliLink.parseOne(raw[i], i);
      if (item !== null) {
        out.push(item);
      }
    }
    return out;
  }

  static parseOne(raw: string, index: number): BilibiliVideoItem | null {
    const text = raw.trim();
    if (text.length === 0) {
      return null;
    }
    const bvid = BilibiliLink.extractBvid(text);
    const iframeSrc = BilibiliLink.extractIframeSrc(text);
    const pageUrl = BilibiliLink.extractHttpUrl(text);
    if (bvid.length === 0 && iframeSrc.length === 0 && pageUrl.length === 0) {
      return null;
    }
    const embedUrl = bvid.length > 0
      ? `https://player.bilibili.com/player.html?isOutside=true&bvid=${bvid}&p=1&autoplay=0&high_quality=1&danmaku=0&as_wide=1`
      : BilibiliLink.normalizeEmbed(iframeSrc.length > 0 ? iframeSrc : pageUrl);
    const playUrl = bvid.length > 0
      ? `https://www.bilibili.com/video/${bvid}`
      : (pageUrl.length > 0 ? pageUrl : embedUrl);
    const appUrl = bvid.length > 0 ? `bilibili://video/${bvid}` : '';
    const title = BilibiliLink.extractTitle(text, bvid, index);
    return {
      title: title,
      bvid: bvid,
      playUrl: playUrl,
      embedUrl: embedUrl,
      appUrl: appUrl
    };
  }

  private static normalizeEmbed(src: string): string {
    if (src.startsWith('//')) {
      return `https:${src}`;
    }
    if (src.startsWith('http://')) {
      return `https://${src.substring(7)}`;
    }
    return src;
  }

  private static extractBvid(text: string): string {
    let from = 0;
    while (from < text.length) {
      const i = text.indexOf('BV', from);
      if (i < 0) {
        break;
      }
      if (i + 12 <= text.length) {
        const cand = text.substring(i, i + 12);
        if (BilibiliLink.isBvid(cand)) {
          return cand;
        }
      }
      from = i + 2;
    }
    return '';
  }

  private static isBvid(cand: string): boolean {
    if (cand.length !== 12 || cand[0] !== 'B' || cand[1] !== 'V') {
      return false;
    }
    for (let i = 2; i < 12; i++) {
      const c = cand.charCodeAt(i);
      const ok = (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
      if (!ok) {
        return false;
      }
    }
    return true;
  }

  private static extractIframeSrc(text: string): string {
    const keys: string[] = ['src="', "src='"];
    for (let k = 0; k < keys.length; k++) {
      const key = keys[k];
      const i = text.indexOf(key);
      if (i < 0) {
        continue;
      }
      const quote = key.charAt(key.length - 1);
      const start = i + key.length;
      const end = text.indexOf(quote, start);
      if (end > start) {
        return text.substring(start, end).trim();
      }
    }
    return '';
  }

  private static extractHttpUrl(text: string): string {
    let start = text.indexOf('https://');
    if (start < 0) {
      start = text.indexOf('http://');
    }
    if (start < 0) {
      return '';
    }
    let end = start;
    while (end < text.length) {
      const ch = text.charAt(end);
      if (ch === ' ' || ch === '\n' || ch === '\r' || ch === '"' || ch === "'" || ch === '>') {
        break;
      }
      end++;
    }
    return text.substring(start, end);
  }

  private static extractTitle(text: string, bvid: string, index: number): string {
    const left = text.indexOf('【');
    const right = text.indexOf('】');
    if (left >= 0 && right > left + 1) {
      const inner = text.substring(left + 1, right).trim();
      if (inner.length > 0) {
        return inner;
      }
    }
    if (bvid.length > 0) {
      return bvid;
    }
    return `视频 ${index + 1}`;
  }
}
