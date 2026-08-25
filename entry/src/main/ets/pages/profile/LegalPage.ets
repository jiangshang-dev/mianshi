import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';

interface LegalNav {
  kind?: string;
}

@Entry
@Component
struct LegalPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private kind: string = 'agreement';

  aboutToAppear(): void {
    const nav = router.getParams() as LegalNav;
    if (nav !== undefined && nav.kind === 'privacy') {
      this.kind = 'privacy';
    } else {
      this.kind = 'agreement';
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(this.kind === 'privacy' ? I18n.t('privacy', this.lang) : I18n.t('user_agreement', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.kind === 'privacy' ? I18n.privacy(this.lang) : I18n.agreement(this.lang),
            (text: string, idx: number) => {
              Text(text)
                .fontSize(15)
                .fontColor('#374151')
                .lineHeight(24)
                .width('100%')
            }, (text: string, idx: number) => `${this.lang}-${idx}`)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
