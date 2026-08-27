import { TodayStudyStats } from '../../common/models/Types';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

@Component
export struct StudyPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  private repo: QuestionRepository = QuestionRepository.getInstance();
  @State private stats: TodayStudyStats = {
    questionCount: 0,
    minutes: 0,
    mastered: 0,
    toReview: 0
  };

  aboutToAppear(): void {
    this.loadStats();
  }

  private async loadStats(): Promise<void> {
    try {
      this.stats = await this.repo.getTodayStudyStats();
    } catch (_e) {
      this.stats = { questionCount: 0, minutes: 0, mastered: 0, toReview: 0 };
    }
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        // Text(I18n.t('tab_study', this.lang))
        //   .fontSize(20)
        //   .fontWeight(FontWeight.Bold)
        //   .width('100%')

        Column({ space: 10 }) {
          Text(I18n.t('today_progress', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
          Row() {
            this.cell(`${this.stats.questionCount}`, 'done_q')
            this.cell(`${this.stats.minutes}`, 'study_min')
            this.cell(`${this.stats.mastered}`, 'done_master')
            this.cell(`${this.stats.toReview}`, 'stat_review')
          }.width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)

        Column({ space: 8 }) {
          Text(I18n.t('cal_ph', this.lang))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text(I18n.t('cal_hint', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .width('100%')
          Row({ space: 6 }) {
            ForEach(I18n.weekdays(this.lang), (d: string) => {
              Column() {
                Text(d).fontSize(11).fontColor($r('app.color.text_muted'))
                Column()
                  .width(18)
                  .height(18)
                  .borderRadius(4)
                  .backgroundColor('#BFDBFE')
                  .margin({ top: 6 })
              }.layoutWeight(1)
            }, (d: string) => d)
          }.width('100%').margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)

        Column({ space: 8 }) {
          Text(I18n.t('weak_ph', this.lang))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          ForEach(['Redis 集群', 'MySQL 索引失效', 'JVM G1', '分布式锁'], (t: string) => {
            Row() {
              Text(t).fontSize(14).fontColor($r('app.color.text_primary')).layoutWeight(1)
              Text(I18n.t('go_review', this.lang)).fontSize(12).fontColor($r('app.color.accent'))
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
          }, (t: string) => t)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  @Builder
  cell(value: string, labelKey: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.stat_value'))
      Text(I18n.t(labelKey, this.lang)).fontSize(11).fontColor($r('app.color.text_muted'))
    }.layoutWeight(1)
  }
}
