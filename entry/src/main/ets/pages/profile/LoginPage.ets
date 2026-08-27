import { promptAction, router } from '@kit.ArkUI';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct LoginPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private logging: boolean = false;
  @State private agreed: boolean = false;

  private auth: AuthRepository = AuthRepository.getInstance();

  private openLegal(kind: string): void {
    router.pushUrl({
      url: 'pages/profile/LegalPage',
      params: { kind: kind }
    });
  }

  private async doLogin(): Promise<void> {
    if (this.logging) {
      return;
    }
    if (!this.agreed) {
      promptAction.showToast({ message: I18n.t('agree_first', this.lang) });
      return;
    }
    this.logging = true;
    const host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.logging = false;
      promptAction.showToast({ message: I18n.t('no_ctx', this.lang) });
      return;
    }
    const outcome = await this.auth.loginWithHuawei(host);
    this.logging = false;
    if (outcome.ok && outcome.profile) {
      promptAction.showToast({ message: I18n.tf('welcome_user', outcome.profile.displayName, this.lang) });
      router.back();
      return;
    }
    promptAction.showToast({
      message: outcome.message.length > 0 ? outcome.message : I18n.t('login_fail', this.lang)
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('login', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
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
          Text(I18n.t('login_title', this.lang))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(I18n.t('login_sub', this.lang))
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
            .textAlign(TextAlign.Center)
        }

        Button(this.logging ? I18n.t('logging', this.lang) : I18n.t('login_huawei', this.lang))
          .width('100%')
          .height(46)
          .fontSize(16)
          .backgroundColor(this.agreed ? '#CF0A2C' : '#F3A3B0')
          .enabled(!this.logging)
          .onClick(() => {
            this.doLogin();
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 36 })

      Blank()

      Row({ space: 6 }) {
        Checkbox()
          .select(this.agreed)
          .selectedColor('#CF0A2C')
          .shape(CheckBoxShape.ROUNDED_SQUARE)
          .width(16)
          .height(16)
          .padding(0)
          .margin({ top: 1 })
          .onChange((checked: boolean) => {
            this.agreed = checked;
          })
        Text() {
          Span(I18n.t('agree_prefix', this.lang))
            .fontColor($r('app.color.text_muted'))
          Span(I18n.t('user_agreement', this.lang))
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.openLegal('agreement');
            })
          Span(I18n.t('and', this.lang))
            .fontColor($r('app.color.text_muted'))
          Span(I18n.t('privacy', this.lang))
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.openLegal('privacy');
            })
        }
        .fontSize(12)
        .lineHeight(16)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 32, right: 32, bottom: 24 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
