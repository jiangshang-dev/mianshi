import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../i18n/I18n';
import { MemberMe } from '../models/MemberTypes';
import { CommentUi } from './CommentUi';
import { LoginGate } from './LoginGate';

interface DialogResult {
  index: number;
}

export class MemberGate {
  static readonly PREFIX: string = '[MEMBER_QUOTA]';
  static readonly ENABLED: string = 'memberEnabled';
  static readonly IS_MEMBER: string = 'isMember';
  static readonly LIFETIME: string = 'isLifetimeMember';
  static readonly PLAN_NAME: string = 'memberPlanName';
  static readonly EXPIRE_TIME: string = 'memberExpireTime';

  static isEnabled(): boolean {
    const v = AppStorage.get(MemberGate.ENABLED) as boolean;
    return v !== false;
  }

  static isActiveMember(): boolean {
    if (!MemberGate.isEnabled()) {
      return false;
    }
    const v = AppStorage.get(MemberGate.IS_MEMBER) as boolean;
    return v === true;
  }

  static applyMe(me: MemberMe | null): void {
    CommentUi.setBool(MemberGate.IS_MEMBER, me !== null && me.member);
    CommentUi.setBool(MemberGate.LIFETIME, me !== null && me.lifetime);
    CommentUi.setStr(MemberGate.PLAN_NAME, me !== null && me.planName.length > 0 ? me.planName : '');
    CommentUi.setNum(MemberGate.EXPIRE_TIME, MemberGate.parseExpireMs(me !== null ? me.expireTime : undefined));
    if (me !== null && me.memberEnabled !== undefined) {
      CommentUi.setBool(MemberGate.ENABLED, me.memberEnabled !== false);
    }
  }

  /** JSON 里 Long 常变成字符串，必须 Number 后再给 Date，否则会 NaN-NaN-NaN */
  static parseExpireMs(raw: number | string | undefined | null): number {
    if (raw === undefined || raw === null) {
      return 0;
    }
    const n = typeof raw === 'number' ? raw : Number(`${raw}`.trim());
    if (isNaN(n) || n <= 0) {
      return 0;
    }
    // 兼容秒级时间戳
    return n < 1000000000000 ? n * 1000 : n;
  }

  static clearMember(): void {
    CommentUi.setBool(MemberGate.IS_MEMBER, false);
    CommentUi.setBool(MemberGate.LIFETIME, false);
    CommentUi.setStr(MemberGate.PLAN_NAME, '');
    CommentUi.setNum(MemberGate.EXPIRE_TIME, 0);
  }

  static isQuotaError(text: string): boolean {
    return text.indexOf(MemberGate.PREFIX) >= 0 || text.indexOf('开通会员') >= 0;
  }

  static displayMessage(text: string): string {
    const idx = text.indexOf(MemberGate.PREFIX);
    if (idx >= 0) {
      return text.substring(idx + MemberGate.PREFIX.length);
    }
    return text;
  }

  static promptUpgrade(message: string): void {
    if (!MemberGate.isEnabled()) {
      return;
    }
    const shown = MemberGate.displayMessage(message);
    const upgrade = shown.indexOf('升级') >= 0;
    const action = upgrade ? I18n.t('member_upgrade') : I18n.t('member_buy');
    promptAction.showDialog({
      title: action,
      message: shown.length > 0 ? shown : I18n.t('member_need_msg'),
      buttons: [
        { text: I18n.t('cancel'), color: '#6B7280' },
        { text: action, color: '#2563EB' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        MemberGate.goMember();
      }
    }).catch(() => {
    });
  }

  static goMember(): void {
    LoginGate.ensure(I18n.t('member_title'), () => {
      router.pushUrl({ url: 'pages/profile/MemberPage' });
    });
  }
}
