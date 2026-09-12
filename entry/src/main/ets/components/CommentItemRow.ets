import { promptAction } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { LoginGate } from '../common/utils/LoginGate';
import { CommentUi } from '../common/utils/CommentUi';
import { ContentReportNav } from '../common/utils/ContentReportNav';
import { ForumUi } from '../common/utils/ForumUi';
import { CommentRepository, emptyQuestionComment, QuestionComment } from '../data/repository/CommentRepository';

interface DialogResult {
  index: number;
}

@Component
export struct CommentItemRow {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop @Watch('syncFromItem') item: QuestionComment = emptyQuestionComment();
  @Prop inDetail: boolean = false;
  @Prop showRepliesLink: boolean = false;
  @Prop nested: boolean = false;
  @Prop indent: number = 0;
  onReply: (id: string, name: string) => void = (id: string, name: string) => {
    CommentUi.openCompose(id, name);
  };
  @State private likeCount: number = 0;
  @State private myVote: number = 0;
  @State private voting: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();

  aboutToAppear(): void {
    this.syncFromItem();
  }

  syncFromItem(): void {
    this.likeCount = this.item.likeCount;
    this.myVote = this.item.myVote;
  }

  private indentLeft(): number {
    const level = this.indent > 4 ? 4 : this.indent;
    return level * 12;
  }

  private isMine(): boolean {
    const uid = LoginGate.currentUserId();
    return uid.length > 0 && uid === this.item.userId;
  }

  private vote(action: number): void {
    LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
      this.doVote(action);
    });
  }

  private replyTotal(): number {
    if (this.item.replyCount > 0) {
      return this.item.replyCount;
    }
    return this.item.replies.length;
  }

  private likeColor(active: boolean): ResourceColor {
    return active ? $r('app.color.accent') : $r('app.color.chevron');
  }

  private async doVote(action: number): Promise<void> {
    if (this.voting || this.item.id.length === 0) {
      return;
    }
    this.voting = true;
    try {
      const result = await this.repo.vote(this.item.id, action);
      if (typeof result === 'string') {
        promptAction.showToast({ message: result });
        return;
      }
      this.likeCount = result.likeCount;
      this.myVote = result.myVote;
      CommentUi.bumpReload();
    } catch (_e) {
      promptAction.showToast({ message: I18n.t('comment_vote_fail', this.lang) });
    } finally {
      this.voting = false;
    }
  }

  private confirmDelete(): void {
    promptAction.showDialog({
      title: I18n.t('delete', this.lang),
      message: I18n.t('blog_comment_delete_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('delete', this.lang), color: '#DC2626' }
      ]
    }).then((res: DialogResult) => {
      if (res.index !== 1) {
        return;
      }
      this.doDelete();
    }).catch(() => {
    });
  }

  private async doDelete(): Promise<void> {
    const result = await this.repo.delete(this.item.id);
    if (result !== true) {
      promptAction.showToast({ message: typeof result === 'string' ? result : I18n.t('forum_delete_fail', this.lang) });
      return;
    }
    promptAction.showToast({ message: I18n.t('blog_comment_deleted', this.lang) });
    CommentUi.bumpReload();
  }

  build() {
    Row({ space: 10 }) {
      if (!this.nested) {
        if (this.item.avatar.length > 0) {
          Image(this.item.avatar)
            .width(32)
            .height(32)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .flexShrink(0)
        } else {
          Column() {
            Text(ForumUi.nickInitial(this.item.nickname))
              .fontSize(12)
              .fontColor($r('app.color.text_on_color'))
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(ForumUi.avatarColor(this.item.nickname))
          .flexShrink(0)
        }
      }

      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(this.item.nickname)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (this.item.replyToNickname.length > 0) {
            Text(`${I18n.t('blog_reply', this.lang)} ${this.item.replyToNickname}`)
              .fontSize(12)
              .fontColor($r('app.color.chevron'))
              .maxLines(1)
          }
        }
        .alignItems(VerticalAlign.Center)

        if (this.item.status === 0) {
          Text(this.item.hint.length > 0 ? this.item.hint : I18n.t('comment_rejected', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.warning_text'))
            .width('100%')
        } else if (this.item.status === 2) {
          Text(this.item.hint.length > 0 ? this.item.hint : I18n.t('forum_pending', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.warning_text'))
            .width('100%')
        }

        Text(this.item.content)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Row({ space: 14 }) {
          Text(ForumUi.ipLabel(this.item.ipAddress).length > 0 ?
            `${ForumUi.relativeTime(this.item.createTime, this.lang)} · ${ForumUi.ipLabel(this.item.ipAddress)}` :
            ForumUi.relativeTime(this.item.createTime, this.lang))
            .fontSize(11)
            .fontColor($r('app.color.chevron'))
          if (this.item.status !== 0) {
            Text(I18n.t('blog_reply', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.accent'))
              .onClick(() => {
                LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
                  this.onReply(this.item.id, this.item.nickname);
                });
              })
          }
          if (this.isMine()) {
            Text(I18n.t('delete', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.danger'))
              .onClick(() => {
                this.confirmDelete();
              })
          } else {
            Text(I18n.t('content_report', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.chevron'))
              .onClick(() => {
                ContentReportNav.open(this.lang, 'QUESTION_COMMENT', this.item.id, this.item.content);
              })
          }
          Blank()
          Row({ space: 4 }) {
            Image($r('app.media.ic_comment_like'))
              .width(14)
              .height(14)
              .objectFit(ImageFit.Contain)
              .fillColor(this.likeColor(this.myVote === 1))
            Text(`${this.likeCount}`)
              .fontSize(12)
              .fontColor(this.likeColor(this.myVote === 1))
          }
          .onClick(() => {
            this.vote(1);
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.showRepliesLink && this.replyTotal() > 0 && this.item.replies.length === 0) {
          Text(`${I18n.t('comment_replies', this.lang)} ${this.replyTotal()} ${I18n.t('comment_replies_unit', this.lang)} >`)
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .margin({ top: 6 })
            .backgroundColor($r('app.color.chip_idle_bg'))
            .borderRadius(4)
            .onClick(() => {
              CommentUi.openDetail(this.item.id);
            })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: this.indentLeft() })
  }
}
