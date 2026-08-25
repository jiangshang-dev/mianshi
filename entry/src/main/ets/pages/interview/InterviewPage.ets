import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { ResumeInsight, ResumeInsightBuilder } from '../../data/interview/ResumeInsight';
import { InterviewRoleCatalog } from '../../data/interview/InterviewRoleCatalog';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { InterviewOptionRepository } from '../../data/repository/InterviewOptionRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

interface SessionNavParams {
  role: string;
  level: string;
  difficulty: string;
}

@Component
export struct InterviewPage {
  @StorageLink('isLoggedIn')
  @Watch('onLoginStateChange')
  isLoggedIn: boolean = false;
  @StorageLink('globalResumeFileName')
  @Watch('onResumeMetaChange')
  resumeFileName: string = '';
  @StorageLink('appLang') lang: string = I18n.HANS;
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

  onLoginStateChange(): void {
    this.loadResume();
  }

  onResumeMetaChange(): void {
    this.resume = this.repo.getCached();
    this.applyResumeInsight();
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
    if (!this.isLoggedIn) {
      Column({ space: 16 }) {
        Text(I18n.t('tab_interview', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Column({ space: 12 }) {
          Text(I18n.t('interview_login_title', this.lang))
            .fontSize(15)
            .fontColor('#374151')
            .width('100%')
          Text(I18n.t('interview_login_sub', this.lang))
            .fontSize(13)
            .fontColor('#6B7280')
            .width('100%')
          Button(I18n.t('go_login', this.lang))
            .width('100%')
            .height(44)
            .backgroundColor('#2563EB')
            .onClick(() => {
              LoginGate.goLogin();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(14)
      }
      .padding({ left: 16, right: 16, top: 8 })
      .width('100%')
      .height('100%')
      .backgroundColor('#F3F4F6')
    } else {
    Scroll() {
      Column({ space: 10 }) {
        Text(I18n.t('tab_interview', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 8 }) {
            Text(I18n.t('pick_role', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).width('100%')
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
            Text(I18n.t('work_exp', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).width('100%')
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
            Text(I18n.t('iv_diff', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).width('100%')
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
            Text(I18n.t('mock_iv', this.lang))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            Text(I18n.tf('iv_soon', `${this.selectedRole} · ${this.selectedLevel} · ${this.selectedDiff}`, this.lang))
              .fontSize(13)
              .fontColor('#6B7280')
              .width('100%')
            Text(I18n.tf('iv_interviewer', this.interviewerTitle, this.lang))
              .fontSize(13)
              .fontColor('#2563EB')
              .width('100%')
            Text(I18n.tf('iv_focus', this.modulesText, this.lang))
              .fontSize(13)
              .fontColor('#374151')
              .width('100%')
            if (this.resume) {
              Text(I18n.tf('iv_resume_using', this.resume.fileName, this.lang))
                .fontSize(13)
                .fontColor('#2563EB')
                .width('100%')
              if (this.recommended) {
                Text(I18n.t('iv_resume_ok', this.lang))
                  .fontSize(12)
                  .fontColor('#6B7280')
                  .width('100%')
              }
              if (!ResumeInsightBuilder.isParsedText(this.resume.textPreview)) {
                Text(I18n.t('iv_resume_parse', this.lang))
                  .fontSize(12)
                  .fontColor('#F59E0B')
                  .width('100%')
              }
            } else {
              Text(I18n.t('iv_no_resume', this.lang))
                .fontSize(13)
                .fontColor('#F59E0B')
                .width('100%')
              Text(I18n.t('iv_go_resume', this.lang))
                .fontSize(13)
                .fontColor('#2563EB')
                .onClick(() => {
                  AppStorage.setOrCreate('mainTabIndex', 4);
                })
            }
            Text(I18n.t('iv_support', this.lang))
              .fontSize(13)
              .fontColor('#6B7280')
              .lineHeight(20)
              .width('100%')
            Button(I18n.t('iv_start', this.lang))
              .width('100%')
              .height(44)
              .backgroundColor('#2563EB')
              .onClick(async () => {
                if (!LoginGate.isLoggedIn()) {
                  LoginGate.goLogin();
                  return;
                }
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
}
