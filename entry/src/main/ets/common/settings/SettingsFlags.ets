import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF = 'app_settings';
const KEY_NOTIFY = 'notify_enabled';
const KEY_REMIND = 'study_remind';
const KEY_AI_NOTICE = 'ai_notice_accepted';

export class SettingsFlags {
  static readonly NOTIFY: string = 'notifyEnabled';
  static readonly REMIND: string = 'studyRemind';
  static readonly AI_NOTICE: string = 'aiNoticeAccepted';

  static async load(ctx: common.UIAbilityContext): Promise<void> {
    let notifyOn = true;
    let remindOn = false;
    let aiNotice = false;
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      notifyOn = await pref.get(KEY_NOTIFY, true) as boolean;
      remindOn = await pref.get(KEY_REMIND, false) as boolean;
      aiNotice = await pref.get(KEY_AI_NOTICE, false) as boolean;
    } catch (_e) {
    }
    AppStorage.setOrCreate(SettingsFlags.NOTIFY, notifyOn);
    AppStorage.setOrCreate(SettingsFlags.REMIND, remindOn);
    AppStorage.setOrCreate(SettingsFlags.AI_NOTICE, aiNotice);
  }

  static async save(ctx: common.UIAbilityContext, key: string, value: boolean): Promise<void> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      await pref.put(key, value);
      await pref.flush();
    } catch (_e) {
    }
    if (key === KEY_NOTIFY) {
      AppStorage.setOrCreate(SettingsFlags.NOTIFY, value);
    } else if (key === KEY_REMIND) {
      AppStorage.setOrCreate(SettingsFlags.REMIND, value);
    } else if (key === KEY_AI_NOTICE) {
      AppStorage.setOrCreate(SettingsFlags.AI_NOTICE, value);
    }
  }

  static notifyKey(): string {
    return KEY_NOTIFY;
  }

  static remindKey(): string {
    return KEY_REMIND;
  }

  static aiNoticeKey(): string {
    return KEY_AI_NOTICE;
  }
}
