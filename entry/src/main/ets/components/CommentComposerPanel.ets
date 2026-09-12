import { common } from '@kit.AbilityKit';
import { promptAction, window } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { CommentEmojis } from '../common/utils/CommentEmojis';
import { CommentUi } from '../common/utils/CommentUi';
import { CommentRepository } from '../data/repository/CommentRepository';

@Component
export struct CommentComposerPanel {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('commentQuestionId') questionId: string = '';
  @StorageLink('commentReplyToId') replyToId: string = '';
  @StorageLink('commentReplyToName') replyToName: string = '';
  @StorageLink('commentDetailOpen') detailOpen: boolean = false;
  @State private draft: string = '';
  @State private posting: boolean = false;
  @State private showEmoji: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();
  private emojis: string[] = CommentEmojis.all();
  private areaCtrl: TextAreaController = new TextAreaController();
  private hostWin: window.Window | null = null;
  private kbListener: (h: number) => void = (_h: number) => {
  };

  aboutToAppear(): void {
    this.kbListener = (h: number) => {
      this.onKeyboardHeight(h);
    };
    this.bindKeyboard();
    this.scheduleFocus();
  }

  aboutToDisappear(): void {
    this.unbindKeyboard();
  }

  private onKeyboardHeight(px: number): void {
    if (px > 40) {
      this.showEmoji = false;
    }
  }

  private async bindKeyboard(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = await window.getLastWindow(ctx);
      this.hostWin = win;
      win.on('keyboardHeightChange', this.kbListener);
    } catch (_e) {
    }
  }

  private unbindKeyboard(): void {
    const win = this.hostWin;
    this.hostWin = null;
    if (win) {
      try {
        win.off('keyboardHeightChange');
      } catch (_e) {
      }
    }
  }

  private scheduleFocus(): void {
    setTimeout((): void => {
      this.tryFocus();
    }, 50);
    setTimeout((): void => {
      this.tryFocus();
    }, 220);
  }

  private tryFocus(): void {
    try {
      this.areaCtrl.caretPosition(this.draft.length);
    } catch (_e) {
    }
  }

  private placeholder(): string {
    if (this.replyToName.length > 0) {
      return `${I18n.t('comment_reply_ph', this.lang)}${this.replyToName}:`;
    }
    return I18n.t('blog_comment_ph', this.lang);
  }

  private canPost(): boolean {
    return this.draft.trim().length > 0 && !this.posting;
  }

  private insertEmoji(emoji: string): void {
    this.draft = `${this.draft}${emoji}`;
  }

  private toggleEmoji(): void {
    if (this.showEmoji) {
      this.showEmoji = false;
      this.scheduleFocus();
      return;
    }
    try {
      this.areaCtrl.stopEditing();
    } catch (_e) {
    }
    this.showEmoji = true;
  }

  private dismiss(): void {
    try {
      this.areaCtrl.stopEditing();
    } catch (_e) {
    }
    CommentUi.closeCompose();
  }

  private async submit(): Promise<void> {
    const text = this.draft.trim();
    if (text.length === 0 || this.posting) {
      return;
    }
    if (text.length > 500) {
      promptAction.showToast({ message: '评论最多 500 字' });
      return;
    }
    this.posting = true;
    try {
      const result = await this.repo.post(this.questionId, text, this.replyToId);
      if (typeof result === 'string') {
        promptAction.showToast({ message: result });
        return;
      }
      this.draft = '';
      this.showEmoji = false;
      try {
        this.areaCtrl.stopEditing();
      } catch (_e) {
      }
      if (result.status === 0) {
        const hint = result.hint.length > 0 ? result.hint : I18n.t('comment_rejected', this.lang);
        promptAction.showToast({ message: hint });
      } else if (result.status === 2) {
        const hint = result.hint.length > 0 ? result.hint : I18n.t('forum_pending', this.lang);
        promptAction.showToast({ message: hint });
      } else {
        promptAction.showToast({ message: I18n.t('comment_ok', this.lang) });
      }
      CommentUi.closeCompose();
      CommentUi.bumpReload();
      setTimeout((): void => {
        CommentUi.bumpReload();
      }, 80);
    } catch (_e) {
      promptAction.showToast({ message: I18n.t('comment_fail', this.lang) });
    } finally {
      this.posting = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.detailOpen ? '#00000000' : '#00000055')
        .onClick(() => {
          this.dismiss();
        })

      Column({ space: 8 }) {
        if (this.replyToName.length > 0) {
          Row() {
            Text(`${I18n.t('comment_reply_ph', this.lang)}${this.replyToName}`)
              .fontSize(12)
              .fontColor('#2563EB')
              .layoutWeight(1)
            Text('×')
              .fontSize(16)
              .fontColor('#9CA3AF')
              .onClick(() => {
                CommentUi.setStr(CommentUi.REPLY_ID, '');
                CommentUi.setStr(CommentUi.REPLY_NAME, '');
              })
          }
          .width('100%')
        }

        if (this.showEmoji) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.emojis, (e: string) => {
              Text(e)
                .fontSize(26)
                .padding(8)
                .onClick(() => {
                  this.insertEmoji(e);
                })
            }, (e: string) => e)
          }
          .width('100%')
          .height(180)
        }

        Row({ space: 8 }) {
          Row({ space: 8 }) {
            TextArea({
              text: this.draft,
              placeholder: this.placeholder(),
              controller: this.areaCtrl
            })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#00000000')
              .fontColor('#111827')
              .placeholderColor('#9CA3AF')
              .padding({ left: 0, right: 0, top: 6, bottom: 6 })
              .maxLength(500)
              .defaultFocus(true)
              .focusable(true)
              .onAppear(() => {
                this.tryFocus();
              })
              .onChange((v: string) => {
                this.draft = v;
              })
              .onEditChange((editing: boolean) => {
                if (editing) {
                  this.showEmoji = false;
                }
              })

            Image($r('app.media.ic_comment_emoji_line'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
              .fillColor(this.showEmoji ? '#2563EB' : '#9CA3AF')
              .flexShrink(0)
              .onClick(() => {
                this.toggleEmoji();
              })
          }
          .layoutWeight(1)
          .height(40)
          .padding({ left: 14, right: 12 })
          .backgroundColor('#F3F4F6')
          .borderRadius(20)
          .alignItems(VerticalAlign.Center)

          Text(this.posting ? I18n.t('comment_posting', this.lang) : I18n.t('forum_send', this.lang))
            .fontSize(14)
            .fontColor('#FFFFFF')
            .height(36)
            .padding({ left: 14, right: 14 })
            .borderRadius(18)
            .backgroundColor(this.canPost() ? '#2563EB' : '#93C5FD')
            .textAlign(TextAlign.Center)
            .opacity(this.posting ? 0.7 : 1)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 12, topRight: 12 })
      .shadow({ radius: 8, color: '#0F172A14', offsetY: -2 })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
  }
}
