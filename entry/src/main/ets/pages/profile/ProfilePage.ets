import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { ResumeRepository } from '../../data/repository/ResumeRepository';

@Component
export struct ProfilePage {
  @StorageLink('isLoggedIn')
  @Watch('onLoginStateChange')
  isLoggedIn: boolean = false;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @State private resume: ResumeProfile | null = null;
  @State private uploading: boolean = false;

  private repo: ResumeRepository = ResumeRepository.getInstance();
  private auth: AuthRepository = AuthRepository.getInstance();

  aboutToAppear(): void {
    this.refreshUser();
    this.loadResume();
  }

  onLoginStateChange(): void {
    this.loadResume();
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

  private onProfileCardClick(): void {
    if (!this.isLoggedIn) {
      this.goLogin();
    }
  }

  private soon(name: string): void {
    promptAction.showToast({ message: `${name}即将上线` });
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
        promptAction.showToast({ message: '简历已保存，正在同步到云端' });
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
    promptAction.showToast({ message: '简历已删除' });
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
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
                .fontColor(this.isLoggedIn ? Color.White : '#9CA3AF')
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isLoggedIn ? '#CF0A2C' : '#E5E7EB')
          }

          Column({ space: 2 }) {
            Text(this.isLoggedIn ?
              (this.displayName.length > 0 ? this.displayName : '华为用户') : '去登录')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isLoggedIn ? '#111827' : '#2563EB')
            Text(this.isLoggedIn ? '华为账号 · 已登录' : '点击登录，同步学习数据')
              .fontSize(12)
              .fontColor('#9CA3AF')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (!this.isLoggedIn) {
            Text('›')
              .fontSize(18)
              .fontColor('#D1D5DB')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .onClick(() => {
          this.onProfileCardClick();
        })

        Column({ space: 10 }) {
          Row() {
            Column({ space: 2 }) {
              Text('我的简历')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')
              Text(this.resume ?
                (this.resume.fileUrl.length > 0 ?
                  '已上传到云端，模拟面试会用这一份' : '已作为全局简历，模拟面试会用这一份') :
                (this.isLoggedIn ? '上传简历，AI 面试更精准' : '登录后自动同步云端简历'))
                .fontSize(12)
                .fontColor('#9CA3AF')
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
                    .fontColor('#111827')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${this.repo.formatFileSize(this.resume.fileSize)} · ` +
                    `${this.repo.formatUploadTime(this.resume.uploadedAt)}`)
                    .fontSize(12)
                    .fontColor('#9CA3AF')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              Text(this.resume.textPreview)
                .fontSize(12)
                .fontColor('#6B7280')
                .lineHeight(18)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .padding(10)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)

              Row({ space: 8 }) {
                Button(this.uploading ? '上传中…' : '更换简历')
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(14)
                  .backgroundColor('#EFF6FF')
                  .fontColor('#2563EB')
                  .onClick(() => {
                    this.pickResume();
                  })
                Button('删除')
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
            Button(this.uploading ? '选择文件中…' :
              (this.isLoggedIn ? '上传简历（PDF / Word / TXT）' : '登录后上传简历'))
              .width('100%')
              .height(42)
              .fontSize(14)
              .backgroundColor('#2563EB')
              .onClick(() => {
                this.pickResume();
              })
            Text(this.isLoggedIn ? '支持 PDF、Word、TXT、Markdown' : '简历跟账号走，退出后本机不保留')
              .fontSize(11)
              .fontColor('#9CA3AF')
              .width('100%')
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Color.White)
        .borderRadius(14)

        Column() {
          this.menuRow('收藏夹', '收藏的题目', () => {
            this.soon('收藏夹');
          })
          this.menuRow('学习记录', '刷题天数与进度', () => {
            this.soon('学习记录');
          })
          this.menuRow('错题本', '回顾答错的题目', () => {
            this.soon('错题本');
          })
          this.menuRow('面试记录', '模拟面试历史', () => {
            this.soon('面试记录');
          })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding({ left: 16, right: 16 })

        Column() {
          this.menuRow('设置', '通知、缓存与退出登录', () => {
            this.goSettings();
          })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding({ left: 16, right: 16 })
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
  menuRow(title: string, subtitle: string, onTap: () => void) {
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
    .onClick(() => {
      onTap();
    })
  }
}
