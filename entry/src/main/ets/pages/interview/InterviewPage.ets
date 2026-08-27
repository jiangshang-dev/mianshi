import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { ResumeInsight, ResumeInsightBuilder } from '../../data/interview/ResumeInsight';
import { InterviewRoleCatalog } from '../../data/interview/InterviewRoleCatalog';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { InterviewOptionRepository } from '../../data/repository/InterviewOptionRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { AiNotice } from '../../common/utils/AiNotice';
import { I18n } from '../../common/i18n/I18n';
import { AiDisclaimerBar, AiGenMark } from '../../components/AiGenMark';

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

  private async launchSession(): Promise<void> {
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
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text(I18n.t('tab_interview', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Column({ space: 8 }) {
            Text(I18n.t('pick_role', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.roles, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedRole === r ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
                  .backgroundColor(this.selectedRole === r ? $r('app.color.accent') : $r('app.color.chip_idle_bg'))
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
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Column({ space: 8 }) {
            Text(I18n.t('work_exp', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.levels, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedLevel === r ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
                  .backgroundColor(this.selectedLevel === r ? $r('app.color.accent') : $r('app.color.chip_idle_bg'))
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
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Column({ space: 8 }) {
            Text(I18n.t('iv_diff', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.difficulties, (r: string) => {
                Text(r)
                  .fontSize(13)
                  .fontColor(this.selectedDiff === r ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
                  .backgroundColor(this.selectedDiff === r ? $r('app.color.accent') : $r('app.color.chip_idle_bg'))
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
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Column({ space: 10 }) {
            Text(I18n.t('mock_iv', this.lang))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            Text(I18n.tf('iv_soon', `${this.selectedRole} · ${this.selectedLevel} · ${this.selectedDiff}`, this.lang))
              .fontSize(13)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
            Text(I18n.tf('iv_interviewer', this.interviewerTitle, this.lang))
              .fontSize(13)
              .fontColor($r('app.color.accent'))
              .width('100%')
            Text(I18n.tf('iv_focus', this.modulesText, this.lang))
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
            if (!this.isLoggedIn) {
              Text(I18n.t('iv_guest_resume', this.lang))
                .fontSize(13)
                .fontColor($r('app.color.text_muted'))
                .width('100%')
            } else if (this.resume) {
              Text(I18n.tf('iv_resume_using', this.resume.fileName, this.lang))
                .fontSize(13)
                .fontColor($r('app.color.accent'))
                .width('100%')
              if (this.recommended) {
                Text(I18n.t('iv_resume_ok', this.lang))
                  .fontSize(12)
                  .fontColor($r('app.color.text_muted'))
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
                .fontColor($r('app.color.accent'))
                .onClick(() => {
                  AppStorage.setOrCreate('mainTabIndex', 3);
                })
            }
            Text(I18n.t('iv_support', this.lang))
              .fontSize(13)
              .fontColor($r('app.color.text_muted'))
              .lineHeight(20)
              .width('100%')
            Row({ space: 6 }) {
              AiGenMark()
              Text(I18n.t('ai_disclaimer_short', this.lang))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            AiDisclaimerBar()
            if (!this.isLoggedIn) {
              Row({ space: 8 }) {
                Text(I18n.t('iv_guest_badge', this.lang))
                  .fontSize(11)
                  .fontColor('#B45309')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor('#FEF3C7')
                  .borderRadius(6)
                Text(I18n.t('iv_guest_cta_sub', this.lang))
                  .fontSize(12)
                  .fontColor($r('app.color.text_muted'))
                  .layoutWeight(1)
                  .maxLines(2)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor('#FFFBEB')
              .borderRadius(10)
            }
            Button(this.isLoggedIn ? I18n.t('iv_start', this.lang) : I18n.t('iv_start_login', this.lang))
              .width('100%')
              .height(44)
              .backgroundColor('#2563EB')
              .onClick(async () => {
                if (!LoginGate.isLoggedIn()) {
                  LoginGate.goLogin();
                  return;
                }
                const ctx = getContext(this) as common.UIAbilityContext;
                AiNotice.ensure(ctx, () => {
                  this.launchSession();
                });
              })
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
    .onAppear(() => {
      this.bootstrap();
    })
  }
}
