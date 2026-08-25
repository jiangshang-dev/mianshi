import { InterviewReport } from '../common/models/InterviewTypes';
import { I18n } from '../common/i18n/I18n';

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
      Text(I18n.t('iv_report', this.lang))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text(I18n.tf('total_score', `${this.report.score}`, this.lang))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2563EB')
        .width('100%')
      Row() {
        this.scoreItem('score_acc', this.report.accuracy)
        this.scoreItem('score_depth', this.report.depth)
        this.scoreItem('score_exp', this.report.expression)
      }
      .width('100%')
      Text(I18n.tf('adv_label', this.report.advantages.join('；'), this.lang))
        .fontSize(13)
        .fontColor('#374151')
        .width('100%')
      Text(I18n.tf('prob_label', this.report.problems.join('；'), this.lang))
        .fontSize(13)
        .fontColor('#374151')
        .width('100%')
      Text(I18n.tf('sugg_label', this.report.suggestions.join('；'), this.lang))
        .fontSize(13)
        .fontColor('#6B7280')
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

  @Builder
  scoreItem(labelKey: string, value: number) {
    Column({ space: 4 }) {
      Text(`${value}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E40AF')
      Text(I18n.t(labelKey, this.lang))
        .fontSize(11)
        .fontColor('#6B7280')
    }
    .layoutWeight(1)
  }
}
