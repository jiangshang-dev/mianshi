import { promptAction, router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { I18n } from '../../common/i18n/I18n';
import { mallBool } from '../../common/models/BlogTypes';
import {
  ForumCategory,
  ForumCatTone,
  ForumFilter,
  ForumPost,
  ForumTab,
  copyForumPost
} from '../../common/models/ForumTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { ForumRepository } from '../../data/repository/ForumRepository';
import { LoginGate } from '../../common/utils/LoginGate';

interface DialogResult {
  index: number;
}

@Component
export struct ForumPage {
  @StorageLink('appLang') @Watch('onLangChange') lang: string = I18n.HANS;
  @StorageLink('forumListTick') @Watch('onForumListTick') forumListTick: number = 0;
  @State private tabs: ForumTab[] = [];
  @State private filters: ForumFilter[] = [];
  @State private tabId: string = 'all';
  @State private sortId: string = 'latest';
  @State private keyword: string = '';
  @State private keywordDraft: string = '';
  @State private searchOpen: boolean = false;
  @State private posts: ForumPost[] = [];
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  @State private pageNo: number = 1;
  @State private finished: boolean = false;
  private repo: ForumRepository = ForumRepository.getInstance();
  private lastTick: number = 0;

  aboutToAppear(): void {
    this.lastTick = this.forumListTick;
    this.syncFilters();
    this.reload();
  }

  onLangChange(): void {
    this.syncFilters();
    if (this.tabs.length > 0 && this.tabs[0].id === 'all') {
      const next: ForumTab[] = [];
      const first: ForumTab = { id: 'all', name: I18n.t('forum_recommend', this.lang) };
      next.push(first);
      for (let i = 1; i < this.tabs.length; i++) {
        next.push(this.tabs[i]);
      }
      this.tabs = next;
    }
  }

  onForumListTick(): void {
    if (this.forumListTick === this.lastTick) {
      return;
    }
    this.lastTick = this.forumListTick;
    this.reload();
  }

  private syncFilters(): void {
    const latest: ForumFilter = { id: 'latest', name: I18n.t('forum_latest', this.lang) };
    const hot: ForumFilter = { id: 'hot', name: I18n.t('forum_hot', this.lang) };
    // const follow: ForumFilter = { id: 'follow', name: I18n.t('forum_followed', this.lang) };
    const list: ForumFilter[] = [];
    list.push(latest);
    list.push(hot);
    // list.push(follow);
    this.filters = list;
  }

  private async reload(): Promise<void> {
    const showSpinner = this.posts.length === 0;
    if (showSpinner) {
      this.loading = true;
    }
    this.pageNo = 1;
    this.finished = false;
    try {
      const cats = await this.repo.categories();
      const tabs: ForumTab[] = [{ id: 'all', name: I18n.t('forum_recommend', this.lang) }];
      for (let i = 0; i < cats.length; i++) {
        const cat: ForumCategory = cats[i];
        const id = mallStr(cat.id);
        if (id.length > 0) {
          const tab: ForumTab = { id: id, name: mallStr(cat.name) };
          tabs.push(tab);
        }
      }
      this.tabs = tabs;
      await this.loadPage(true);
    } catch (err) {
      this.posts = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('forum_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private async loadPage(reset: boolean): Promise<void> {
    const page = await this.repo.posts(this.tabId, this.pageNo, this.sortId, this.keyword);
    const records = page.records !== undefined ? page.records : [];
    if (reset) {
      this.posts = records;
    } else {
      const next: ForumPost[] = [];
      for (let i = 0; i < this.posts.length; i++) {
        next.push(this.posts[i]);
      }
      for (let i = 0; i < records.length; i++) {
        next.push(records[i]);
      }
      this.posts = next;
    }
    this.finished = records.length < 20;
  }

  private pullRefresh(): void {
    this.refreshing = true;
    this.reload().then(() => {
      this.refreshing = false;
    }).catch(() => {
      this.refreshing = false;
    });
  }

  private refreshPosts(): void {
    this.pageNo = 1;
    this.finished = false;
    this.loading = this.posts.length === 0;
    this.loadPage(true).catch(() => {
      this.posts = [];
    }).then(() => {
      this.loading = false;
    });
  }

  private selectTab(id: string): void {
    if (this.tabId === id) {
      return;
    }
    this.tabId = id;
    this.refreshPosts();
  }

  private selectFilter(id: string): void {
    if (id === 'follow') {
      promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
      return;
    }
    if (this.sortId === id) {
      return;
    }
    this.sortId = id;
    this.refreshPosts();
  }

  private applySearch(): void {
    this.keyword = this.keywordDraft.trim();
    this.refreshPosts();
  }

  private toggleSearch(): void {
    this.searchOpen = !this.searchOpen;
    if (!this.searchOpen && this.keyword.length > 0) {
      this.keyword = '';
      this.keywordDraft = '';
      this.refreshPosts();
    }
  }

  private openPost(item: ForumPost): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/forum/ForumDetailPage',
      params: { 'postId': id }
    });
  }

  private openCompose(): void {
    LoginGate.ensure(I18n.t('forum_compose', this.lang), () => {
      router.pushUrl({
        url: 'pages/forum/ForumComposePage',
        params: { 'categoryId': this.tabId }
      });
    });
  }

  private isMine(item: ForumPost): boolean {
    return mallBool(item.mine);
  }

  private cardTitle(item: ForumPost): string {
    const title = mallStr(item.title);
    if (title.length > 0) {
      return title;
    }
    return mallStr(item.summary);
  }

  private cardSummary(item: ForumPost): string {
    const title = mallStr(item.title);
    const summary = mallStr(item.summary);
    if (summary.length === 0) {
      return '';
    }
    if (title.length > 0 && summary.indexOf(title) === 0) {
      return summary.substring(title.length).trim();
    }
    if (title === summary) {
      return '';
    }
    return summary;
  }

  private likeColor(on: boolean): string {
    return on ? '#2563EB' : '#9CA3AF';
  }

  private nickInitial(name: string): string {
    if (name.length === 0) {
      return '?';
    }
    return name.substring(0, 1);
  }

  private avatarColor(name: string): string {
    if (name.length === 0) {
      return '#60A5FA';
    }
    const palette: string[] = ['#60A5FA', '#34D399', '#F59E0B', '#A78BFA', '#F87171'];
    return palette[name.charCodeAt(0) % palette.length];
  }

  private catTone(name: string): ForumCatTone {
    if (name.indexOf('面试') >= 0) {
      const tone: ForumCatTone = { bg: '#DBEAFE', fg: '#2563EB' };
      return tone;
    }
    if (name.indexOf('求职') >= 0) {
      const tone: ForumCatTone = { bg: '#D1FAE5', fg: '#059669' };
      return tone;
    }
    if (name.indexOf('问答') >= 0) {
      const tone: ForumCatTone = { bg: '#EDE9FE', fg: '#7C3AED' };
      return tone;
    }
    if (name.indexOf('打卡') >= 0) {
      const tone: ForumCatTone = { bg: '#FFEDD5', fg: '#EA580C' };
      return tone;
    }
    const tone: ForumCatTone = { bg: '#F3F4F6', fg: '#6B7280' };
    return tone;
  }

  private relativeTime(raw: string): string {
    if (raw.length < 16) {
      return raw;
    }
    const y = Number.parseInt(raw.substring(0, 4), 10);
    const mo = Number.parseInt(raw.substring(5, 7), 10);
    const d = Number.parseInt(raw.substring(8, 10), 10);
    const h = Number.parseInt(raw.substring(11, 13), 10);
    const mi = Number.parseInt(raw.substring(14, 16), 10);
    const s = raw.length >= 19 ? Number.parseInt(raw.substring(17, 19), 10) : 0;
    const then = new Date(y, mo - 1, d, h, mi, s).getTime();
    const diff = Date.now() - then;
    if (diff < 60 * 1000) {
      return I18n.t('forum_just_now', this.lang);
    }
    if (diff < 60 * 60 * 1000) {
      return I18n.tf('forum_min_ago', `${Math.floor(diff / 60000)}`, this.lang);
    }
    if (diff < 24 * 60 * 60 * 1000) {
      return I18n.tf('forum_hour_ago', `${Math.floor(diff / 3600000)}`, this.lang);
    }
    if (diff < 7 * 24 * 60 * 60 * 1000) {
      return I18n.tf('forum_day_ago', `${Math.floor(diff / 86400000)}`, this.lang);
    }
    return raw.substring(0, 10);
  }

  private metaLine(item: ForumPost): string {
    const time = this.relativeTime(mallStr(item.createTime));
    const cat = mallStr(item.categoryName);
    if (cat.length === 0) {
      return time;
    }
    return `${time} · ${cat}`;
  }

  private likePost(item: ForumPost): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    LoginGate.ensure(I18n.t('blog_like', this.lang), () => {
      this.repo.toggleLike('post', id).then((res) => {
        const next: ForumPost[] = [];
        for (let i = 0; i < this.posts.length; i++) {
          const row = this.posts[i];
          if (mallStr(row.id) === id) {
            const updated = copyForumPost(row);
            updated.liked = res.on === true;
            updated.likeCount = mallNum(res.count);
            next.push(updated);
          } else {
            next.push(row);
          }
        }
        this.posts = next;
      }).catch((err: Error) => promptAction.showToast({ message: err.message }));
    });
  }

  private favSoon(): void {
    promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
  }

  private sharePost(item: ForumPost): void {
    const title = this.cardTitle(item);
    const summary = this.cardSummary(item);
    const text = summary.length > 0 ? `${title}\n${summary}` : title;
    if (text.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      promptAction.showToast({ message: I18n.t('forum_copied', this.lang) });
    }).catch(() => {
      promptAction.showToast({ message: I18n.t('forum_copied', this.lang) });
    });
  }

  private confirmDelete(item: ForumPost): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
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
      this.repo.deletePost(id).then(() => {
        const next: ForumPost[] = [];
        for (let i = 0; i < this.posts.length; i++) {
          if (mallStr(this.posts[i].id) !== id) {
            next.push(this.posts[i]);
          }
        }
        this.posts = next;
        promptAction.showToast({ message: I18n.t('forum_deleted', this.lang) });
      }).catch((err: Error) => {
        promptAction.showToast({
          message: err.message.length > 0 ? err.message : I18n.t('forum_delete_fail', this.lang)
        });
      });
    }).catch(() => {
    });
  }

  private emptyText(): string {
    if (this.keyword.length > 0) {
      return I18n.t('forum_search_empty', this.lang);
    }
    return I18n.t('forum_empty', this.lang);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text(I18n.t('tab_forum', this.lang))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Image($r('app.media.ic_forum_search'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
            .fillColor('#111827')
            .onClick(() => this.toggleSearch())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 2 })
        .alignItems(VerticalAlign.Center)

        if (this.searchOpen) {
          Row({ space: 8 }) {
            TextInput({ placeholder: I18n.t('forum_search_ph', this.lang), text: this.keywordDraft })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#FFFFFF')
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_muted'))
              .borderRadius(18)
              .padding({ left: 12, right: 12 })
              .onChange((v: string) => {
                this.keywordDraft = v;
              })
              .onSubmit(() => {
                this.applySearch();
              })
            Text(I18n.t('search', this.lang))
              .fontSize(14)
              .fontColor($r('app.color.accent'))
              .onClick(() => this.applySearch())
          }
          .width('100%')
          .height(44)
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }

        Scroll() {
          Row({ space: 18 }) {
            ForEach(this.tabs, (tab: ForumTab) => {
              Column({ space: 4 }) {
                Text(tab.name)
                  .fontSize(15)
                  .fontWeight(this.tabId === tab.id ? FontWeight.Medium : FontWeight.Regular)
                  .fontColor(this.tabId === tab.id ? $r('app.color.accent') : $r('app.color.text_secondary'))
                Row()
                  .width(20)
                  .height(3)
                  .borderRadius(2)
                  .backgroundColor(this.tabId === tab.id ? $r('app.color.accent') : Color.Transparent)
              }
              .onClick(() => this.selectTab(tab.id))
            }, (tab: ForumTab) => tab.id)
          }
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Bottom)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .width('100%')
        .height(36)

        Row({ space: 8 }) {
          ForEach(this.filters, (item: ForumFilter) => {
            Row({ space: 4 }) {
              if (item.id === 'hot') {
                Text('🔥').fontSize(12)
              } else if (item.id === 'follow') {
                Text('👤').fontSize(12)
              }
              Text(item.name)
                .fontSize(13)
                .fontColor(this.sortId === item.id ? '#FFFFFF' : '#4B5563')
            }
            .padding({ left: 14, right: 14, top: 5, bottom: 5 })
            .borderRadius(16)
            .backgroundColor(this.sortId === item.id ? '#2563EB' : '#F3F4F6')
            .onClick(() => this.selectFilter(item.id))
          }, (item: ForumFilter) => item.id)
        }
        .width('100%')
        .height(36)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Refresh({ refreshing: this.refreshing }) {
          if (this.loading && this.posts.length === 0) {
            Column() {
              LoadingProgress().width(36).height(36)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else if (this.posts.length === 0) {
            Column() {
              Text(this.emptyText()).fontSize(14).fontColor($r('app.color.text_muted'))
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 10 }) {
              ForEach(this.posts, (item: ForumPost) => {
                ListItem() {
                  this.postCard(item)
                }
              }, (item: ForumPost) => `${mallStr(item.id)}-${mallBool(item.liked) ? 1 : 0}-${mallNum(item.likeCount)}-${mallNum(item.replyCount)}-${mallBool(item.featured) ? 1 : 0}`)
            }
            .width('100%')
            .height('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 80 })
            .scrollBar(BarState.Off)
            .onReachEnd(() => {
              if (this.finished || this.loading) {
                return;
              }
              this.pageNo = this.pageNo + 1;
              this.loadPage(false).catch(() => {
                this.pageNo = this.pageNo - 1;
              });
            })
          }
        }
        .layoutWeight(1)
        .width('100%')
        .onRefreshing(() => this.pullRefresh())
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.page_bg'))

      Column() {
        Image($r('app.media.ic_forum_edit'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor('#FFFFFF')
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#2563EB')
      .margin({ right: 16, bottom: 16 })
      .onClick(() => this.openCompose())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  postCard(item: ForumPost) {
    Column({ space: 10 }) {
      Column({ space: 10 }) {
        Row() {
          if (mallStr(item.avatar).length > 0) {
            Image(mallStr(item.avatar))
              .width(36)
              .height(36)
              .borderRadius(18)
              .objectFit(ImageFit.Cover)
              .flexShrink(0)
          } else {
            Column() {
              Text(this.nickInitial(mallStr(item.nickname)))
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(36)
            .height(36)
            .borderRadius(18)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.avatarColor(mallStr(item.nickname)))
            .flexShrink(0)
          }

          Column({ space: 2 }) {
            Row({ space: 6 }) {
              Text(mallStr(item.nickname))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
              if (this.isMine(item)) {
                Text(I18n.t('forum_author', this.lang))
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#F97316')
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(4)
              }
              if (mallBool(item.member)) {
                Text('VIP')
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#D97706')
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(4)
              }
              if (mallBool(item.pinned)) {
                Text(I18n.t('forum_pinned', this.lang))
                  .fontSize(10)
                  .fontColor('#2563EB')
                  .backgroundColor('#DBEAFE')
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(4)
              }
              if (mallBool(item.featured)) {
                Text(I18n.t('forum_featured', this.lang))
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#D97706')
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(4)
              }
            }
            .alignItems(VerticalAlign.Center)
            Text(this.metaLine(item))
              .fontSize(11)
              .fontColor('#9CA3AF')
              .maxLines(1)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })

          if (mallStr(item.categoryName).length > 0) {
            Text(mallStr(item.categoryName))
              .fontSize(11)
              .fontColor(this.catTone(mallStr(item.categoryName)).fg)
              .backgroundColor(this.catTone(mallStr(item.categoryName)).bg)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(10)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        if (this.cardTitle(item).length > 0) {
          Text(this.cardTitle(item))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .width('100%')
        }
        if (mallBool(item.rejected)) {
          Text(mallStr(item.rejectHint).length > 0 ? mallStr(item.rejectHint) : I18n.t('forum_rejected', this.lang))
            .fontSize(12)
            .fontColor('#B45309')
            .width('100%')
        } else if (mallBool(item.pending)) {
          Text(mallStr(item.rejectHint).length > 0 ? mallStr(item.rejectHint) : I18n.t('forum_pending', this.lang))
            .fontSize(12)
            .fontColor('#B45309')
            .width('100%')
        }
        if (this.cardSummary(item).length > 0 && !mallBool(item.rejected)) {
          Text(this.cardSummary(item))
            .fontSize(13)
            .fontColor('#6B7280')
            .maxLines(3)
            .width('100%')
        }
        if (mallStr(item.coverUrl).length > 0) {
          Image(mallStr(item.coverUrl))
            .width('100%')
            .height(140)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.openPost(item))

      Row() {
        Row({ space: 4 }) {
          Image($r('app.media.ic_comment_like'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
            .fillColor(this.likeColor(mallBool(item.liked)))
          Text(`${mallNum(item.likeCount)}`)
            .fontSize(12)
            .fontColor(this.likeColor(mallBool(item.liked)))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .onClick(() => this.likePost(item))

        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_comment'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
            .fillColor('#9CA3AF')
          Text(`${mallNum(item.replyCount)}`)
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.openPost(item))

        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_fav'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
            .fillColor('#9CA3AF')
          Text(I18n.t('forum_fav', this.lang))
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.favSoon())

        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_share'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
            .fillColor('#9CA3AF')
          Text(I18n.t('forum_share', this.lang))
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)
        .onClick(() => this.sharePost(item))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.isMine(item)) {
        Row() {
          Blank()
          Text(I18n.t('delete', this.lang))
            .fontSize(12)
            .fontColor('#DC2626')
            .onClick(() => this.confirmDelete(item))
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 2 })
  }
}
