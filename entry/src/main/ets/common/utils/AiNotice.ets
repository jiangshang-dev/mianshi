import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { I18n } from '../i18n/I18n';
import { SettingsFlags } from '../settings/SettingsFlags';

interface DialogResult {
  index: number;
}

export class AiNotice {
  static isAccepted(): boolean {
    return AppStorage.get(SettingsFlags.AI_NOTICE) === true;
  }

  static ensure(ctx: common.UIAbilityContext, onOk: () => void): void {
    if (AiNotice.isAccepted()) {
      onOk();
      return;
    }
    promptAction.showDialog({
      title: I18n.t('ai_notice_title'),
      message: I18n.t('ai_notice_msg'),
      buttons: [
        { text: I18n.t('cancel'), color: '#6B7280' },
        { text: I18n.t('ai_notice_ok'), color: '#2563EB' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        SettingsFlags.save(ctx, SettingsFlags.aiNoticeKey(), true);
        onOk();
      }
    }).catch(() => {
    });
  }
}
