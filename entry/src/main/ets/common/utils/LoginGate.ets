import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';

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
      title: '需要登录',
      message: `${feature}登录后才可使用`,
      buttons: [
        { text: '取消', color: '#6B7280' },
        { text: '去登录', color: '#2563EB' }
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
