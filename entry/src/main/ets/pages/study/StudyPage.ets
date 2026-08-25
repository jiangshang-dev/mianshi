import { TodayStudyStats } from '../../common/models/Types';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct StudyPage {
  private repo: QuestionRepository = QuestionRepository.getInstance();
  @State private stats: TodayStudyStats = {
    questionCount: 0,
    minutes: 0,
    mastered: 0,
    toReview: 0
  };

  aboutToAppear(): void {
    this.stats = this.repo.getTodayStudyStats();
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text('学习')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 10 }) {
          Text('今日进度').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
          Row() {
            this.cell(`${this.stats.questionCount}`, '已刷题')
            this.cell(`${this.stats.minutes}`, '学习分钟')
            this.cell(`${this.stats.mastered}`, '已掌握')
            this.cell(`${this.stats.toReview}`, '待复习')
          }.width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(14)

        Column({ space: 8 }) {
          Text('学习日历（占位）')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('后续可接入连续打卡与 GitHub 风格贡献图。')
            .fontSize(13)
            .fontColor('#6B7280')
            .width('100%')
          Row({ space: 6 }) {
            ForEach(['一', '二', '三', '四', '五', '六', '日'], (d: string) => {
              Column() {
                Text(d).fontSize(11).fontColor('#9CA3AF')
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
        .backgroundColor(Color.White)
        .borderRadius(14)

        Column({ space: 8 }) {
          Text('薄弱知识（占位）')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          ForEach(['Redis 集群', 'MySQL 索引失效', 'JVM G1', '分布式锁'], (t: string) => {
            Row() {
              Text(t).fontSize(14).fontColor('#111827').layoutWeight(1)
              Text('去复习 ›').fontSize(12).fontColor('#2563EB')
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .border({ width: { bottom: 0.5 }, color: '#F3F4F6' })
          }, (t: string) => t)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(14)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  @Builder
  cell(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1E40AF')
      Text(label).fontSize(11).fontColor('#6B7280')
    }.layoutWeight(1)
  }
}
