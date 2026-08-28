import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF = 'app_settings';
const KEY = 'search_history';
const MAX = 10;
const SEP = '\n';

/** 搜索历史：本地 Preferences 缓存 */
export class SearchHistoryStore {
  static async load(ctx: common.UIAbilityContext): Promise<string[]> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      const raw = await pref.get(KEY, '') as string;
      return SearchHistoryStore.split(raw);
    } catch (_e) {
      return [];
    }
  }

  static async add(ctx: common.UIAbilityContext, keyword: string): Promise<string[]> {
    const word = keyword.trim();
    if (word.length === 0) {
      return SearchHistoryStore.load(ctx);
    }
    const next: string[] = [word];
    const prev = await SearchHistoryStore.load(ctx);
    for (let i = 0; i < prev.length; i++) {
      if (prev[i] !== word) {
        next.push(prev[i]);
      }
    }
    if (next.length > MAX) {
      next.length = MAX;
    }
    await SearchHistoryStore.save(ctx, next);
    return next;
  }

  static async clear(ctx: common.UIAbilityContext): Promise<void> {
    await SearchHistoryStore.save(ctx, []);
  }

  private static async save(ctx: common.UIAbilityContext, items: string[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      await pref.put(KEY, items.join(SEP));
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
