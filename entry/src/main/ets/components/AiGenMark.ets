import { I18n } from '../common/i18n/I18n';

@Component
export struct AiGenMark {
  @StorageLink('appLang') lang: string = I18n.HANS;

  build() {
    Text(I18n.t('ai_gen_badge', this.lang))
      .fontSize(10)
      .fontColor($r('app.color.ai_badge_text'))
      .backgroundColor($r('app.color.ai_badge_bg'))
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(4)
  }
}

@Component
export struct AiDisclaimerBar {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop shortText: boolean = false;

  build() {
    Text(I18n.t(this.shortText ? 'ai_disclaimer_short' : 'ai_disclaimer', this.lang))
      .fontSize(11)
      .fontColor($r('app.color.text_muted'))
      .lineHeight(16)
      .width('100%')
  }
}
