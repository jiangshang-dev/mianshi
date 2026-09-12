import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BlogArticle, BlogCategory, BlogTab, mallBool } from '../../common/models/BlogTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { NavBackButton } from '../../components/NavBackButton';
import { BlogRepository } from '../../data/repository/BlogRepository';
import { ForumUi } from '../../common/utils/ForumUi';

@Component
export struct BlogPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop showNavBack: boolean = false;
  @StorageLink('blogListTick') @Watch('onBlogListTick') blogListTick: number = 0;
  @State private tabs: BlogTab[] = [];
  @State private tabId: string = 'recommend';
  @State private articles: BlogArticle[] = [];
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  @State private pageNo: number = 1;
  @State private finished: boolean = false;
  private repo: BlogRepository = BlogRepository.getInstance();
  private lastTick: number = 0;

  aboutToAppear(): void {
    this.lastTick = this.blogListTick;
    this.reload();
  }

  onBlogListTick(): void {
    if (this.blogListTick === this.lastTick) {
      return;
    }
    this.lastTick = this.blogListTick;
    this.reload();
  }

  private async reload(): Promise<void> {
    this.loading = this.articles.length === 0;
    this.pageNo = 1;
    this.finished = false;
    try {
      const cats = await this.repo.categories();
      const tabs: BlogTab[] = [{ id: 'recommend', name: I18n.t('blog_recommend', this.lang) }];
      for (let i = 0; i < cats.length; i++) {
        const cat: BlogCategory = cats[i];
        const id = mallStr(cat.id);
        if (id.length > 0) {
          const tab: BlogTab = { id: id, name: mallStr(cat.name) };
          tabs.push(tab);
        }
      }
      this.tabs = tabs;
      await this.loadPage(true);
    } catch (err) {
      this.articles = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('blog_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private async loadPage(reset: boolean): Promise<void> {
    const page = await this.repo.articles(this.tabId, this.pageNo, '');
    const records = page.records !== undefined ? page.records : [];
    if (reset) {
      this.articles = records;
    } else {
      const next: BlogArticle[] = [];
      for (let i = 0; i < this.articles.length; i++) {
        next.push(this.articles[i]);
      }
      for (let i = 0; i < records.length; i++) {
        next.push(records[i]);
      }
      this.articles = next;
    }
    this.finished = records.length < 20;
  }

  private refreshList(): void {
    this.pageNo = 1;
    this.finished = false;
    this.loading = this.articles.length === 0;
    this.loadPage(true).catch(() => {
      this.articles = [];
    }).then(() => {
      this.loading = false;
    });
  }

  private pullRefresh(): void {
    this.refreshing = true;
    this.reload().then(() => {
      this.refreshing = false;
    }).catch(() => {
      this.refreshing = false;
    });
  }

  private selectTab(id: string): void {
    if (this.tabId === id) {
      return;
    }
    this.tabId = id;
    this.refreshList();
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/blog/BlogSearchPage' });
  }

  // private filterSoon(): void {
  //   promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
  // }

  private openArticle(item: BlogArticle): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/blog/BlogDetailPage',
      params: { 'articleId': id }
    });
  }

  private topicItem(): BlogArticle | null {
    if (this.tabId !== 'recommend' || this.articles.length === 0) {
      return null;
    }
    return this.articles[0];
  }

  private featuredItem(): BlogArticle | null {
    const start = this.topicItem() !== null ? 1 : 0;
    if (this.articles.length <= start) {
      return null;
    }
    const item = this.articles[start];
    if (mallStr(item.coverUrl).length === 0 && !mallBool(item.recommend)) {
      return null;
    }
    return item;
  }

  private topicList(): BlogArticle[] {
    const item = this.topicItem();
    const list: BlogArticle[] = [];
    if (item !== null) {
      list.push(item);
    }
    return list;
  }

  private featuredList(): BlogArticle[] {
    const item = this.featuredItem();
    const list: BlogArticle[] = [];
    if (item !== null) {
      list.push(item);
    }
    return list;
  }

  private feedItems(): BlogArticle[] {
    let start = 0;
    if (this.topicItem() !== null) {
      start++;
    }
    if (this.featuredItem() !== null) {
      start++;
    }
    const out: BlogArticle[] = [];
    for (let i = start; i < this.articles.length; i++) {
      out.push(this.articles[i]);
    }
    return out;
  }

  private emptyText(): string {
    return I18n.t('blog_empty', this.lang);
  }

  build() {
    Column() {
      Row() {
        if (this.showNavBack) {
          NavBackButton({ onBack: () => router.back() })
        }
        Text(I18n.t('tab_blog', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Image($r('app.media.ic_forum_search'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor('#111827')
          .onClick(() => this.openSearch())
        // Image($r('app.media.ic_blog_filter'))
        //   .width(22)
        //   .height(22)
        //   .objectFit(ImageFit.Contain)
        //   .fillColor('#111827')
        //   .onClick(() => this.filterSoon())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 2 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row({ space: 18 }) {
          ForEach(this.tabs, (tab: BlogTab) => {
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
          }, (tab: BlogTab) => tab.id)
        }
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Bottom)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .width('100%')
      .height(36)

      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 10 }) {
          if (this.loading && this.articles.length === 0) {
            ListItem() {
              Column() {
                LoadingProgress().width(36).height(36)
              }
              .width('100%')
              .height(280)
              .justifyContent(FlexAlign.Center)
            }
          } else if (this.articles.length === 0) {
            ListItem() {
              Column() {
                Text(this.emptyText()).fontSize(14).fontColor($r('app.color.text_muted'))
              }
              .width('100%')
              .height(280)
              .justifyContent(FlexAlign.Center)
            }
          } else {
            ForEach(this.topicList(), (item: BlogArticle) => {
              ListItem() {
                this.topicCard(item)
              }
            }, (item: BlogArticle) => `topic-${mallStr(item.id)}`)
            ForEach(this.featuredList(), (item: BlogArticle) => {
              ListItem() {
                this.featuredCard(item)
              }
            }, (item: BlogArticle) => `feat-${mallStr(item.id)}`)
            ForEach(this.feedItems(), (item: BlogArticle) => {
              ListItem() {
                this.articleCard(item)
              }
            }, (item: BlogArticle) => mallStr(item.id))
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          if (this.finished || this.loading || this.articles.length === 0) {
            return;
          }
          this.pageNo = this.pageNo + 1;
          this.loadPage(false).catch(() => {
            this.pageNo = this.pageNo - 1;
          });
        })
      }
      .layoutWeight(1)
      .width('100%')
      .onRefreshing(() => this.pullRefresh())
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  topicCard(item: BlogArticle) {
    Column({ space: 8 }) {
      Text(I18n.t('blog_topic', this.lang))
        .fontSize(10)
        .fontColor('#FFFFFF')
        .backgroundColor('#1D4ED8')
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .borderRadius(4)
      Text(mallStr(item.title))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(2)
        .width('100%')
      if (mallStr(item.summary).length > 0) {
        Text(mallStr(item.summary))
          .fontSize(12)
          .fontColor('#DBEAFE')
          .maxLines(2)
          .width('100%')
      }
      Text(I18n.t('blog_view_topic', this.lang))
        .fontSize(13)
        .fontColor('#2563EB')
        .backgroundColor('#FFFFFF')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(14)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(14)
    .linearGradient({ angle: 135, colors: [['#2563EB', 0], ['#1D4ED8', 1]] })
    .onClick(() => this.openArticle(item))
  }

  @Builder
  featuredCard(item: BlogArticle) {
    Column({ space: 10 }) {
      if (mallStr(item.coverUrl).length > 0) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(mallStr(item.coverUrl))
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
            .borderRadius(10)
          Text(I18n.t('blog_featured', this.lang))
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#2563EB')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(4)
            .margin({ left: 10, top: 10 })
        }
        .width('100%')
      }
      Text(mallStr(item.title))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .maxLines(2)
        .width('100%')
      if (mallStr(item.summary).length > 0) {
        Text(mallStr(item.summary))
          .fontSize(13)
          .fontColor('#6B7280')
          .maxLines(2)
          .width('100%')
      }
      this.metaRow(item)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => this.openArticle(item))
  }

  @Builder
  articleCard(item: BlogArticle) {
    Row({ space: 12 }) {
      if (mallStr(item.coverUrl).length > 0) {
        Image(mallStr(item.coverUrl))
          .width(92)
          .height(92)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .flexShrink(0)
      }
      Column({ space: 6 }) {
        Text(mallStr(item.title))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (mallStr(item.summary).length > 0) {
          Text(mallStr(item.summary))
            .fontSize(12)
            .fontColor('#6B7280')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        this.metaRow(item)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => this.openArticle(item))
  }

  @Builder
  metaRow(item: BlogArticle) {
    Row({ space: 6 }) {
      Column() {
        Text(ForumUi.nickInitial(mallStr(item.authorName)))
          .fontSize(9)
          .fontColor('#FFFFFF')
      }
      .width(18)
      .height(18)
      .borderRadius(9)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(ForumUi.avatarColor(mallStr(item.authorName)))
      Text(mallStr(item.authorName))
        .fontSize(11)
        .fontColor('#6B7280')
        .maxLines(1)
      if (mallStr(item.categoryName).length > 0) {
        Text(mallStr(item.categoryName))
          .fontSize(10)
          .fontColor(ForumUi.catTone(mallStr(item.categoryName)).fg)
          .backgroundColor(ForumUi.catTone(mallStr(item.categoryName)).bg)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .borderRadius(4)
      }
      if (mallBool(item.vipOnly)) {
        Text('VIP')
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor('#D97706')
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .borderRadius(4)
      }
      Blank()
      Row({ space: 3 }) {
        Image($r('app.media.ic_forum_view'))
          .width(12)
          .height(12)
          .fillColor('#9CA3AF')
        Text(ForumUi.formatCount(mallNum(item.viewCount)))
          .fontSize(11)
          .fontColor('#9CA3AF')
      }
      Row({ space: 3 }) {
        Image($r('app.media.ic_comment_like'))
          .width(12)
          .height(12)
          .fillColor('#9CA3AF')
        Text(ForumUi.formatCount(mallNum(item.likeCount)))
          .fontSize(11)
          .fontColor('#9CA3AF')
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
