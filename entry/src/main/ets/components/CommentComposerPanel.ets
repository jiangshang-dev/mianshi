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
  @State private kbHeight: number = 0;
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
    let vp = 0;
    try {
      vp = this.getUIContext().px2vp(px);
    } catch (_e) {
      vp = px > 0 ? px / 3.25 : 0;
    }
    this.kbHeight = vp > 1 ? vp : 0;
    if (this.kbHeight > 20) {
      this.showEmoji = false;
    }
  }

  private async bindKeyboard(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = await window.getLastWindow(ctx);
      this.hostWin = win;
      win.on('keyboardHeightChange', this.kbListener);
      const area = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
      if (area && area.bottomRect) {
        this.onKeyboardHeight(area.bottomRect.height);
      }
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
    return I18n.t('comment_ph', this.lang);
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
        TextArea({
          text: this.draft,
          placeholder: this.placeholder(),
          controller: this.areaCtrl
        })
          .height(68)
          .backgroundColor('#F4F4F4')
          .fontColor('#18191C')
          .placeholderColor('#9499A0')
          .borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
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

        Row() {
          Column() {
            Image($r('app.media.ic_comment_emoji_line'))
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
          }
          .width(36)
          .height(36)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.toggleEmoji();
          })
          Blank()
          Text(this.posting ? I18n.t('comment_posting', this.lang) : I18n.t('comment_send', this.lang))
            .fontSize(13)
            .fontColor('#FFFFFF')
            .height(28)
            .padding({ left: 14, right: 14 })
            .borderRadius(14)
            .backgroundColor(this.canPost() ? '#FB7299' : '#FFB6C9')
            .textAlign(TextAlign.Center)
            .opacity(this.posting ? 0.7 : 1)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

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
        } else {
          Scroll() {
            Row({ space: 2 }) {
              ForEach(this.emojis, (e: string) => {
                Text(e)
                  .fontSize(26)
                  .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.insertEmoji(e);
                  })
              }, (e: string) => `strip-${e}`)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .height(44)
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .margin({ bottom: this.kbHeight })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 12, topRight: 12 })
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
  }
}
