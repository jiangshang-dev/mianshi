import { promptAction } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { BlogComment, copyBlogComment, mallBool } from '../common/models/BlogTypes';
import { mallNum, mallStr } from '../common/models/MallTypes';
import { BlogRepository } from '../data/repository/BlogRepository';
import { CommentEmojis } from '../common/utils/CommentEmojis';
import { ForumUi } from '../common/utils/ForumUi';
import { LoginGate } from '../common/utils/LoginGate';

interface DialogResult {
  index: number;
}

interface FlatBlogReply {
  item: BlogComment;
  depth: number;
}

@Component
export struct BlogCommentBlock {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('blogCommentTick') @Watch('onCommentTick') blogCommentTick: number = 0;
  @Prop @Watch('onArticleChange') articleId: string = '';
  @Prop authorName: string = '';
  @State private comments: BlogComment[] = [];
  @State private loading: boolean = false;
  @State private commentTick: number = 0;
  @State private replyText: string = '';
  @State private replyToId: string = '';
  @State private replyToName: string = '';
  @State private sending: boolean = false;
  @State private showEmoji: boolean = false;
  onOpenToc: () => void = () => {
  };
  onPosted: () => void = () => {
  };
  private repo: BlogRepository = BlogRepository.getInstance();
  private emojis: string[] = CommentEmojis.all();

  aboutToAppear(): void {
    this.reload();
  }

  onArticleChange(): void {
    this.reload();
  }

  onCommentTick(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    if (this.articleId.length === 0) {
      return;
    }
    this.loading = true;
    try {
      this.comments = await this.repo.comments(this.articleId);
      this.commentTick = this.commentTick + 1;
    } catch (_e) {
      this.comments = [];
      this.commentTick = this.commentTick + 1;
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

  private flatReplies(item: BlogComment): FlatBlogReply[] {
    const out: FlatBlogReply[] = [];
    this.collectFlat(item.replies, 1, out);
    return out;
  }

  private collectFlat(src: BlogComment[] | undefined, depth: number, out: FlatBlogReply[]): void {
    if (src === undefined) {
      return;
    }
    for (let i = 0; i < src.length; i++) {
      const row: FlatBlogReply = {
        item: src[i],
        depth: depth
      };
      out.push(row);
      this.collectFlat(src[i].replies, depth + 1, out);
    }
  }

  private commentKey(item: BlogComment): string {
    return `${this.commentTick}-${mallStr(item.id)}-${mallNum(item.status)}-${mallStr(item.hint)}-${mallNum(item.likeCount)}-${mallStr(item.content)}-${mallBool(item.mine) ? 1 : 0}`;
  }

  private startReply(item: BlogComment): void {
    LoginGate.ensure(I18n.t('blog_comment', this.lang), () => {
      this.replyToId = mallStr(item.id);
      this.replyToName = mallStr(item.nickname);
      this.showEmoji = false;
    });
  }

  private send(): void {
    const text = this.replyText.trim();
    if (text.length === 0) {
      return;
    }
    LoginGate.ensure(I18n.t('blog_comment', this.lang), () => {
      if (this.sending) {
        return;
      }
      this.sending = true;
      this.repo.postComment(this.articleId, text, this.replyToId).then((row) => {
        this.replyText = '';
        this.replyToId = '';
        this.replyToName = '';
        this.showEmoji = false;
        this.comments = this.mergePosted(row);
        const hint = mallStr(row.hint);
        if (hint.length > 0) {
          promptAction.showToast({ message: hint });
        }
        BlogRepository.bumpList();
        this.onPosted();
        this.reload();
      }).catch((err: Error) => {
        promptAction.showToast({ message: err.message });
      }).then(() => {
        this.sending = false;
      });
    });
  }

  private mergePosted(row: BlogComment): BlogComment[] {
    const item = copyBlogComment(row);
    const parentId = mallStr(item.parentId);
    const next: BlogComment[] = [];
    if (parentId.length === 0) {
      for (let i = 0; i < this.comments.length; i++) {
        next.push(this.comments[i]);
      }
      next.push(item);
      return next;
    }
    for (let i = 0; i < this.comments.length; i++) {
      const cur = copyBlogComment(this.comments[i]);
      if (mallStr(cur.id) === parentId || mallStr(cur.id) === mallStr(item.rootId)) {
        const kids: BlogComment[] = [];
        const src = cur.replies;
        if (src !== undefined) {
          for (let j = 0; j < src.length; j++) {
            kids.push(src[j]);
          }
        }
        kids.push(item);
        cur.replies = kids;
        cur.replyCount = mallNum(cur.replyCount) + 1;
      }
      next.push(cur);
    }
    return next;
  }

  private isMine(item: BlogComment): boolean {
    return mallBool(item.mine);
  }

  private confirmDelete(item: BlogComment): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
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
      this.repo.deleteComment(id).then(() => {
        promptAction.showToast({ message: I18n.t('blog_comment_deleted', this.lang) });
        BlogRepository.bumpList();
        this.onPosted();
        this.reload();
      }).catch((err: Error) => {
        promptAction.showToast({
          message: err.message.length > 0 ? err.message : I18n.t('forum_delete_fail', this.lang)
        });
      });
    }).catch(() => {
    });
  }

  private vote(item: BlogComment, action: number): void {
    LoginGate.ensure(I18n.t('blog_like', this.lang), () => {
      this.repo.voteComment(mallStr(item.id), action).then(() => {
        this.reload();
      }).catch((err: Error) => {
        promptAction.showToast({ message: err.message });
      });
    });
  }

  private isAuthor(item: BlogComment): boolean {
    const name = mallStr(item.nickname);
    return name.length > 0 && name === this.authorName;
  }

  private insertEmoji(emoji: string): void {
    this.replyText = `${this.replyText}${emoji}`;
  }

  private hotSoon(): void {
    promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
  }

  private likeColor(on: boolean): string {
    return on ? '#2563EB' : '#9CA3AF';
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(`${I18n.t('blog_comment', this.lang)} ${this.totalCount()}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        // Text(I18n.t('blog_toc', this.lang))
        //   .fontSize(13)
        //   .fontColor('#2563EB')
        //   .padding({ right: 12 })
        //   .onClick(() => this.onOpenToc())
        Row({ space: 2 }) {
          Text(I18n.t('blog_hot', this.lang))
            .fontSize(13)
            .fontColor('#6B7280')
          Text('▾')
            .fontSize(12)
            .fontColor('#6B7280')
        }
        .onClick(() => this.hotSoon())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading && this.comments.length === 0) {
        Text(I18n.t('blog_comment_loading', this.lang)).fontSize(13).fontColor($r('app.color.text_muted'))
      } else if (this.comments.length === 0) {
        Text(I18n.t('blog_comment_empty', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.comments, (item: BlogComment) => {
          Column({ space: 8 }) {
            this.commentBody(item, false)
            if (this.flatReplies(item).length > 0) {
              Column({ space: 8 }) {
                ForEach(this.flatReplies(item), (child: FlatBlogReply) => {
                  Column() {
                    this.commentBody(child.item, true)
                  }
                  .width('100%')
                  .padding({ left: (child.depth - 1) * 12 })
                }, (child: FlatBlogReply) => `${this.commentKey(child.item)}-${child.depth}`)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 10, right: 8, top: 8, bottom: 8 })
              .backgroundColor('#F8FAFC')
              .borderRadius(8)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 4, bottom: 8 })
        }, (item: BlogComment) => this.commentKey(item))
      }

      if (this.replyToName.length > 0) {
        Row() {
          Text(I18n.tf('forum_reply_to_ph', this.replyToName, this.lang))
            .fontSize(12)
            .fontColor($r('app.color.accent'))
            .layoutWeight(1)
          Text('×')
            .fontSize(16)
            .fontColor($r('app.color.text_muted'))
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
              .onClick(() => this.insertEmoji(emoji))
          }, (emoji: string) => emoji)
        }
        .width('100%')
      }

      Row({ space: 8 }) {
        TextInput({ placeholder: I18n.t('blog_comment_ph', this.lang), text: this.replyText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F3F4F6')
          .borderRadius(20)
          .padding({ left: 14, right: 14 })
          .onChange((v: string) => {
            this.replyText = v;
          })
        Image($r('app.media.ic_comment_emoji_line'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor(this.showEmoji ? '#2563EB' : '#9CA3AF')
          .onClick(() => {
            this.showEmoji = !this.showEmoji;
          })
        Button(this.sending ? I18n.t('forum_publishing', this.lang) : I18n.t('forum_send', this.lang))
          .height(36)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .enabled(!this.sending)
          .backgroundColor('#2563EB')
          .borderRadius(18)
          .onClick(() => this.send())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }

  @Builder
  commentBody(item: BlogComment, nested: boolean) {
    Row({ space: 10 }) {
      if (!nested) {
        Column() {
          Text(ForumUi.nickInitial(mallStr(item.nickname)))
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ForumUi.avatarColor(mallStr(item.nickname)))
        .flexShrink(0)
      }
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(mallStr(item.nickname))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (this.isAuthor(item)) {
            Text(I18n.t('blog_author', this.lang))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#2563EB')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
          if (mallStr(item.replyToNickname).length > 0) {
            Text(`${I18n.t('blog_reply', this.lang)} ${mallStr(item.replyToNickname)}`)
              .fontSize(12)
              .fontColor('#9CA3AF')
              .maxLines(1)
          }
        }
        .alignItems(VerticalAlign.Center)
        if (mallStr(item.hint).length > 0) {
          Text(mallStr(item.hint)).fontSize(12).fontColor('#B45309').width('100%')
        } else if (mallNum(item.status) === 2) {
          Text(I18n.t('forum_pending', this.lang)).fontSize(12).fontColor('#B45309').width('100%')
        }
        Text(mallStr(item.content))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Row({ space: 14 }) {
          Text(ForumUi.relativeTime(mallStr(item.createTime), this.lang))
            .fontSize(11)
            .fontColor('#9CA3AF')
          Text(I18n.t('blog_reply', this.lang))
            .fontSize(12)
            .fontColor('#2563EB')
            .onClick(() => this.startReply(item))
          if (this.isMine(item)) {
            Text(I18n.t('delete', this.lang))
              .fontSize(12)
              .fontColor('#DC2626')
              .onClick(() => this.confirmDelete(item))
          }
          Blank()
          Row({ space: 4 }) {
            Image($r('app.media.ic_comment_like'))
              .width(14)
              .height(14)
              .objectFit(ImageFit.Contain)
              .fillColor(this.likeColor(mallNum(item.myVote) === 1))
            Text(`${mallNum(item.likeCount)}`)
              .fontSize(12)
              .fontColor(this.likeColor(mallNum(item.myVote) === 1))
          }
          .onClick(() => this.vote(item, 1))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}
