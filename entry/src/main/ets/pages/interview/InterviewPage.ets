import { router } from '@kit.ArkUI';

interface SessionNavParams {
  role: string;
  level: string;
  difficulty: string;
}

@Component
export struct InterviewPage {
  private roles: string[] = ['Java 后端', '高级 Java', 'AI 应用开发', '前端', '测试开发'];
  private levels: string[] = ['应届', '1～3 年', '3～5 年', '5 年以上'];
  private difficulties: string[] = ['简单', '中等', '困难', '大厂'];
  @State private selectedRole: string = 'Java 后端';
  @State private selectedLevel: string = '1～3 年';
  @State private selectedDiff: string = '中等';

  build() {
    Column() {
      Text('AI 面试')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('选择岗位').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.roles, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedRole === r ? Color.White : '#374151')
                  .backgroundColor(this.selectedRole === r ? '#2563EB' : Color.White)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .borderRadius(16)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.selectedRole = r;
                  })
              }, (r: string) => r)
            }.width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(14)

          Column({ space: 8 }) {
            Text('工作经验').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.levels, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedLevel === r ? Color.White : '#374151')
                  .backgroundColor(this.selectedLevel === r ? '#2563EB' : Color.White)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .borderRadius(16)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.selectedLevel = r;
                  })
              }, (r: string) => r)
            }.width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(14)

          Column({ space: 8 }) {
            Text('面试难度').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.difficulties, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedDiff === r ? Color.White : '#374151')
                  .backgroundColor(this.selectedDiff === r ? '#2563EB' : Color.White)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .borderRadius(16)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.selectedDiff = r;
                  })
              }, (r: string) => r)
            }.width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(14)

          Column({ space: 10 }) {
            Text('模拟面试')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            Text(`即将开始：${this.selectedRole} · ${this.selectedLevel} · ${this.selectedDiff}`)
              .fontSize(13)
              .fontColor('#6B7280')
              .width('100%')
            Text('支持文字聊天与 AI 语音对话，自动追问并生成面试报告。')
              .fontSize(13)
              .fontColor('#6B7280')
              .lineHeight(20)
              .width('100%')
            Button('开始模拟面试')
              .width('100%')
              .height(44)
              .backgroundColor('#2563EB')
              .onClick(() => {
                const navParams: SessionNavParams = {
                  role: this.selectedRole,
                  level: this.selectedLevel,
                  difficulty: this.selectedDiff
                };
                router.pushUrl({
                  url: 'pages/interview/InterviewSessionPage',
                  params: navParams
                });
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(14)
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
}
