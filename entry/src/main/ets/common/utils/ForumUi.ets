import { I18n } from '../i18n/I18n';
import { ForumCatTone, ForumReply, ForumReplyRow, ForumReplyThread } from '../models/ForumTypes';
import { mallStr } from '../models/MallTypes';

export class ForumUi {
  static readonly PREVIEW_CHILD = 2;
  static readonly CONTENT_LIMIT = 90;

  static nickInitial(name: string): string {
    if (name.length === 0) {
      return '?';
    }
    return name.substring(0, 1);
  }

  static avatarColor(name: string): string {
    if (name.length === 0) {
      return '#60A5FA';
    }
    const palette: string[] = ['#60A5FA', '#34D399', '#F59E0B', '#A78BFA', '#F87171'];
    return palette[name.charCodeAt(0) % palette.length];
  }

  static catTone(name: string): ForumCatTone {
    if (name.indexOf('面试') >= 0) {
      const tone: ForumCatTone = { bg: '#DBEAFE', fg: '#2563EB' };
      return tone;
    }
    if (name.indexOf('求职') >= 0) {
      const tone: ForumCatTone = { bg: '#D1FAE5', fg: '#059669' };
      return tone;
    }
    if (name.indexOf('问答') >= 0) {
      const tone: ForumCatTone = { bg: '#EDE9FE', fg: '#7C3AED' };
      return tone;
    }
    if (name.indexOf('打卡') >= 0) {
      const tone: ForumCatTone = { bg: '#FFEDD5', fg: '#EA580C' };
      return tone;
    }
    const tone: ForumCatTone = { bg: '#EFF6FF', fg: '#2563EB' };
    return tone;
  }

  static relativeTime(raw: string, lang: string): string {
    if (raw.length < 16) {
      return raw;
    }
    const y = Number.parseInt(raw.substring(0, 4), 10);
    const mo = Number.parseInt(raw.substring(5, 7), 10);
    const d = Number.parseInt(raw.substring(8, 10), 10);
    const h = Number.parseInt(raw.substring(11, 13), 10);
    const mi = Number.parseInt(raw.substring(14, 16), 10);
    const s = raw.length >= 19 ? Number.parseInt(raw.substring(17, 19), 10) : 0;
    const then = new Date(y, mo - 1, d, h, mi, s).getTime();
    const diff = Date.now() - then;
    if (diff < 60 * 1000) {
      return I18n.t('forum_just_now', lang);
    }
    if (diff < 60 * 60 * 1000) {
      return I18n.tf('forum_min_ago', `${Math.floor(diff / 60000)}`, lang);
    }
    if (diff < 24 * 60 * 60 * 1000) {
      return I18n.tf('forum_hour_ago', `${Math.floor(diff / 3600000)}`, lang);
    }
    if (diff < 7 * 24 * 60 * 60 * 1000) {
      return I18n.tf('forum_day_ago', `${Math.floor(diff / 86400000)}`, lang);
    }
    return raw.substring(0, 10);
  }

  static formatCount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}w`;
    }
    if (n >= 1000) {
      return `${(n / 1000).toFixed(1)}k`;
    }
    return `${n}`;
  }

  static hasReplyId(id: string, all: ForumReply[]): boolean {
    for (let i = 0; i < all.length; i++) {
      if (mallStr(all[i].id) === id) {
        return true;
      }
    }
    return false;
  }

  static isRoot(item: ForumReply, all: ForumReply[]): boolean {
    const pid = mallStr(item.parentId);
    return pid.length === 0 || !ForumUi.hasReplyId(pid, all);
  }

  static childRows(parentId: string, all: ForumReply[], depth: number): ForumReplyRow[] {
    const out: ForumReplyRow[] = [];
    for (let i = 0; i < all.length; i++) {
      if (mallStr(all[i].parentId) === parentId) {
        const row: ForumReplyRow = { reply: all[i], depth: depth };
        out.push(row);
        const nested = ForumUi.childRows(mallStr(all[i].id), all, depth + 1);
        for (let j = 0; j < nested.length; j++) {
          out.push(nested[j]);
        }
      }
    }
    return out;
  }

  static threads(all: ForumReply[], latest: boolean): ForumReplyThread[] {
    const roots: ForumReply[] = [];
    for (let i = 0; i < all.length; i++) {
      if (ForumUi.isRoot(all[i], all)) {
        roots.push(all[i]);
      }
    }
    const list: ForumReplyThread[] = [];
    for (let i = 0; i < roots.length; i++) {
      const thread: ForumReplyThread = {
        root: roots[i],
        children: ForumUi.childRows(mallStr(roots[i].id), all, 1),
        floor: i + 1
      };
      list.push(thread);
    }
    if (!latest) {
      return list;
    }
    const rev: ForumReplyThread[] = [];
    for (let i = list.length - 1; i >= 0; i--) {
      rev.push(list[i]);
    }
    return rev;
  }

  static longContent(text: string): boolean {
    return text.length > ForumUi.CONTENT_LIMIT;
  }

  static idIn(id: string, list: string[]): boolean {
    for (let i = 0; i < list.length; i++) {
      if (list[i] === id) {
        return true;
      }
    }
    return false;
  }

  static toggleId(id: string, list: string[]): string[] {
    const next: string[] = [];
    let found = false;
    for (let i = 0; i < list.length; i++) {
      if (list[i] === id) {
        found = true;
      } else {
        next.push(list[i]);
      }
    }
    if (!found) {
      next.push(id);
    }
    return next;
  }
}
