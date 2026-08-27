import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

const SETTINGS_PREF = 'app_settings';
const KEY_NOTIFY = 'notify_enabled';
const KEY_REMIND = 'study_remind';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private notifyOn: boolean = true;
  @State private remindOn: boolean = false;
  @State private unreadCount: number = 0;

  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.refreshUser();
    this.loadSettings();
    this.loadUnread();
  }

  onPageShow(): void {
    this.loadUnread();
  }

  private async refreshUser(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.auth.load(ctx);
    this.auth.syncAppStorage();
  }

  private async loadSettings(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await preferences.getPreferences(ctx, SETTINGS_PREF);
      this.notifyOn = await pref.get(KEY_NOTIFY, true) as boolean;
      this.remindOn = await pref.get(KEY_REMIND, false) as boolean;
    } catch (_e) {
    }
  }

  private async saveFlag(key: string, value: boolean): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const pref = await preferences.getPreferences(ctx, SETTINGS_PREF);
    await pref.put(key, value);
    await pref.flush();
  }

  private async logout(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.auth.logout(ctx);
    promptAction.showToast({ message: I18n.t('logged_out', this.lang) });
    router.back();
  }

  private async loadUnread(): Promise<void> {
    if (!this.isLoggedIn) {
      this.unreadCount = 0;
      return;
    }
    const uid = LoginGate.currentUserId();
    if (uid.length === 0) {
      return;
    }
    this.unreadCount = await RemoteApiDataSource.inboxUnread(uid);
  }

  private goFeedback(): void {
    LoginGate.ensure(I18n.t('feedback', this.lang), () => {
      router.pushUrl({ url: 'pages/profile/FeedbackPage' });
    });
  }

  private goInbox(): void {
    LoginGate.ensure(I18n.t('inbox', this.lang), () => {
      router.pushUrl({ url: 'pages/profile/InboxPage' });
    });
  }

  private async clearCache(): Promise<void> {
    promptAction.showToast({ message: I18n.t('cache_cleared', this.lang) });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('settings', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.isLoggedIn) {
            Row({ space: 12 }) {
              if (this.avatarUrl.length > 0) {
                Image(this.avatarUrl)
                  .width(48)
                  .height(48)
                  .borderRadius(24)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  Text('华')
                    .fontSize(18)
                    .fontColor(Color.White)
                }
                .width(48)
                .height(48)
                .borderRadius(24)
                .justifyContent(FlexAlign.Center)
                .backgroundColor('#CF0A2C')
              }
              Column({ space: 4 }) {
                Text(this.displayName.length > 0 ? this.displayName : I18n.t('huawei_user', this.lang))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(I18n.t('logged_huawei', this.lang))
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(14)
          }

          Column() {
            this.switchRow('notify', 'notify_sub', this.notifyOn, (on: boolean) => {
              this.notifyOn = on;
              this.saveFlag(KEY_NOTIFY, on);
            })
            this.switchRow('daily_remind', 'daily_remind_sub', this.remindOn, (on: boolean) => {
              this.remindOn = on;
              this.saveFlag(KEY_REMIND, on);
            })
            this.actionRow('language', '__lang__', () => {
              router.pushUrl({ url: 'pages/profile/LanguagePage' });
            })
            this.actionRow('clear_cache', 'clear_cache_sub', () => {
              this.clearCache();
            })
            this.actionRow('feedback', 'feedback_sub', () => {
              this.goFeedback();
            })
            this.actionRow('inbox', this.unreadCount > 0 ? '__inbox__' : 'inbox_sub', () => {
              this.goInbox();
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })

          Column() {
            this.actionRow('user_agreement', '', () => {
              router.pushUrl({ url: 'pages/profile/LegalPage', params: { kind: 'agreement' } });
            })
            this.actionRow('privacy', '', () => {
              router.pushUrl({ url: 'pages/profile/LegalPage', params: { kind: 'privacy' } });
            })
            this.infoRow('version', 'V1.0')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })

          if (this.isLoggedIn) {
            Button(I18n.t('logout', this.lang))
              .width('100%')
              .height(44)
              .fontSize(15)
              .backgroundColor('#FEF2F2')
              .fontColor('#DC2626')
              .onClick(() => {
                this.logout();
              })
          }
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 24 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F3F4F6')
  }

  @Builder
  switchRow(titleKey: string, subtitleKey: string, isOn: boolean, onChange: (on: boolean) => void) {
    Row() {
      Column({ space: 2 }) {
        Text(I18n.t(titleKey, this.lang)).fontSize(15).fontColor('#111827')
        Text(I18n.t(subtitleKey, this.lang)).fontSize(12).fontColor('#9CA3AF')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor('#2563EB')
        .width(40)
        .height(24)
        .onChange((on: boolean) => {
          onChange(on);
        })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: '#F3F4F6' })
  }

  @Builder
  actionRow(titleKey: string, subtitleKey: string, onTap: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(I18n.t(titleKey, this.lang)).fontSize(15).fontColor('#111827')
        if (subtitleKey === '__lang__') {
          Text(I18n.langName(this.lang)).fontSize(12).fontColor('#9CA3AF')
        } else if (subtitleKey === '__inbox__') {
          Text(I18n.tf('inbox_unread', `${this.unreadCount}`, this.lang)).fontSize(12).fontColor('#2563EB')
        } else if (subtitleKey.length > 0) {
          Text(I18n.t(subtitleKey, this.lang)).fontSize(12).fontColor('#9CA3AF')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(18).fontColor('#D1D5DB')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: '#F3F4F6' })
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  infoRow(labelKey: string, value: string) {
    Row() {
      Text(I18n.t(labelKey, this.lang))
        .fontSize(15)
        .fontColor('#111827')
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
  }
}
