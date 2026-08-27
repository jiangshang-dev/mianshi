import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { ThemeManager } from '../../common/theme/ThemeManager';

@Entry
@Component
struct ThemePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('appTheme') theme: string = ThemeManager.SYSTEM;

  private applyTheme(mode: string): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    ThemeManager.setMode(ctx, mode);
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('theme', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })

      Column() {
        this.themeRow(ThemeManager.SYSTEM, false)
        this.themeRow(ThemeManager.LIGHT, false)
        this.themeRow(ThemeManager.DARK, true)
      }
      .width('100%')
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(14)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  themeRow(mode: string, last: boolean) {
    Row() {
      Text(I18n.t(ThemeManager.labelKey(mode), this.lang))
        .fontSize(15)
        .fontColor(this.theme === mode ? $r('app.color.accent') : $r('app.color.text_primary'))
        .layoutWeight(1)
      if (this.theme === mode) {
        Text('✓')
          .fontSize(16)
          .fontColor($r('app.color.accent'))
          .padding({ left: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .border({ width: { bottom: last ? 0 : 0.5 }, color: $r('app.color.divider') })
    .onClick(() => {
      this.applyTheme(mode);
    })
  }
}
