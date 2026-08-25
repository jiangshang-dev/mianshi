import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';

@Entry
@Component
struct LoginPage {
  @State private logging: boolean = false;

  private auth: AuthRepository = AuthRepository.getInstance();

  private async doLogin(): Promise<void> {
    if (this.logging) {
      return;
    }
    this.logging = true;
    const host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.logging = false;
      promptAction.showToast({ message: '无法获取页面上下文' });
      return;
    }
    const outcome = await this.auth.loginWithHuawei(host);
    this.logging = false;
    if (outcome.ok && outcome.profile) {
      promptAction.showToast({ message: `欢迎，${outcome.profile.displayName}` });
      router.back();
      return;
    }
    promptAction.showToast({
      message: outcome.message.length > 0 ? outcome.message : '华为账号登录失败'
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text('登录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Column({ space: 20 }) {
        Column() {
          Text('👤')
            .fontSize(36)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E5E7EB')

        Column({ space: 8 }) {
          Text('登录码上 Offer')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
          Text('使用华为账号登录，同步学习记录与简历')
            .fontSize(14)
            .fontColor('#6B7280')
            .textAlign(TextAlign.Center)
        }

        Button(this.logging ? '登录中…' : '华为账号登录')
          .width('100%')
          .height(46)
          .fontSize(16)
          .backgroundColor('#CF0A2C')
          .enabled(!this.logging)
          .onClick(() => {
            this.doLogin();
          })

        Text('登录即表示同意用户协议与隐私政策')
          .fontSize(12)
          .fontColor('#9CA3AF')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 48 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
