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
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('综合评分')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        AiGenMark()
      }
      .width('100%')
      AiDisclaimerBar({ shortText: true })
      Column({ space: 2 }) {
        Text(`${this.report.score}`)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2563EB')
        Text('综合评分 · 满分 100')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F4F7FF')
      .borderRadius(16)
      Row() {
        this.scoreItem('score_acc', this.report.accuracy)
        this.scoreItem('score_depth', this.report.depth)
        this.scoreItem('score_exp', this.report.expression)
      }
      .width('100%')
      this.noteBlock('优势', this.report.advantages)
      this.noteBlock('待提升', this.report.problems)
      this.noteBlock('建议', this.report.suggestions)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
  }

  @Builder
  noteBlock(title: string, lines: string[]) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      if (lines.length === 0) {
        Text('暂无')
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
      } else {
        ForEach(lines, (line: string, index: number) => {
          Text(`${index + 1}. ${line}`)
            .fontSize(13)
            .fontColor($r('app.color.chip_idle_text'))
            .width('100%')
            .lineHeight(20)
        }, (line: string, index: number) => `${title}-${index}-${line}`)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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
