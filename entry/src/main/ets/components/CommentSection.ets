import { I18n } from '../common/i18n/I18n';
import { LoginGate } from '../common/utils/LoginGate';
import { CommentUi } from '../common/utils/CommentUi';
import { CommentItemRow } from './CommentItemRow';
import { CommentRepository, QuestionComment } from '../data/repository/CommentRepository';

@Component
export struct CommentSection {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop @Watch('onReload') reloadTick: number = 0;
  @Prop @Watch('onQuestionIdChange') questionId: string = '';
  @Prop @Watch('onComposeChange') composeOpen: boolean = false;
  @State private comments: QuestionComment[] = [];
  @State private loading: boolean = false;
  @State private sortHot: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();
  private composeWasOpen: boolean = false;
  private onPostedReload: () => void = () => {
    this.reload();
  };

  aboutToAppear(): void {
    CommentUi.setQuestionId(this.questionId);
    this.composeWasOpen = this.composeOpen;
    CommentUi.addReloadListener(this.onPostedReload);
    this.reload();
  }

  aboutToDisappear(): void {
    CommentUi.removeReloadListener(this.onPostedReload);
  }

  onQuestionIdChange(): void {
    CommentUi.setQuestionId(this.questionId);
    this.reload();
  }

  onReload(): void {
    this.reload();
  }

  onComposeChange(): void {
    if (this.composeWasOpen && !this.composeOpen) {
      this.reload();
    }
    this.composeWasOpen = this.composeOpen;
  }

  private async reload(): Promise<void> {
    if (this.questionId.length === 0) {
      return;
    }
    this.loading = true;
    try {
      const next = await this.repo.list(this.questionId);
      this.comments = [];
      this.comments = next;
    } catch (_e) {
      this.comments = [];
    } finally {
      this.loading = false;
    }
  }

  private totalCount(): number {
    let n = this.comments.length;
    for (let i = 0; i < this.comments.length; i++) {
      n += this.comments[i].replyCount;
    }
    return n;
  }

  private displayList(): QuestionComment[] {
    if (!this.sortHot) {
      return this.comments;
    }
    const copy: QuestionComment[] = [];
    for (let i = 0; i < this.comments.length; i++) {
      copy.push(this.comments[i]);
    }
    copy.sort((a: QuestionComment, b: QuestionComment) => {
      if (b.likeCount !== a.likeCount) {
        return b.likeCount - a.likeCount;
      }
      return b.createTime.localeCompare(a.createTime);
    });
    return copy;
  }

  private openNew(): void {
    LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
      CommentUi.openCompose('', '');
    });
  }

  build() {
    Column() {
      Row() {
        Text(`${I18n.t('comment_title', this.lang)} ${this.totalCount()}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#18191C')
          .layoutWeight(1)
        Text(this.sortHot ? I18n.t('comment_sort_hot', this.lang) : I18n.t('comment_sort_time', this.lang))
          .fontSize(12)
          .fontColor('#9499A0')
          .onClick(() => {
            this.sortHot = !this.sortHot;
          })
      }
      .width('100%')
      .padding({ bottom: 10 })

      Row({ space: 8 }) {
        Text(I18n.t('comment_ph', this.lang))
          .fontSize(14)
          .fontColor('#9499A0')
          .layoutWeight(1)
        Image($r('app.media.ic_comment_emoji'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(36)
      .padding({ left: 14, right: 12 })
      .backgroundColor('#F1F2F3')
      .borderRadius(18)
      .onClick(() => {
        this.openNew();
      })

      if (this.loading && this.comments.length === 0) {
        Text(I18n.t('loading', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .margin({ top: 16 })
      } else if (this.comments.length === 0) {
        Text(I18n.t('comment_empty', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .margin({ top: 16, bottom: 8 })
      } else {
        ForEach(this.displayList(), (c: QuestionComment) => {
          Column() {
            CommentItemRow({
              item: c,
              inDetail: false,
              showRepliesLink: true
            })
            Divider().color($r('app.color.divider'))
          }
          .width('100%')
        }, (c: QuestionComment) => `${c.id}_${c.replyCount}_${c.likeCount}_${c.dislikeCount}_${c.content}`)
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
