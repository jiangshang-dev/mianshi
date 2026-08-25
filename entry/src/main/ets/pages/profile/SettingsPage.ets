import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';

const SETTINGS_PREF = 'app_settings';
const KEY_NOTIFY = 'notify_enabled';
const KEY_REMIND = 'study_remind';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @State private notifyOn: boolean = true;
  @State private remindOn: boolean = false;

  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.refreshUser();
    this.loadSettings();
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
    promptAction.showToast({ message: '已退出登录' });
    router.back();
  }

  private async clearCache(): Promise<void> {
    promptAction.showToast({ message: '缓存已清除' });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text('设置')
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
                Text(this.displayName.length > 0 ? this.displayName : '华为用户')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text('华为账号已登录')
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
            this.switchRow('消息通知', '学习与面试相关提醒', this.notifyOn, (on: boolean) => {
              this.notifyOn = on;
              this.saveFlag(KEY_NOTIFY, on);
            })
            this.switchRow('每日学习提醒', '提醒你完成当天刷题', this.remindOn, (on: boolean) => {
              this.remindOn = on;
              this.saveFlag(KEY_REMIND, on);
            })
            this.actionRow('清除缓存', '清理本地临时数据', () => {
              this.clearCache();
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })

          Column() {
            this.actionRow('用户协议', '', () => {
              router.pushUrl({ url: 'pages/profile/LegalPage', params: { kind: 'agreement' } });
            })
            this.actionRow('隐私政策', '', () => {
              router.pushUrl({ url: 'pages/profile/LegalPage', params: { kind: 'privacy' } });
            })
            this.infoRow('当前版本', 'V1.0')
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })

          if (this.isLoggedIn) {
            Button('退出登录')
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
  switchRow(title: string, subtitle: string, isOn: boolean, onChange: (on: boolean) => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontColor('#111827')
        Text(subtitle).fontSize(12).fontColor('#9CA3AF')
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
  actionRow(title: string, subtitle: string, onTap: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontColor('#111827')
        if (subtitle.length > 0) {
          Text(subtitle).fontSize(12).fontColor('#9CA3AF')
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
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
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
