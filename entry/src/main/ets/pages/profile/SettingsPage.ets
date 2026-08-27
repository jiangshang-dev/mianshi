import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';
import { ThemeManager } from '../../common/theme/ThemeManager';
import { SettingsFlags } from '../../common/settings/SettingsFlags';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('appTheme') theme: string = ThemeManager.SYSTEM;
  @StorageLink('notifyEnabled') notifyOn: boolean = true;
  @StorageLink('studyRemind') remindOn: boolean = false;
  @State private unreadCount: number = 0;

  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.refreshUser();
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

  private async saveFlag(key: string, value: boolean): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await SettingsFlags.save(ctx, key, value);
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
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('settings', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          // if (this.isLoggedIn) {
            // Row({ space: 12 }) {
              // if (this.avatarUrl.length > 0) {
              //   Image(this.avatarUrl)
              //     .width(48)
              //     .height(48)
              //     .borderRadius(24)
              //     .objectFit(ImageFit.Cover)
              // } else {
              //   Column() {
              //     Text('华')
              //       .fontSize(18)
              //       .fontColor($r('app.color.text_on_color'))
              //   }
              //   .width(48)
              //   .height(48)
              //   .borderRadius(24)
              //   .justifyContent(FlexAlign.Center)
              //   .backgroundColor('#CF0A2C')
              // }
              // Column({ space: 4 }) {
              //   Text(this.displayName.length > 0 ? this.displayName : I18n.t('huawei_user', this.lang))
              //     .fontSize(16)
              //     .fontWeight(FontWeight.Medium)
              //     .fontColor($r('app.color.text_primary'))
              //   Text(I18n.t('logged_huawei', this.lang))
              //     .fontSize(12)
              //     .fontColor($r('app.color.text_muted'))
              // }
              // .alignItems(HorizontalAlign.Start)
            // }
            // .width('100%')
            // .padding(14)
            // .backgroundColor($r('app.color.card_bg'))
            // .borderRadius(14)
          // }

          Column() {
            // Row() {
              // Column({ space: 2 }) {
              //   Text(I18n.t('notify', this.lang)).fontSize(15).fontColor($r('app.color.text_primary'))
              //   Text(I18n.t('notify_sub', this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
              // }
              // .alignItems(HorizontalAlign.Start)
              // .layoutWeight(1)
              // Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
              //   .selectedColor('#2563EB')
              //   .width(40)
              //   .height(24)
              //   .onChange((on: boolean) => {
              //     this.notifyOn = on;
              //     this.saveFlag(SettingsFlags.notifyKey(), on);
              //   })
            // }
            // .width('100%')
            // .padding({ top: 14, bottom: 14 })
            // .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

            // Row() {
            //   Column({ space: 2 }) {
            //     Text(I18n.t('daily_remind', this.lang)).fontSize(15).fontColor($r('app.color.text_primary'))
            //     Text(I18n.t('daily_remind_sub', this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
            //   }
            //   .alignItems(HorizontalAlign.Start)
            //   .layoutWeight(1)
            //   Toggle({ type: ToggleType.Switch, isOn: this.remindOn })
            //     .selectedColor('#2563EB')
            //     .width(40)
            //     .height(24)
            //     .onChange((on: boolean) => {
            //       this.remindOn = on;
            //       this.saveFlag(SettingsFlags.remindKey(), on);
            //     })
            // }
            // .width('100%')
            // .padding({ top: 14, bottom: 14 })
            // .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
            this.actionRow('language', '__lang__', () => {
              router.pushUrl({ url: 'pages/profile/LanguagePage' });
            })
            this.actionRow('theme', '__theme__', () => {
              router.pushUrl({ url: 'pages/profile/ThemePage' });
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
          .backgroundColor($r('app.color.card_bg'))
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
          .backgroundColor($r('app.color.card_bg'))
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
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  actionRow(titleKey: string, subtitleKey: string, onTap: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(I18n.t(titleKey, this.lang)).fontSize(15).fontColor($r('app.color.text_primary'))
        if (subtitleKey === '__lang__') {
          Text(I18n.langName(this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
        } else if (subtitleKey === '__theme__') {
          Text(I18n.t(ThemeManager.labelKey(this.theme), this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
        } else if (subtitleKey === '__inbox__') {
          Text(I18n.tf('inbox_unread', `${this.unreadCount}`, this.lang)).fontSize(12).fontColor($r('app.color.accent'))
        } else if (subtitleKey.length > 0) {
          Text(I18n.t(subtitleKey, this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(18).fontColor($r('app.color.text_muted'))
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  infoRow(labelKey: string, value: string) {
    Row() {
      Text(I18n.t(labelKey, this.lang))
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.text_muted'))
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
  }
}
