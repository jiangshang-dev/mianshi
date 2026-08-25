import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LangManager } from '../../common/i18n/LangManager';

@Entry
@Component
struct LanguagePage {
  @StorageLink('appLang') lang: string = I18n.HANS;

  private applyLang(code: string): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    LangManager.setLang(ctx, code);
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('language', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Column() {
        this.langRow(I18n.HANS)
        this.langRow(I18n.HANT)
        this.langRow(I18n.EN)
      }
      .width('100%')
      .margin({ left: 16, right: 16, top: 8 })
      .backgroundColor(Color.White)
      .borderRadius(14)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F3F4F6')
  }

  @Builder
  langRow(code: string) {
    Row() {
      Text(I18n.langName(code))
        .fontSize(15)
        .fontColor(this.lang === code ? '#2563EB' : '#111827')
        .layoutWeight(1)
      if (this.lang === code) {
        Text('✓').fontSize(16).fontColor('#2563EB')
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .border({ width: { bottom: code === I18n.EN ? 0 : 0.5 }, color: '#F3F4F6' })
    .onClick(() => {
      this.applyLang(code);
    })
  }
}
