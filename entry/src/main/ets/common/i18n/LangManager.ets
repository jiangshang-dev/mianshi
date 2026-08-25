import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { i18n } from '@kit.LocalizationKit';
import { I18n } from './I18n';

const PREF = 'app_settings';
const PREF_LANG = 'app_lang';

export class LangManager {
  static async load(ctx: common.UIAbilityContext): Promise<void> {
    let lang = LangManager.fromSystem();
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      const saved = await pref.get(PREF_LANG, '') as string;
      if (saved === I18n.HANS || saved === I18n.HANT || saved === I18n.EN) {
        lang = saved;
      }
    } catch (_e) {
    }
    LangManager.apply(lang);
  }

  static async setLang(ctx: common.UIAbilityContext, lang: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      await pref.put(PREF_LANG, lang);
      await pref.flush();
    } catch (_e) {
    }
    LangManager.apply(lang);
  }

  static apply(lang: string): void {
    AppStorage.setOrCreate(I18n.KEY, lang);
    try {
      i18n.System.setAppPreferredLanguage(lang);
    } catch (_e) {
    }
  }

  static fromSystem(): string {
    try {
      const sys = i18n.System.getSystemLanguage();
      if (sys.indexOf('Hant') >= 0 || sys.indexOf('TW') >= 0 || sys.indexOf('HK') >= 0) {
        return I18n.HANT;
      }
      if (sys.indexOf('en') === 0) {
        return I18n.EN;
      }
    } catch (_e) {
    }
    return I18n.HANS;
  }
}
