import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { I18n } from '../i18n/I18n';

interface DialogResult {
  index: number;
}

export class LoginGate {
  static isLoggedIn(): boolean {
    return AuthRepository.getInstance().isLoggedIn();
  }

  static currentUserId(): string {
    const user = AuthRepository.getInstance().getCached();
    return user !== null ? user.userId : '';
  }

  static ensure(feature: string, onOk: () => void): void {
    if (LoginGate.isLoggedIn()) {
      onOk();
      return;
    }
    promptAction.showDialog({
      title: I18n.t('need_login'),
      message: I18n.tf('need_login_msg', feature),
      buttons: [
        { text: I18n.t('cancel'), color: '#6B7280' },
        { text: I18n.t('go_login'), color: '#2563EB' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        LoginGate.goLogin();
      }
    }).catch(() => {
    });
  }

  static goLogin(): void {
    router.pushUrl({ url: 'pages/profile/LoginPage' });
  }
}
