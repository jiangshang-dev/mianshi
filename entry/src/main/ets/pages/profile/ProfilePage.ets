import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

@Component
export struct ProfilePage {
  @StorageLink('isLoggedIn')
  @Watch('onLoginStateChange')
  isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @StorageLink('globalResumeFileName')
  @Watch('onResumeMetaChange')
  resumeFileName: string = '';
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private resume: ResumeProfile | null = null;
  @State private uploading: boolean = false;

  private repo: ResumeRepository = ResumeRepository.getInstance();
  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.bootstrap();
  }

  onLoginStateChange(): void {
    this.loadResume();
  }

  onResumeMetaChange(): void {
    this.resume = this.repo.getCached();
  }

  private async bootstrap(): Promise<void> {
    await this.refreshUser();
    await this.loadResume();
  }

  private async refreshUser(): Promise<void> {
    const ctx = this.hostContext();
    await this.auth.load(ctx);
    this.auth.syncAppStorage();
  }

  private hostContext(): common.UIAbilityContext {
    const host = this.getUIContext().getHostContext();
    if (host) {
      return host as common.UIAbilityContext;
    }
    return getContext(this) as common.UIAbilityContext;
  }

  private async loadResume(): Promise<void> {
    if (this.uploading) {
      return;
    }
    const ctx = this.hostContext();
    this.resume = await this.repo.load(ctx);
  }

  private goLogin(): void {
    router.pushUrl({ url: 'pages/profile/LoginPage' });
  }

  private goSettings(): void {
    router.pushUrl({ url: 'pages/profile/SettingsPage' });
  }

  private openNeedLogin(feature: string, url: string, scene?: string, pageTitle?: string): void {
    LoginGate.ensure(feature, () => {
      if (scene !== undefined && pageTitle !== undefined) {
        router.pushUrl({
          url: url,
          params: {
            'scene': scene,
            'title': pageTitle
          }
        });
      } else {
        router.pushUrl({ url: url });
      }
    });
  }

  private onProfileCardClick(): void {
    if (!this.isLoggedIn) {
      this.goLogin();
    }
  }

  private soon(name: string): void {
    promptAction.showToast({ message: I18n.tf('soon', name, this.lang) });
  }

  private async pickResume(): Promise<void> {
    if (!this.isLoggedIn) {
      this.goLogin();
      return;
    }
    if (this.uploading) {
      return;
    }
    this.uploading = true;
    try {
      const ctx = this.hostContext();
      const profile = await this.repo.pickAndSave(ctx);
      if (profile) {
        this.resume = profile;
        promptAction.showToast({ message: I18n.t('resume_saved', this.lang) });
      } else {
        const errMsg = this.repo.consumePickError();
        if (errMsg.length > 0) {
          promptAction.showToast({ message: errMsg });
        }
      }
    } finally {
      this.uploading = false;
    }
  }

  private async removeResume(): Promise<void> {
    const ctx = this.hostContext();
    await this.repo.clear(ctx);
    this.resume = null;
    promptAction.showToast({ message: I18n.t('resume_deleted', this.lang) });
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text(I18n.t('tab_profile', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Row({ space: 12 }) {
          if (this.isLoggedIn && this.avatarUrl.length > 0) {
            Image(this.avatarUrl)
              .width(48)
              .height(48)
              .borderRadius(24)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text(this.isLoggedIn ? '华' : '👤')
                .fontSize(this.isLoggedIn ? 18 : 22)
                .fontColor(this.isLoggedIn ? $r('app.color.text_on_color') : $r('app.color.text_muted'))
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isLoggedIn ? '#CF0A2C' : '#E5E7EB')
          }

          Column({ space: 2 }) {
            Text(this.isLoggedIn ?
              (this.displayName.length > 0 ? this.displayName : I18n.t('huawei_user', this.lang)) : I18n.t('go_login', this.lang))
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isLoggedIn ? $r('app.color.text_primary') : $r('app.color.accent'))
            Text(this.isLoggedIn ? I18n.t('huawei_on', this.lang) : I18n.t('tap_login', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (!this.isLoggedIn) {
            Text('›')
              .fontSize(18)
              .fontColor($r('app.color.chevron'))
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)
        .onClick(() => {
          this.onProfileCardClick();
        })

        Column({ space: 10 }) {
          Row() {
            Column({ space: 2 }) {
              Text(I18n.t('my_resume', this.lang))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text(this.resume ?
                (this.resume.fileUrl.length > 0 ?
                  I18n.t('resume_cloud', this.lang) : I18n.t('resume_local', this.lang)) :
                (this.isLoggedIn ? I18n.t('resume_upload_tip', this.lang) : I18n.t('resume_login_sync', this.lang)))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')

          if (this.resume) {
            Column({ space: 6 }) {
              Row({ space: 8 }) {
                Text('📄')
                  .fontSize(18)
                Column({ space: 2 }) {
                  Text(this.resume.fileName)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${this.repo.formatFileSize(this.resume.fileSize)} · ` +
                    `${this.repo.formatUploadTime(this.resume.uploadedAt)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              Text(this.resume.textPreview)
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .lineHeight(18)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding(10)
                .backgroundColor($r('app.color.preview_bg'))
                .borderRadius(8)

              Row({ space: 8 }) {
                Button(this.uploading ? I18n.t('uploading', this.lang) : I18n.t('replace_resume', this.lang))
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(14)
                  .backgroundColor('#EFF6FF')
                  .fontColor($r('app.color.accent'))
                  .onClick(() => {
                    this.pickResume();
                  })
                Button(I18n.t('delete', this.lang))
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(14)
                  .backgroundColor('#FEF2F2')
                  .fontColor('#DC2626')
                  .onClick(() => {
                    this.removeResume();
                  })
              }
              .width('100%')
            }
          } else {
            Button(this.uploading ? I18n.t('picking', this.lang) :
              (this.isLoggedIn ? I18n.t('upload_resume', this.lang) : I18n.t('upload_after_login', this.lang)))
              .width('100%')
              .height(42)
              .fontSize(14)
              .backgroundColor('#2563EB')
              .onClick(() => {
                this.pickResume();
              })
            Text(this.isLoggedIn ? I18n.t('resume_fmt', this.lang) : I18n.t('resume_account', this.lang))
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)

        Column() {
          this.menuRow('favorites', 'fav_sub', () => {
            this.openNeedLogin(I18n.t('favorites', this.lang), 'pages/profile/FavoritesPage');
          })
          this.menuRow('ai_qa', 'ai_qa_sub', () => {
            this.openNeedLogin(I18n.t('ai_qa_title', this.lang), 'pages/profile/AiHistoryPage', 'chat',
              I18n.t('ai_qa_title', this.lang));
          })
          this.menuRow('iv_logs', 'iv_logs_sub', () => {
            this.openNeedLogin(I18n.t('iv_logs', this.lang), 'pages/profile/AiHistoryPage', 'interview',
              I18n.t('iv_logs', this.lang));
          })
          // this.menuRow('study_log', 'study_log_sub', () => {
          //   this.soon(I18n.t('study_log', this.lang));
          // })
        }
        .width('100%')
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)
        .padding({ left: 16, right: 16 })

        Column() {
          this.menuRow('settings', 'settings_sub', () => {
            this.goSettings();
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)
        .padding({ left: 16, right: 16 })
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
  menuRow(titleKey: string, subtitleKey: string, onTap: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(I18n.t(titleKey, this.lang)).fontSize(15).fontColor($r('app.color.text_primary'))
        Text(I18n.t(subtitleKey, this.lang)).fontSize(12).fontColor($r('app.color.text_muted')).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(18).fontColor($r('app.color.chevron'))
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .onClick(() => {
      onTap();
    })
  }
}
