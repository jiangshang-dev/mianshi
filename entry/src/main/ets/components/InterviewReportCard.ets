import { InterviewReport } from '../common/models/InterviewTypes';
import { I18n } from '../common/i18n/I18n';
import { AiGenMark, AiDisclaimerBar } from './AiGenMark';

@Component
export struct InterviewReportCard {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop report: InterviewReport = {
    score: 0,
    accuracy: 0,
    depth: 0,
    expression: 0,
    advantages: [],
    problems: [],
    suggestions: []
  };

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(I18n.t('iv_report', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        AiGenMark()
      }
      .width('100%')
      AiDisclaimerBar({ shortText: true })
      Text(I18n.tf('total_score', `${this.report.score}`, this.lang))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent'))
        .width('100%')
      Row() {
        this.scoreItem('score_acc', this.report.accuracy)
        this.scoreItem('score_depth', this.report.depth)
        this.scoreItem('score_exp', this.report.expression)
      }
      .width('100%')
      Text(I18n.tf('adv_label', this.report.advantages.join('；'), this.lang))
        .fontSize(13)
        .fontColor($r('app.color.chip_idle_text'))
        .width('100%')
      Text(I18n.tf('prob_label', this.report.problems.join('；'), this.lang))
        .fontSize(13)
        .fontColor($r('app.color.chip_idle_text'))
        .width('100%')
      Text(I18n.tf('sugg_label', this.report.suggestions.join('；'), this.lang))
        .fontSize(13)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
  }

  @Builder
  scoreItem(labelKey: string, value: number) {
    Column({ space: 4 }) {
      Text(`${value}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.stat_value'))
      Text(I18n.t(labelKey, this.lang))
        .fontSize(11)
        .fontColor($r('app.color.text_muted'))
    }
    .layoutWeight(1)
  }
}
