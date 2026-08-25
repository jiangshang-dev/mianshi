import { AppConfig } from '../../common/constants/AppConfig';

@Component
export struct ProfilePage {
  build() {
    Column() {
      Text('我的')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 12 }) {
            Column() {
              Text('面')
                .fontSize(22)
                .fontColor(Color.White)
            }
            .width(56)
            .height(56)
            .borderRadius(28)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#2563EB')

            Column({ space: 4 }) {
              Text('面试选手')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              Text('本地 MD + 远程 API 双数据源')
                .fontSize(12)
                .fontColor('#6B7280')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(14)

          Column() {
            this.menuRow('收藏夹', '本地暂存')
            this.menuRow('学习记录', '今日 / 连续天数')
            this.menuRow('数据源', `API: ${AppConfig.REMOTE_API_BASE}`)
            this.menuRow('关于', AppConfig.APP_NAME)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .padding({ left: 16, right: 16 })
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  menuRow(title: string, subtitle: string) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontColor('#111827')
        Text(subtitle).fontSize(12).fontColor('#9CA3AF').maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(18).fontColor('#D1D5DB')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: '#F3F4F6' })
  }
}
