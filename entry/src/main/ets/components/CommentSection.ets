import { promptAction } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { LoginGate } from '../common/utils/LoginGate';
import { CommentUi } from '../common/utils/CommentUi';
import { CommentEmojis } from '../common/utils/CommentEmojis';
import { CommentItemRow } from './CommentItemRow';
import { CommentFlatRow, CommentRepository, QuestionComment } from '../data/repository/CommentRepository';

@Component
export struct CommentSection {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop @Watch('onReload') reloadTick: number = 0;
  @Prop @Watch('onQuestionIdChange') questionId: string = '';
  @Prop @Watch('onComposeChange') composeOpen: boolean = false;
  @State private comments: QuestionComment[] = [];
  @State private loading: boolean = false;
  @State private sortHot: boolean = true;
  @State private replyText: string = '';
  @State private replyToId: string = '';
  @State private replyToName: string = '';
  @State private sending: boolean = false;
  @State private showEmoji: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();
  private emojis: string[] = CommentEmojis.all();
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
    this.replyText = '';
    this.replyToId = '';
    this.replyToName = '';
    this.showEmoji = false;
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
      n += this.flatReplies(this.comments[i]).length;
    }
    return n;
  }

  private flatReplies(item: QuestionComment): CommentFlatRow[] {
    const out: CommentFlatRow[] = [];
    this.collectFlat(item.replies, 1, out);
    return out;
  }

  private collectFlat(src: QuestionComment[], depth: number, out: CommentFlatRow[]): void {
    for (let i = 0; i < src.length; i++) {
      const row: CommentFlatRow = {
        key: `${src[i].id}_${depth}_${i}`,
        depth: depth,
        item: src[i]
      };
      out.push(row);
      this.collectFlat(src[i].replies, depth + 1, out);
    }
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

  private commentKey(c: QuestionComment): string {
    return `${c.id}_${c.replyCount}_${c.likeCount}_${c.dislikeCount}_${c.content}_${c.myVote}`;
  }

  private startReply(id: string, name: string): void {
    LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
      this.replyToId = id;
      this.replyToName = name;
      this.showEmoji = false;
    });
  }

  private insertEmoji(emoji: string): void {
    this.replyText = `${this.replyText}${emoji}`;
  }

  private send(): void {
    const text = this.replyText.trim();
    if (text.length === 0) {
      return;
    }
    LoginGate.ensure(I18n.t('comment_feature', this.lang), () => {
      this.doSend(text);
    });
  }

  private async doSend(text: string): Promise<void> {
    if (this.sending) {
      return;
    }
    if (text.length > 500) {
      promptAction.showToast({ message: '评论最多 500 字' });
      return;
    }
    this.sending = true;
    try {
      const result = await this.repo.post(this.questionId, text, this.replyToId);
      if (typeof result === 'string') {
        promptAction.showToast({ message: result });
        return;
      }
      this.replyText = '';
      this.replyToId = '';
      this.replyToName = '';
      this.showEmoji = false;
      if (result.status === 0) {
        const hint = result.hint.length > 0 ? result.hint : I18n.t('comment_rejected', this.lang);
        promptAction.showToast({ message: hint });
      } else if (result.status === 2) {
        const hint = result.hint.length > 0 ? result.hint : I18n.t('forum_pending', this.lang);
        promptAction.showToast({ message: hint });
      } else {
        promptAction.showToast({ message: I18n.t('comment_ok', this.lang) });
      }
      CommentUi.bumpReload();
      await this.reload();
    } catch (_e) {
      promptAction.showToast({ message: I18n.t('comment_fail', this.lang) });
    } finally {
      this.sending = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(`${I18n.t('comment_title', this.lang)} ${this.totalCount()}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Row({ space: 2 }) {
          Text(this.sortHot ? I18n.t('comment_sort_hot', this.lang) : I18n.t('comment_sort_time', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
          Text('▾')
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
        .onClick(() => {
          this.sortHot = !this.sortHot;
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading && this.comments.length === 0) {
        Text(I18n.t('loading', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
      } else if (this.comments.length === 0) {
        Text(I18n.t('comment_empty', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.displayList(), (c: QuestionComment) => {
          Column({ space: 8 }) {
            CommentItemRow({
              item: c,
              nested: false,
              showRepliesLink: false,
              onReply: (id: string, name: string) => {
                this.startReply(id, name);
              }
            })
            if (this.flatReplies(c).length > 0) {
              Column({ space: 8 }) {
                ForEach(this.flatReplies(c), (child: CommentFlatRow) => {
                  Column() {
                    CommentItemRow({
                      item: child.item,
                      nested: true,
                      showRepliesLink: false,
                      onReply: (id: string, name: string) => {
                        this.startReply(id, name);
                      }
                    })
                  }
                  .width('100%')
                  .padding({ left: (child.depth - 1) * 12 })
                }, (child: CommentFlatRow) => `${this.commentKey(child.item)}-${child.depth}`)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 10, right: 8, top: 8, bottom: 8 })
              .backgroundColor($r('app.color.preview_bg'))
              .borderRadius(8)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 4, bottom: 8 })
        }, (c: QuestionComment) => this.commentKey(c))
      }

      if (this.replyToName.length > 0) {
        Row() {
          Text(I18n.tf('forum_reply_to_ph', this.replyToName, this.lang))
            .fontSize(12)
            .fontColor($r('app.color.accent'))
            .layoutWeight(1)
          Text('×')
            .fontSize(16)
            .fontColor($r('app.color.chevron'))
            .onClick(() => {
              this.replyToId = '';
              this.replyToName = '';
            })
        }
        .width('100%')
      }

      if (this.showEmoji) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.emojis, (emoji: string) => {
            Text(emoji)
              .fontSize(22)
              .padding(6)
              .onClick(() => {
                this.insertEmoji(emoji);
              })
          }, (emoji: string) => emoji)
        }
        .width('100%')
      }

      Row({ space: 8 }) {
        Row({ space: 8 }) {
          TextInput({
            placeholder: I18n.t('blog_comment_ph', this.lang),
            text: this.replyText
          })
            .layoutWeight(1)
            .height(36)
            .backgroundColor('#00000000')
            .padding({ left: 0, right: 0 })
            .onChange((v: string) => {
              this.replyText = v;
            })
          Image($r('app.media.ic_comment_emoji_line'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
            .fillColor(this.showEmoji ? $r('app.color.accent') : $r('app.color.chevron'))
            .flexShrink(0)
            .onClick(() => {
              this.showEmoji = !this.showEmoji;
            })
        }
        .layoutWeight(1)
        .height(40)
        .padding({ left: 14, right: 12 })
        .backgroundColor($r('app.color.chip_idle_bg'))
        .borderRadius(20)
        .alignItems(VerticalAlign.Center)

        Button(this.sending ? I18n.t('comment_posting', this.lang) : I18n.t('forum_send', this.lang))
          .height(36)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .enabled(!this.sending)
          .backgroundColor(this.replyText.trim().length > 0 ? $r('app.color.accent') : $r('app.color.accent_soft'))
          .borderRadius(18)
          .onClick(() => {
            this.send();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }
}
