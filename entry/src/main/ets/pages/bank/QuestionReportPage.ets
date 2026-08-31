import { promptAction, router } from '@kit.ArkUI';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';
import { RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';

interface ReportRouteParams {
  questionId?: string;
  questionTitle?: string;
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
struct QuestionReportPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private typeKey: string = '答案有误';
  @State private content: string = '';
  @State private contact: string = '';
  @State private submitting: boolean = false;
  private questionId: string = '';
  private questionTitle: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as ReportRouteParams;
    this.questionId = params.questionId ?? '';
    this.questionTitle = params.questionTitle ?? '';
  }

  private types(): TypeOpt[] {
    const list: TypeOpt[] = [];
    list.push(new TypeOpt('答案有误', I18n.t('report_ty_wrong', this.lang)));
    list.push(new TypeOpt('题干不清', I18n.t('report_ty_unclear', this.lang)));
    list.push(new TypeOpt('内容过时', I18n.t('report_ty_outdated', this.lang)));
    list.push(new TypeOpt('错别字', I18n.t('report_ty_typo', this.lang)));
    list.push(new TypeOpt('其他', I18n.t('report_ty_other', this.lang)));
    return list;
  }

  private async submit(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      LoginGate.goLogin();
      return;
    }
    const text = this.content.trim();
    if (text.length < 4) {
      promptAction.showToast({ message: I18n.t('report_hint', this.lang) });
      return;
    }
    this.submitting = true;
    const ok = await RemoteApiDataSource.submitQuestionReport(
      this.questionId, this.questionTitle, this.typeKey, text, this.contact.trim());
    this.submitting = false;
    promptAction.showToast({ message: I18n.t(ok ? 'report_ok' : 'report_fail', this.lang) });
    if (ok) {
      router.back();
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('report_title', this.lang)).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          Text(I18n.t('report_q', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
          Text(this.questionTitle.length > 0 ? this.questionTitle : I18n.t('unnamed_q', this.lang))
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
          TextArea({ text: this.content, placeholder: I18n.t('report_hint', this.lang) })
            .height(140)
            .backgroundColor($r('app.color.card_bg'))
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_muted'))
            .onChange((v: string) => {
              this.content = v;
            })

          Text(I18n.t('feedback_contact', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
          TextInput({ text: this.contact, placeholder: '微信 / 邮箱 / 手机' })
            .height(44)
            .backgroundColor($r('app.color.card_bg'))
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_muted'))
            .onChange((v: string) => {
              this.contact = v;
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
