import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { ResumeRepository } from '../../data/repository/ResumeRepository';

interface SessionNavParams {
  role: string;
  level: string;
  difficulty: string;
  resumeId: string;
  resumePreview: string;
  resumeFileName: string;
}

@Component
export struct InterviewPage {
  private roles: string[] = ['Java 后端', '高级 Java', 'AI 应用开发', '前端', '测试开发'];
  private levels: string[] = ['应届', '1～3 年', '3～5 年', '5 年以上'];
  private difficulties: string[] = ['简单', '中等', '困难', '大厂'];
  @State private selectedRole: string = 'Java 后端';
  @State private selectedLevel: string = '1～3 年';
  @State private selectedDiff: string = '中等';
  @State private resume: ResumeProfile | null = null;

  private repo: ResumeRepository = ResumeRepository.getInstance();

  aboutToAppear(): void {
    this.loadResume();
  }

  private async loadResume(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.resume = await this.repo.load(ctx);
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text('AI 面试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

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
            if (this.resume) {
              Text(`已关联简历：${this.resume.fileName}`)
                .fontSize(13)
                .fontColor('#2563EB')
                .width('100%')
            } else {
              Text('未上传简历，建议在「我的」页上传以获得更精准的面试提问')
                .fontSize(13)
                .fontColor('#F59E0B')
                .width('100%')
            }
            Text('支持文字聊天与 AI 语音对话，自动追问并生成面试报告。')
              .fontSize(13)
              .fontColor('#6B7280')
              .lineHeight(20)
              .width('100%')
            Button('开始模拟面试')
              .width('100%')
              .height(44)
              .backgroundColor('#2563EB')
              .onClick(async () => {
                const ctx = getContext(this) as common.UIAbilityContext;
                this.resume = await this.repo.load(ctx);
                const navParams: SessionNavParams = {
                  role: this.selectedRole,
                  level: this.selectedLevel,
                  difficulty: this.selectedDiff,
                  resumeId: this.resume?.resumeId ?? '',
                  resumePreview: this.resume?.textPreview ?? '',
                  resumeFileName: this.resume?.fileName ?? ''
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
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        .width('100%')
      }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
}
