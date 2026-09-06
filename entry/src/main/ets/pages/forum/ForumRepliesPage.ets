import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { mallBool } from '../../common/models/BlogTypes';
import { ForumPost, ForumReply, ForumReplyRow, ForumReplyThread, copyForumPost, copyForumReply } from '../../common/models/ForumTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { ForumReplyBlock } from '../../components/ForumReplyBlock';
import { ForumRepository } from '../../data/repository/ForumRepository';
import { CommentEmojis } from '../../common/utils/CommentEmojis';
import { ContentReportNav } from '../../common/utils/ContentReportNav';
import { ForumUi } from '../../common/utils/ForumUi';
import { LoginGate } from '../../common/utils/LoginGate';

interface ForumRepliesParams {
  postId?: string;
  rootId?: string;
}

interface DialogResult {
  index: number;
}

@Entry
@Component
struct ForumRepliesPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private post: ForumPost | null = null;
  @State private replyText: string = '';
  @State private sending: boolean = false;
  @State private replyToId: string = '';
  @State private replyToName: string = '';
  @State private refreshing: boolean = false;
  @State private filterId: string = 'all';
  @State private commentSort: string = 'default';
  @State private expandedContentIds: string[] = [];
  @State private showEmoji: boolean = false;
  @State private threadList: ForumReplyThread[] = [];
  @State private replyTick: number = 0;
  private postId: string = '';
  private focusRootId: string = '';
  private repo: ForumRepository = ForumRepository.getInstance();
  private emojis: string[] = CommentEmojis.all();

  private pageReady: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as ForumRepliesParams;
    this.postId = params !== undefined && params.postId !== undefined ? params.postId : '';
    this.focusRootId = params !== undefined && params.rootId !== undefined ? params.rootId : '';
    this.load(false);
  }

  onPageShow(): void {
    if (!this.pageReady) {
      this.pageReady = true;
      return;
    }
    this.load(true);
  }

  aboutToDisappear(): void {
    ForumRepository.bumpList();
  }

  private async load(silent: boolean): Promise<void> {
    if (this.postId.length === 0) {
      this.loading = false;
      return;
    }
    if (!silent) {
      this.loading = true;
    }
    try {
      this.applyDetail(await this.repo.detail(this.postId));
    } catch (err) {
      this.post = null;
      this.threadList = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('forum_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private applyDetail(post: ForumPost): void {
    this.post = copyForumPost(post);
    this.syncThreads();
  }

  private syncThreads(): void {
    const all = ForumUi.threads(this.replies(), this.commentSort === 'latest');
    if (this.filterId === 'author') {
      this.threadList = this.authorThreads(all);
    } else if (this.filterId === 'featured') {
      this.threadList = this.featuredThreads(all);
    } else if (this.focusRootId.length === 0) {
      this.threadList = all;
    } else {
      const focused: ForumReplyThread[] = [];
      const rest: ForumReplyThread[] = [];
      for (let i = 0; i < all.length; i++) {
        if (mallStr(all[i].root.id) === this.focusRootId) {
          focused.push(all[i]);
        } else {
          rest.push(all[i]);
        }
      }
      for (let i = 0; i < rest.length; i++) {
        focused.push(rest[i]);
      }
      this.threadList = focused;
    }
    this.replyTick = this.replyTick + 1;
  }

  private replies(): ForumReply[] {
    const post = this.post;
    if (post === null || post.replies === undefined) {
      const empty: ForumReply[] = [];
      return empty;
    }
    return post.replies;
  }

  private mergeReply(row: ForumReply): void {
    const current = this.post;
    if (current === null) {
      return;
    }
    const next = copyForumPost(current);
    const list: ForumReply[] = [];
    const src = next.replies;
    if (src !== undefined) {
      for (let i = 0; i < src.length; i++) {
        list.push(src[i]);
      }
    }
    list.push(copyForumReply(row));
    next.replies = list;
    next.replyCount = mallNum(next.replyCount) + 1;
    this.applyDetail(next);
  }

  private authorThreads(all: ForumReplyThread[]): ForumReplyThread[] {
    const out: ForumReplyThread[] = [];
    for (let i = 0; i < all.length; i++) {
      const thread = all[i];
      const kids: ForumReplyRow[] = [];
      if (mallBool(thread.root.author)) {
        for (let j = 0; j < thread.children.length; j++) {
          if (mallBool(thread.children[j].reply.author)) {
            kids.push(thread.children[j]);
          }
        }
        const row: ForumReplyThread = { root: thread.root, children: kids, floor: thread.floor };
        out.push(row);
      } else {
        for (let j = 0; j < thread.children.length; j++) {
          if (mallBool(thread.children[j].reply.author)) {
            const empty: ForumReplyRow[] = [];
            const row: ForumReplyThread = { root: thread.children[j].reply, children: empty, floor: thread.floor };
            out.push(row);
          }
        }
      }
    }
    return out;
  }

  private featuredThreads(all: ForumReplyThread[]): ForumReplyThread[] {
    const out: ForumReplyThread[] = [];
    for (let i = 0; i < all.length; i++) {
      const thread = all[i];
      const kids: ForumReplyRow[] = [];
      for (let j = 0; j < thread.children.length; j++) {
        if (mallBool(thread.children[j].reply.featured)) {
          kids.push(thread.children[j]);
        }
      }
      if (mallBool(thread.root.featured) || kids.length > 0) {
        const row: ForumReplyThread = { root: thread.root, children: kids, floor: thread.floor };
        out.push(row);
      }
    }
    return out;
  }

  private selectFilter(id: string): void {
    this.filterId = id;
    this.focusRootId = '';
    this.syncThreads();
  }

  private emptyText(): string {
    if (this.filterId === 'featured') {
      return I18n.t('forum_featured_empty', this.lang);
    }
    return I18n.t('forum_reply_empty', this.lang);
  }

  private beginReply(item: ForumReply): void {
    LoginGate.ensure(I18n.t('forum_reply_action', this.lang), () => {
      this.replyToId = mallStr(item.id);
      this.replyToName = mallStr(item.nickname);
      this.showEmoji = false;
    });
  }

  private clearReplyTarget(): void {
    this.replyToId = '';
    this.replyToName = '';
  }

  private replyPlaceholder(): string {
    if (this.replyToName.length > 0) {
      return I18n.tf('forum_reply_to_ph', this.replyToName, this.lang);
    }
    return I18n.t('forum_write_reply', this.lang);
  }

  private confirmDeleteReply(item: ForumReply): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    promptAction.showDialog({
      title: I18n.t('delete', this.lang),
      message: I18n.t('forum_reply_delete_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('delete', this.lang), color: '#DC2626' }
      ]
    }).then((res: DialogResult) => {
      if (res.index !== 1) {
        return;
      }
      this.repo.deleteReply(id).then(() => {
        promptAction.showToast({ message: I18n.t('forum_reply_deleted', this.lang) });
        if (this.replyToId === id) {
          this.clearReplyTarget();
        }
        ForumRepository.bumpList();
        this.load(true);
      }).catch((err: Error) => {
        promptAction.showToast({
          message: err.message.length > 0 ? err.message : I18n.t('forum_delete_fail', this.lang)
        });
      });
    }).catch(() => {
    });
  }

  private likeReply(item: ForumReply): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    LoginGate.ensure(I18n.t('blog_like', this.lang), () => {
      this.repo.toggleLike('reply', id).then((res) => {
        const current = this.post;
        if (current === null || current.replies === undefined) {
          return;
        }
        const next = copyForumPost(current);
        const list: ForumReply[] = [];
        const src = next.replies;
        if (src === undefined) {
          return;
        }
        for (let i = 0; i < src.length; i++) {
          const row = src[i];
          if (mallStr(row.id) === id) {
            const updated = copyForumReply(row);
            updated.liked = res.on === true;
            updated.likeCount = mallNum(res.count);
            list.push(updated);
          } else {
            list.push(row);
          }
        }
        next.replies = list;
        this.applyDetail(next);
      }).catch((err: Error) => promptAction.showToast({ message: err.message }));
    });
  }

  private toggleContent(item: ForumReply): void {
    this.expandedContentIds = ForumUi.toggleId(mallStr(item.id), this.expandedContentIds);
  }

  private insertEmoji(emoji: string): void {
    this.replyText = `${this.replyText}${emoji}`;
  }

  private pullRefresh(): void {
    this.refreshing = true;
    this.load(true).then(() => {
      this.refreshing = false;
    }).catch(() => {
      this.refreshing = false;
    });
  }

  private sendReply(): void {
    const text = this.replyText.trim();
    if (text.length === 0) {
      return;
    }
    LoginGate.ensure(I18n.t('forum_publish', this.lang), () => {
      if (this.sending) {
        return;
      }
      this.sending = true;
      this.repo.createReply(this.postId, text, this.replyToId).then((row) => {
        this.replyText = '';
        this.clearReplyTarget();
        this.showEmoji = false;
        const hint = mallStr(row.rejectHint);
        if (hint.length > 0) {
          promptAction.showToast({ message: hint });
        }
        this.mergeReply(row);
        this.load(true);
        ForumRepository.bumpList();
      }).catch((err: Error) => {
        promptAction.showToast({ message: err.message });
      }).then(() => {
        this.sending = false;
      });
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('forum_all_replies', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.card_bg'))

      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.post === null) {
        Column() {
          Text(I18n.t('forum_not_found', this.lang)).fontSize(15).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Text(I18n.tf('forum_all_n', `${this.replies().length}`, this.lang))
            .fontSize(14)
            .fontColor(this.filterId === 'all' ? '#2563EB' : '#6B7280')
            .fontWeight(this.filterId === 'all' ? FontWeight.Medium : FontWeight.Regular)
            .padding({ right: 16, top: 8, bottom: 8 })
            .onClick(() => this.selectFilter('all'))
          Text(I18n.t('forum_only_author', this.lang))
            .fontSize(14)
            .fontColor(this.filterId === 'author' ? '#2563EB' : '#6B7280')
            .fontWeight(this.filterId === 'author' ? FontWeight.Medium : FontWeight.Regular)
            .padding({ right: 16, top: 8, bottom: 8 })
            .onClick(() => this.selectFilter('author'))
          Text(I18n.t('forum_only_featured', this.lang))
            .fontSize(14)
            .fontColor(this.filterId === 'featured' ? '#2563EB' : '#6B7280')
            .fontWeight(this.filterId === 'featured' ? FontWeight.Medium : FontWeight.Regular)
            .padding({ right: 12, top: 8, bottom: 8 })
            .onClick(() => this.selectFilter('featured'))
          Blank()
          Text(this.commentSort === 'latest' ? I18n.t('forum_sort_latest', this.lang) :
            I18n.t('forum_sort_default_full', this.lang))
            .fontSize(13)
            .fontColor('#6B7280')
            .onClick(() => {
              this.commentSort = this.commentSort === 'latest' ? 'default' : 'latest';
              this.syncThreads();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.card_bg'))

        Refresh({ refreshing: this.refreshing }) {
          List({ space: 10 }) {
            if (this.threadList.length === 0) {
              ListItem() {
                Column() {
                  Text(this.emptyText()).fontSize(14).fontColor($r('app.color.text_muted'))
                }
                .width('100%')
                .height(280)
                .justifyContent(FlexAlign.Center)
              }
            } else {
              ForEach(this.threadList, (thread: ForumReplyThread) => {
                ListItem() {
                  this.threadCard(thread)
                }
              }, (thread: ForumReplyThread) =>
                `${this.replyTick}-${mallStr(thread.root.id)}-${thread.floor}-${mallNum(thread.root.likeCount)}-${thread.children.length}-${mallBool(thread.root.pending) ? 1 : 0}-${mallStr(thread.root.rejectHint)}`)
            }
          }
          .width('100%')
          .height('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 16 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
        }
        .layoutWeight(1)
        .width('100%')
        .onRefreshing(() => this.pullRefresh())

        if (this.replyToName.length > 0) {
          Row() {
            Text(I18n.tf('forum_reply_to_ph', this.replyToName, this.lang))
              .fontSize(12)
              .fontColor($r('app.color.accent'))
              .layoutWeight(1)
            Text('×')
              .fontSize(16)
              .fontColor($r('app.color.text_muted'))
              .padding({ left: 8, top: 4, bottom: 4 })
              .onClick(() => this.clearReplyTarget())
          }
          .width('100%')
          .padding({ left: 16, right: 12, top: 6, bottom: 0 })
          .backgroundColor($r('app.color.card_bg'))
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
          .padding({ left: 12, right: 12, top: 8, bottom: 4 })
          .backgroundColor($r('app.color.card_bg'))
        }

        Row({ space: 8 }) {
          TextInput({ placeholder: this.replyPlaceholder(), text: this.replyText })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#F3F4F6')
            .borderRadius(20)
            .padding({ left: 14, right: 14 })
            .onChange((v: string) => {
              this.replyText = v;
            })
          Image($r('app.media.ic_comment_emoji_line'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
            .fillColor(this.showEmoji ? '#2563EB' : '#9CA3AF')
            .onClick(() => {
              this.showEmoji = !this.showEmoji;
            })
          Button(this.sending ? I18n.t('forum_publishing', this.lang) : I18n.t('forum_publish', this.lang))
            .height(36)
            .padding({ left: 14, right: 14 })
            .fontSize(14)
            .enabled(!this.sending)
            .backgroundColor('#2563EB')
            .borderRadius(18)
            .onClick(() => this.sendReply())
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.card_bg'))
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  threadCard(thread: ForumReplyThread) {
    Column({ space: 10 }) {
      ForumReplyBlock({
        reply: thread.root,
        compact: false,
        floor: thread.floor,
        contentExpanded: ForumUi.idIn(mallStr(thread.root.id), this.expandedContentIds),
        onReply: (item: ForumReply) => {
          this.beginReply(item);
        },
        onLike: (item: ForumReply) => {
          this.likeReply(item);
        },
        onToggleContent: (item: ForumReply) => {
          this.toggleContent(item);
        },
        onDelete: (item: ForumReply) => {
          this.confirmDeleteReply(item);
        },
        onReport: (item: ForumReply) => {
          ContentReportNav.open(this.lang, 'FORUM_REPLY', mallStr(item.id), mallStr(item.content));
        }
      })
      if (thread.children.length > 0) {
        Column({ space: 8 }) {
          ForEach(thread.children, (item: ForumReplyRow) => {
            ForumReplyBlock({
              reply: item.reply,
              compact: true,
              floor: 0,
              depth: item.depth,
              contentExpanded: ForumUi.idIn(mallStr(item.reply.id), this.expandedContentIds),
              onReply: (child: ForumReply) => {
                this.beginReply(child);
              },
              onLike: (child: ForumReply) => {
                this.likeReply(child);
              },
              onToggleContent: (child: ForumReply) => {
                this.toggleContent(child);
              },
              onDelete: (child: ForumReply) => {
                this.confirmDeleteReply(child);
              },
              onReport: (child: ForumReply) => {
                ContentReportNav.open(this.lang, 'FORUM_REPLY', mallStr(child.id), mallStr(child.content));
              }
            })
          }, (item: ForumReplyRow) =>
            `${this.replyTick}-${mallStr(item.reply.id)}-${item.depth}-${mallNum(item.reply.likeCount)}-${mallStr(item.reply.content)}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12, top: 8, bottom: 4, right: 4 })
        .backgroundColor('#F8FAFC')
        .borderRadius(8)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }
}
