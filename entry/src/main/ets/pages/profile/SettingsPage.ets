import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AppConfig } from '../../common/constants/AppConfig';
import { AuthRepository } from '../../data/repository/AuthRepository';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';

  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.refreshUser();
  }

  private async refreshUser(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.auth.load(ctx);
    this.auth.syncAppStorage();
  }

  private async logout(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.auth.logout(ctx);
    promptAction.showToast({ message: '已退出登录' });
    router.back();
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
            this.infoRow('应用名称', AppConfig.APP_NAME)
            this.infoRow('数据接口', AppConfig.REMOTE_API_BASE)
            this.infoRow('版本', 'V1.0')
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
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
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
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: '58%' })
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: '#F3F4F6' })
  }
}
