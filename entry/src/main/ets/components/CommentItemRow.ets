import { promptAction } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { LoginGate } from '../common/utils/LoginGate';
import { CommentUi } from '../common/utils/CommentUi';
import { ContentReportNav } from '../common/utils/ContentReportNav';
import { ForumUi } from '../common/utils/ForumUi';
import { CommentRepository, emptyQuestionComment, QuestionComment } from '../data/repository/CommentRepository';

@Component
export struct CommentItemRow {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop @Watch('syncFromItem') item: QuestionComment = emptyQuestionComment();
  @Prop inDetail: boolean = false;
  @Prop showRepliesLink: boolean = false;
  @Prop indent: number = 0;
  @State private likeCount: number = 0;
  @State private dislikeCount: number = 0;
  @State private myVote: number = 0;
  @State private voting: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();

  aboutToAppear(): void {
    this.syncFromItem();
  }

  syncFromItem(): void {
    this.likeCount = this.item.likeCount;
    this.dislikeCount = this.item.dislikeCount;
    this.myVote = this.item.myVote;
  }

  private indentLeft(): number {
    const level = this.indent > 4 ? 4 : this.indent;
    return level * 16;
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

  private voteColor(active: boolean): string {
    return active ? '#FB7299' : '#9499A0';
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
      this.dislikeCount = result.dislikeCount;
      this.myVote = result.myVote;
      CommentUi.bumpReload();
    } catch (_e) {
      promptAction.showToast({ message: I18n.t('comment_vote_fail', this.lang) });
    } finally {
      this.voting = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      Row({ space: 10 }) {
        if (this.item.avatar.length > 0) {
          Image(this.item.avatar)
            .width(34)
            .height(34)
            .borderRadius(17)
            .objectFit(ImageFit.Cover)
            .flexShrink(0)
        } else {
          Column() {
            Text(this.item.nickname.length > 0 ? this.item.nickname.substring(0, 1) : '评')
              .fontSize(13)
              .fontColor('#FFFFFF')
          }
          .width(34)
          .height(34)
          .borderRadius(17)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#60A5FA')
          .flexShrink(0)
        }

        Column({ space: 5 }) {
          Text(this.item.nickname)
            .fontSize(13)
            .fontColor('#FB7299')
            .width('100%')

          if (this.inDetail && this.item.replyToNickname.length > 0) {
            Text() {
              Span(`${I18n.t('comment_replying', this.lang)} @${this.item.replyToNickname}：`)
                .fontColor('#00A1D6')
              Span(this.item.content)
                .fontColor($r('app.color.text_primary'))
            }
            .fontSize(15)
            .width('100%')
          } else {
            Text(this.item.content)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
          }

          if (this.item.status === 0) {
            Text(this.item.hint.length > 0 ? this.item.hint : I18n.t('comment_rejected', this.lang))
              .fontSize(12)
              .fontColor('#B45309')
              .width('100%')
              .padding(8)
              .backgroundColor('#FEF3C7')
              .borderRadius(8)
          }

          Row() {
            Text(ForumUi.ipLabel(this.item.ipAddress).length > 0 ?
              `${CommentUi.shortTime(this.item.createTime,
                I18n.t('comment_month', this.lang),
                I18n.t('comment_day', this.lang),
                I18n.t('comment_today', this.lang))} · ${ForumUi.ipLabel(this.item.ipAddress)}` :
              CommentUi.shortTime(this.item.createTime,
                I18n.t('comment_month', this.lang),
                I18n.t('comment_day', this.lang),
                I18n.t('comment_today', this.lang)))
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
            if (this.item.status !== 0) {
              Text(I18n.t('comment_reply', this.lang))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .margin({ left: 12 })
                .padding({ left: 2, right: 6, top: 8, bottom: 8 })
                .onClick(() => {
                  LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
                    CommentUi.openCompose(this.item.id, this.item.nickname);
                  });
                })
            }
            if (LoginGate.currentUserId() !== this.item.userId) {
              Text(I18n.t('content_report', this.lang))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .margin({ left: 8 })
                .padding({ left: 2, right: 6, top: 8, bottom: 8 })
                .onClick(() => {
                  ContentReportNav.open(this.lang, 'QUESTION_COMMENT', this.item.id, this.item.content);
                })
            }
            Blank()
            Row({ space: 16 }) {
              Row({ space: 3 }) {
                Image($r('app.media.ic_comment_like'))
                  .width(16)
                  .height(16)
                  .objectFit(ImageFit.Contain)
                  .fillColor(this.voteColor(this.myVote === 1))
                if (this.likeCount > 0 || this.myVote === 1) {
                  Text(`${this.likeCount}`)
                    .fontSize(12)
                    .fontColor(this.myVote === 1 ? '#FB7299' : '#9499A0')
                }
              }
              .padding({ top: 8, bottom: 8, left: 2, right: 2 })
              .onClick(() => {
                this.vote(1);
              })
              Row({ space: 3 }) {
                Image($r('app.media.ic_comment_dislike'))
                  .width(16)
                  .height(16)
                  .objectFit(ImageFit.Contain)
                  .fillColor(this.voteColor(this.myVote === -1))
                if (this.dislikeCount > 0 || this.myVote === -1) {
                  Text(`${this.dislikeCount}`)
                    .fontSize(12)
                    .fontColor(this.myVote === -1 ? '#FB7299' : '#9499A0')
                }
              }
              .padding({ top: 8, bottom: 8, left: 2, right: 2 })
              .onClick(() => {
                this.vote(-1);
              })
            }
          }
          .width('100%')

          if (this.showRepliesLink && this.replyTotal() > 0) {
            Text(`${I18n.t('comment_replies', this.lang)} ${this.replyTotal()} ${I18n.t('comment_replies_unit', this.lang)} >`)
              .fontSize(13)
              .fontColor('#61666D')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ top: 6 })
              .backgroundColor('#F1F2F3')
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
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: this.indentLeft()
    })
  }
}
