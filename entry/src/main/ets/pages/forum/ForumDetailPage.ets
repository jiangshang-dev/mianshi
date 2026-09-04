import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { mallBool } from '../../common/models/BlogTypes';
import { ForumPost, ForumReply, ForumReplyRow, ForumReplyThread, copyForumPost, copyForumReply } from '../../common/models/ForumTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { ForumReplyBlock } from '../../components/ForumReplyBlock';
import { ForumRepository } from '../../data/repository/ForumRepository';
import { CommentEmojis } from '../../common/utils/CommentEmojis';
import { ForumUi } from '../../common/utils/ForumUi';
import { LoginGate } from '../../common/utils/LoginGate';

interface ForumDetailParams {
  postId?: string;
}

interface DialogResult {
  index: number;
}

@Entry
@Component
struct ForumDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private post: ForumPost | null = null;
  @State private replyText: string = '';
  @State private sending: boolean = false;
  @State private replyToId: string = '';
  @State private replyToName: string = '';
  @State private refreshing: boolean = false;
  @State private commentSort: string = 'default';
  @State private expandedContentIds: string[] = [];
  @State private showEmoji: boolean = false;
  @State private previewUrl: string = '';
  @State private threadList: ForumReplyThread[] = [];
  @State private replyTick: number = 0;
  private postId: string = '';
  private repo: ForumRepository = ForumRepository.getInstance();
  private emojis: string[] = CommentEmojis.all();

  private pageReady: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as ForumDetailParams;
    this.postId = params !== undefined && params.postId !== undefined ? params.postId : '';
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
    this.threadList = ForumUi.threads(this.replies(), this.commentSort === 'latest');
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

  private previewChildren(thread: ForumReplyThread): ForumReplyRow[] {
    const all = thread.children;
    if (all.length <= ForumUi.PREVIEW_CHILD) {
      return all;
    }
    const out: ForumReplyRow[] = [];
    for (let i = 0; i < ForumUi.PREVIEW_CHILD; i++) {
      out.push(all[i]);
    }
    return out;
  }

  private hiddenChildCount(thread: ForumReplyThread): number {
    const n = thread.children.length - ForumUi.PREVIEW_CHILD;
    return n > 0 ? n : 0;
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
    return I18n.t('forum_write_comment', this.lang);
  }

  private postImages(): string[] {
    const post = this.post;
    if (post === null || post.images === undefined) {
      const empty: string[] = [];
      return empty;
    }
    return post.images;
  }

  private gridImages(): string[] {
    const all = this.postImages();
    if (all.length <= 3) {
      return all;
    }
    const out: string[] = [];
    out.push(all[0]);
    out.push(all[1]);
    out.push(all[2]);
    return out;
  }

  private imageExtra(url: string): number {
    const all = this.postImages();
    if (all.length <= 3) {
      return 0;
    }
    const last = this.gridImages();
    if (last.length === 0) {
      return 0;
    }
    if (last[last.length - 1] === url) {
      return all.length - 3;
    }
    return 0;
  }

  private isMine(): boolean {
    const post = this.post;
    if (post === null) {
      return false;
    }
    return mallBool(post.mine);
  }

  private postNickname(): string {
    return this.post === null ? '' : mallStr(this.post.nickname);
  }

  private postAvatar(): string {
    return this.post === null ? '' : mallStr(this.post.avatar);
  }

  private postTitle(): string {
    return this.post === null ? '' : mallStr(this.post.title);
  }

  private postContent(): string {
    return this.post === null ? '' : mallStr(this.post.content);
  }

  private postCategory(): string {
    return this.post === null ? '' : mallStr(this.post.categoryName);
  }

  private postTime(): string {
    return this.post === null ? '' : mallStr(this.post.createTime);
  }

  private postHint(): string {
    return this.post === null ? '' : mallStr(this.post.rejectHint);
  }

  private postPending(): boolean {
    return this.post === null ? false : mallBool(this.post.pending);
  }

  private postRejected(): boolean {
    return this.post === null ? false : mallBool(this.post.rejected);
  }

  private postMember(): boolean {
    return this.post === null ? false : mallBool(this.post.member);
  }

  private postLiked(): boolean {
    return this.post === null ? false : mallBool(this.post.liked);
  }

  private postFavored(): boolean {
    return this.post === null ? false : mallBool(this.post.favored);
  }

  private postViewCount(): number {
    return this.post === null ? 0 : mallNum(this.post.viewCount);
  }

  private postLikeCount(): number {
    return this.post === null ? 0 : mallNum(this.post.likeCount);
  }

  private postReplyCount(): number {
    return this.post === null ? 0 : mallNum(this.post.replyCount);
  }

  private showTitle(): boolean {
    const post = this.post;
    if (post === null) {
      return false;
    }
    const title = mallStr(post.title);
    const content = mallStr(post.content);
    if (title.length === 0) {
      return false;
    }
    return content.indexOf(title) !== 0;
  }

  private likeColor(on: boolean): string {
    return on ? '#2563EB' : '#9CA3AF';
  }

  private likePost(): void {
    LoginGate.ensure(I18n.t('blog_like', this.lang), () => {
      this.repo.toggleLike('post', this.postId).then((res) => {
        const current = this.post;
        if (current === null) {
          return;
        }
        const updated = copyForumPost(current);
        updated.liked = res.on === true;
        updated.likeCount = mallNum(res.count);
        this.post = updated;
        ForumRepository.bumpList();
      }).catch((err: Error) => promptAction.showToast({ message: err.message }));
    });
  }

  private toggleFav(): void {
    LoginGate.ensure(I18n.t('forum_fav', this.lang), () => {
      this.repo.toggleFavorite(this.postId).then((res) => {
        const current = this.post;
        if (current === null) {
          return;
        }
        const updated = copyForumPost(current);
        updated.favored = res.on === true;
        updated.favoriteCount = mallNum(res.count);
        this.post = updated;
        ForumRepository.bumpList();
        promptAction.showToast({
          message: res.on === true ? I18n.t('fav_on', this.lang) : I18n.t('fav_off', this.lang)
        });
      }).catch((err: Error) => promptAction.showToast({ message: err.message }));
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

  private expandThread(thread: ForumReplyThread): void {
    this.openAllReplies(mallStr(thread.root.id));
  }

  private openAllReplies(rootId: string): void {
    router.pushUrl({
      url: 'pages/forum/ForumRepliesPage',
      params: { 'postId': this.postId, 'rootId': rootId }
    });
  }

  private followSoon(): void {
    promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
  }

  private insertEmoji(emoji: string): void {
    this.replyText = `${this.replyText}${emoji}`;
  }

  private confirmDelete(): void {
    promptAction.showDialog({
      title: I18n.t('delete', this.lang),
      message: I18n.t('forum_delete_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('delete', this.lang), color: '#DC2626' }
      ]
    }).then((res: DialogResult) => {
      if (res.index !== 1) {
        return;
      }
      this.repo.deletePost(this.postId).then(() => {
        promptAction.showToast({ message: I18n.t('forum_deleted', this.lang) });
        ForumRepository.bumpList();
        router.back();
      }).catch((err: Error) => {
        promptAction.showToast({
          message: err.message.length > 0 ? err.message : I18n.t('forum_delete_fail', this.lang)
        });
      });
    }).catch(() => {
    });
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
    Stack() {
      Column() {
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.text_primary'))
            .padding({ right: 8 })
            .onClick(() => router.back())
          Text(I18n.t('forum_detail', this.lang))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Text(this.postFavored() ? '★' : '☆')
            .fontSize(22)
            .fontColor(this.postFavored() ? '#F59E0B' : '#6B7280')
            .padding({ left: 10, right: 6 })
            .onClick(() => this.toggleFav())
          if (this.isMine()) {
            Text(I18n.t('delete', this.lang))
              .fontSize(14)
              .fontColor('#DC2626')
              .padding({ left: 8, top: 6, bottom: 6 })
              .onClick(() => this.confirmDelete())
          }
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
          Refresh({ refreshing: this.refreshing }) {
            List({ space: 0 }) {
              ListItem() {
                this.postBody()
              }
              ListItem() {
                this.commentHeader()
              }
              if (this.threadList.length === 0) {
                ListItem() {
                  Text(I18n.t('forum_reply_empty', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.text_muted'))
                    .width('100%')
                    .padding({ left: 12, right: 12, top: 16, bottom: 16 })
                }
              } else {
                ForEach(this.threadList, (thread: ForumReplyThread) => {
                  ListItem() {
                    this.threadCard(thread)
                  }
                  .margin({ left: 12, right: 12, bottom: 10 })
                }, (thread: ForumReplyThread) =>
                  `${this.replyTick}-${mallStr(thread.root.id)}-${thread.floor}-${mallNum(thread.root.likeCount)}-${thread.children.length}-${mallBool(thread.root.pending) ? 1 : 0}-${mallStr(thread.root.rejectHint)}`)
              }
              ListItem() {
                Row().width('100%').height(12)
              }
            }
            .width('100%')
            .height('100%')
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

      if (this.previewUrl.length > 0) {
        Stack() {
          Image(this.previewUrl)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
          Text(I18n.t('image_preview_close', this.lang))
            .fontSize(15)
            .fontColor('#FFFFFF')
            .padding({ left: 16, right: 16, top: 46, bottom: 12 })
            .align(Alignment.TopStart)
            .onClick(() => {
              this.previewUrl = '';
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .onClick(() => {
          this.previewUrl = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  postBody() {
    Column({ space: 12 }) {
      Row() {
        this.authorAvatar()
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(this.postNickname())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
            Text(I18n.t('forum_author', this.lang))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#2563EB')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
            if (this.postMember()) {
              Text('VIP')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#D97706')
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(ForumUi.relativeTime(this.postTime(), this.lang))
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        // if (!this.isMine()) {
        //   Text(I18n.t('forum_follow', this.lang))
        //     .fontSize(13)
        //     .fontColor('#FFFFFF')
        //     .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        //     .borderRadius(16)
        //     .backgroundColor('#2563EB')
        //     .onClick(() => this.followSoon())
        // }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.showTitle()) {
        Text(this.postTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
      }
      Row({ space: 8 }) {
        if (this.postCategory().length > 0) {
          Text(this.postCategory())
            .fontSize(12)
            .fontColor(ForumUi.catTone(this.postCategory()).fg)
            .backgroundColor(ForumUi.catTone(this.postCategory()).bg)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .borderRadius(12)
        }
        if (this.post !== null && mallBool(this.post.featured)) {
          Text(I18n.t('forum_featured', this.lang))
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#D97706')
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .borderRadius(12)
        }
      }
      if (this.postRejected() || this.postPending()) {
        Text(this.postHint().length > 0 ? this.postHint() :
          (this.postPending() ? I18n.t('forum_pending', this.lang) : I18n.t('forum_rejected', this.lang)))
          .fontSize(13)
          .fontColor('#B45309')
          .width('100%')
      }
      Text(this.postContent())
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(26)
        .width('100%')

      this.imageGrid()

      Text(I18n.tf('forum_edited', this.postTime(), this.lang))
        .fontSize(12)
        .fontColor('#9CA3AF')
        .width('100%')

      Row({ space: 18 }) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_view'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor('#9CA3AF')
          Text(I18n.tf('forum_views', ForumUi.formatCount(this.postViewCount()), this.lang))
            .fontSize(13)
            .fontColor('#6B7280')
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_comment'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor('#9CA3AF')
          Text(I18n.tf('forum_comments', ForumUi.formatCount(this.postReplyCount()), this.lang))
            .fontSize(13)
            .fontColor('#6B7280')
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_comment_like'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor(this.likeColor(this.postLiked()))
          Text(I18n.tf('forum_likes', ForumUi.formatCount(this.postLikeCount()), this.lang))
            .fontSize(13)
            .fontColor(this.likeColor(this.postLiked()))
        }
        .onClick(() => this.likePost())
      }
      .width('100%')
      .padding({ top: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  authorAvatar() {
    if (this.postAvatar().length > 0) {
      Image(this.postAvatar())
        .width(44)
        .height(44)
        .borderRadius(22)
        .objectFit(ImageFit.Cover)
        .flexShrink(0)
    } else {
      Column() {
        Text(ForumUi.nickInitial(this.postNickname()))
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(ForumUi.avatarColor(this.postNickname()))
      .flexShrink(0)
    }
  }

  @Builder
  imageGrid() {
    if (this.postImages().length === 1) {
      Image(this.postImages()[0])
        .width('100%')
        .height(180)
        .objectFit(ImageFit.Cover)
        .borderRadius(10)
        .onClick(() => {
          this.previewUrl = this.postImages()[0];
        })
    } else if (this.gridImages().length > 0) {
      Row({ space: 6 }) {
        ForEach(this.gridImages(), (url: string) => {
          Stack() {
            Image(url)
              .width('100%')
              .aspectRatio(1)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
            if (this.imageExtra(url) > 0) {
              Column() {
                Text(`+${this.imageExtra(url)}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .width('100%')
              .aspectRatio(1)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#99000000')
              .borderRadius(8)
            }
          }
          .layoutWeight(1)
          .onClick(() => {
            this.previewUrl = url;
          })
        }, (url: string) => url)
      }
      .width('100%')
    }
  }

  @Builder
  commentHeader() {
    Row() {
      Text(I18n.tf('forum_all_comments', `${this.replies().length}`, this.lang))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .onClick(() => this.openAllReplies(''))
      Text(I18n.t('forum_sort_default', this.lang))
        .fontSize(13)
        .fontColor(this.commentSort === 'default' ? '#2563EB' : '#6B7280')
        .padding({ left: 8, top: 4, bottom: 4 })
        .onClick(() => {
          if (this.commentSort === 'default') {
            return;
          }
          this.commentSort = 'default';
          this.syncThreads();
        })
      Text(I18n.t('forum_sort_latest', this.lang))
        .fontSize(13)
        .fontColor(this.commentSort === 'latest' ? '#2563EB' : '#6B7280')
        .padding({ left: 8, top: 4, bottom: 4 })
        .onClick(() => {
          if (this.commentSort === 'latest') {
            return;
          }
          this.commentSort = 'latest';
          this.syncThreads();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12, top: 16, bottom: 12 })
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
        }
      })
      if (this.previewChildren(thread).length > 0) {
        Column({ space: 8 }) {
          ForEach(this.previewChildren(thread), (item: ForumReplyRow) => {
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
              }
            })
          }, (item: ForumReplyRow) =>
            `${this.replyTick}-${mallStr(item.reply.id)}-${item.depth}-${mallNum(item.reply.likeCount)}-${mallStr(item.reply.content)}`)
          if (this.hiddenChildCount(thread) > 0) {
            Text(I18n.tf('forum_more_replies', `${thread.children.length}`, this.lang))
              .fontSize(13)
              .fontColor('#2563EB')
              .padding({ top: 2, bottom: 2 })
              .onClick(() => this.expandThread(thread))
          }
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
