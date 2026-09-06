import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import { ContentReportRepository } from '../../data/repository/ContentReportRepository';

interface ContentReportParams {
  targetType?: string;
  targetId?: string;
  title?: string;
}

class TypeOpt {
  key: string;
  label: string;

  constructor(key: string, label: string) {
    this.key = key;
    this.label = label;
  }
}

@Entry
@Component
struct ContentReportPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private typeKey: string = '垃圾广告';
  @State private content: string = '';
  @State private submitting: boolean = false;
  private targetType: string = '';
  private targetId: string = '';
  private targetTitle: string = '';
  private repo: ContentReportRepository = ContentReportRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as ContentReportParams;
    this.targetType = params !== undefined && params.targetType !== undefined ? params.targetType : '';
    this.targetId = params !== undefined && params.targetId !== undefined ? params.targetId : '';
    this.targetTitle = params !== undefined && params.title !== undefined ? params.title : '';
  }

  private types(): TypeOpt[] {
    const list: TypeOpt[] = [];
    list.push(new TypeOpt('垃圾广告', I18n.t('content_report_ty_spam', this.lang)));
    list.push(new TypeOpt('色情低俗', I18n.t('content_report_ty_porn', this.lang)));
    list.push(new TypeOpt('辱骂攻击', I18n.t('content_report_ty_abuse', this.lang)));
    list.push(new TypeOpt('违法违规', I18n.t('content_report_ty_illegal', this.lang)));
    list.push(new TypeOpt('其他', I18n.t('content_report_ty_other', this.lang)));
    return list;
  }

  private async submit(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      LoginGate.goLogin();
      return;
    }
    if (this.targetId.length === 0) {
      return;
    }
    this.submitting = true;
    try {
      await this.repo.submit(this.targetType, this.targetId, this.targetTitle, this.typeKey, this.content.trim());
      promptAction.showToast({ message: I18n.t('content_report_ok', this.lang) });
      router.back();
    } catch (err) {
      promptAction.showToast({
        message: err instanceof Error && err.message.length > 0 ? err.message : I18n.t('content_report_fail', this.lang)
      });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('content_report_title', this.lang)).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          Text(I18n.t('content_report_target', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
          Text(this.targetTitle.length > 0 ? this.targetTitle : I18n.t('content_report', this.lang))
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(10)

          Text(I18n.t('report_type', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.types(), (item: TypeOpt) => {
              Text(item.label)
                .fontSize(13)
                .fontColor(this.typeKey === item.key ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
                .backgroundColor(this.typeKey === item.key ? $r('app.color.accent') : $r('app.color.chip_idle_bg'))
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .borderRadius(16)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.typeKey = item.key;
                })
            }, (item: TypeOpt) => item.key)
          }
          .width('100%')

          Text(I18n.t('report_content', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
          TextArea({ text: this.content, placeholder: I18n.t('content_report_hint', this.lang) })
            .height(140)
            .backgroundColor($r('app.color.card_bg'))
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_muted'))
            .onChange((v: string) => {
              this.content = v;
            })

          Button(I18n.t('feedback_submit', this.lang))
            .width('100%')
            .height(44)
            .backgroundColor('#2563EB')
            .enabled(!this.submitting)
            .onClick(() => {
              this.submit();
            })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
