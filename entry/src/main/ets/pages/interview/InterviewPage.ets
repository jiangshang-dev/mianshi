import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { ResumeInsight, ResumeInsightBuilder } from '../../data/interview/ResumeInsight';
import { InterviewRoleCatalog } from '../../data/interview/InterviewRoleCatalog';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { InterviewOptionRepository } from '../../data/repository/InterviewOptionRepository';

interface SessionNavParams {
  role: string;
  level: string;
  difficulty: string;
}

@Component
export struct InterviewPage {
  @State private roles: string[] = InterviewRoleCatalog.names();
  @State private levels: string[] = InterviewRoleCatalog.levelNames();
  @State private difficulties: string[] = InterviewRoleCatalog.difficulties;
  @State private selectedRole: string = InterviewRoleCatalog.defaultRole();
  @State private selectedLevel: string = InterviewRoleCatalog.defaultLevel();
  @State private selectedDiff: string = InterviewRoleCatalog.defaultDifficulty;
  @State private resume: ResumeProfile | null = null;
  @State private recommended: boolean = false;
  @State private interviewerTitle: string = InterviewRoleCatalog.interviewerTitle(InterviewRoleCatalog.defaultRole());
  @State private modulesText: string = '岗位核心技能、系统设计、简历项目深挖';

  private repo: ResumeRepository = ResumeRepository.getInstance();
  private optionRepo: InterviewOptionRepository = InterviewOptionRepository.getInstance();

  aboutToAppear(): void {
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    const opts = await this.optionRepo.load();
    this.roles = opts.roles;
    this.levels = opts.levels;
    this.difficulties = opts.difficulties;
    await this.loadResume();
    if (this.roles.indexOf(this.selectedRole) < 0) {
      this.selectedRole = opts.defaultRole;
    }
    if (this.levels.indexOf(this.selectedLevel) < 0) {
      this.selectedLevel = opts.defaultLevel;
    }
    if (this.difficulties.indexOf(this.selectedDiff) < 0) {
      this.selectedDiff = opts.defaultDifficulty;
    }
    this.refreshTrack();
  }

  private async loadResume(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.resume = await this.repo.load(ctx);
    this.applyResumeInsight();
  }

  private applyResumeInsight(): void {
    const insight: ResumeInsight = ResumeInsightBuilder.from(this.resume);
    if (this.resume) {
      if (this.roles.indexOf(insight.role) >= 0) {
        this.selectedRole = insight.role;
      }
      if (this.levels.indexOf(insight.level) >= 0) {
        this.selectedLevel = insight.level;
      }
      this.recommended = true;
    }
    this.refreshTrack();
  }

  private refreshTrack(): void {
    this.interviewerTitle = ResumeInsightBuilder.interviewerOf(this.selectedRole);
    this.modulesText = ResumeInsightBuilder.modulesOf(this.resume, this.selectedRole).join('、');
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
                    this.recommended = false;
                    this.refreshTrack();
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
                    this.recommended = false;
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
            Text(`面试官：${this.interviewerTitle}`)
              .fontSize(13)
              .fontColor('#2563EB')
              .width('100%')
            Text(`考察方向：${this.modulesText}`)
              .fontSize(13)
              .fontColor('#374151')
              .width('100%')
            if (this.resume) {
              Text(`当前使用「我的」简历：${this.resume.fileName}`)
                .fontSize(13)
                .fontColor('#2563EB')
                .width('100%')
              if (this.recommended) {
                Text('已根据这份简历推荐岗位、面试官和考察方向')
                  .fontSize(12)
                  .fontColor('#6B7280')
                  .width('100%')
              }
              if (!ResumeInsightBuilder.isParsedText(this.resume.textPreview)) {
                Text('云端正在解析这份 PDF/Word。解析完成后面试官就能按项目点名提问。')
                  .fontSize(12)
                  .fontColor('#F59E0B')
                  .width('100%')
              }
            } else {
              Text('尚未上传全局简历。模拟面试会使用「我的」页那一份，请先去上传。')
                .fontSize(13)
                .fontColor('#F59E0B')
                .width('100%')
              Text('去「我的」上传简历')
                .fontSize(13)
                .fontColor('#2563EB')
                .onClick(() => {
                  AppStorage.setOrCreate('mainTabIndex', 4);
                })
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
                this.refreshTrack();
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
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        .width('100%')
      }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .onAppear(() => {
      this.bootstrap();
    })
  }
}
