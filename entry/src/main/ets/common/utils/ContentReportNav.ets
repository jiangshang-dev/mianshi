import { router } from '@kit.ArkUI';
import { I18n } from '../i18n/I18n';
import { LoginGate } from './LoginGate';

export class ContentReportNav {
  static open(lang: string, targetType: string, targetId: string, title: string): void {
    LoginGate.ensure(I18n.t('content_report', lang), () => {
      if (targetId.length === 0) {
        return;
      }
      router.pushUrl({
        url: 'pages/profile/ContentReportPage',
        params: { 'targetType': targetType, 'targetId': targetId, 'title': title }
      });
    });
  }
}
