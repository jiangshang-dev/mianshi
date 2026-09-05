import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF = 'app_settings';
const KEY = 'search_history';
const MAX = 10;
const SEP = '\n';

export const BLOG_SEARCH_HISTORY = 'blog_search_history';
export const FORUM_SEARCH_HISTORY = 'forum_search_history';

/** 搜索历史：本地 Preferences 缓存 */
export class SearchHistoryStore {

  static async load(ctx: common.UIAbilityContext, key: string = KEY): Promise<string[]> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      const raw = await pref.get(key, '') as string;
      return SearchHistoryStore.split(raw);
    } catch (_e) {
      return [];
    }
  }

  static async add(ctx: common.UIAbilityContext, keyword: string, key: string = KEY): Promise<string[]> {
    const word = keyword.trim();
    if (word.length === 0) {
      return SearchHistoryStore.load(ctx, key);
    }
    const next: string[] = [word];
    const prev = await SearchHistoryStore.load(ctx, key);
    for (let i = 0; i < prev.length; i++) {
      if (prev[i] !== word) {
        next.push(prev[i]);
      }
    }
    if (next.length > MAX) {
      next.length = MAX;
    }
    await SearchHistoryStore.save(ctx, next, key);
    return next;
  }

  static async clear(ctx: common.UIAbilityContext, key: string = KEY): Promise<void> {
    await SearchHistoryStore.save(ctx, [], key);
  }

  private static async save(ctx: common.UIAbilityContext, items: string[], key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      await pref.put(key, items.join(SEP));
      await pref.flush();
    } catch (_e) {
    }
  }

  private static split(raw: string): string[] {
    if (raw.length === 0) {
      return [];
    }
    const out: string[] = [];
    const parts = raw.split(SEP);
    for (let i = 0; i < parts.length; i++) {
      const item = parts[i].trim();
      if (item.length > 0) {
        out.push(item);
      }
    }
    return out;
  }
}
