import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { QuestionItem } from '../../common/models/Types';
import { BlogArticle } from '../../common/models/BlogTypes';
import { BookItem } from '../../common/models/BookTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BookCover } from '../../components/BookCover';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { BlogRepository } from '../../data/repository/BlogRepository';
import { BookRepository } from '../../data/repository/BookRepository';
import { RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { LoginGate } from '../../common/utils/LoginGate';

interface HomeGridItem {
  titleKey: string;
  subKey: string;
  action: string;
}

@Component
export struct HomePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('blogEnabled') blogEnabled: boolean = true;
  @StorageLink('forumEnabled') forumEnabled: boolean = true;
  @StorageLink('interviewAiEnabled') interviewAiEnabled: boolean = true;
  @State private loading: boolean = true;
  @State private hotQs: QuestionItem[] = [];
  @State private books: BookItem[] = [];
  @State private blogs: BlogArticle[] = [];
  @State private unread: number = 0;
  private qRepo: QuestionRepository = QuestionRepository.getInstance();
  private blogRepo: BlogRepository = BlogRepository.getInstance();
  private bookRepo: BookRepository = BookRepository.getInstance();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.refreshUnread();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.hotQs = (await this.qRepo.getHot(ctx)).slice(0, 4);
    } catch (_e) {
      this.hotQs = [];
    }
    try {
      const home = await this.bookRepo.home();
      const weekly = home.weekly !== undefined ? home.weekly : [];
      const featured = home.featured !== undefined ? home.featured : [];
      this.books = weekly.length > 0 ? weekly.slice(0, 6) : featured.slice(0, 6);
    } catch (_e) {
      this.books = [];
    }
    if (this.blogEnabled) {
      try {
        const page = await this.blogRepo.articles('recommend', 1, '');
        this.blogs = page.records !== undefined ? page.records.slice(0, 3) : [];
      } catch (_e) {
        this.blogs = [];
      }
    }
    await this.refreshUnread();
    this.loading = false;
  }

  private async refreshUnread(): Promise<void> {
    if (!AuthRepository.getInstance().isLoggedIn()) {
      this.unread = 0;
      return;
    }
    const uid = AppStorage.get('userId') as string;
    if (uid === undefined || uid.length === 0) {
      this.unread = 0;
      return;
    }
    this.unread = await RemoteApiDataSource.inboxUnread(uid);
  }

  private greet(): string {
    const h = new Date().getHours();
    if (h < 11) {
      return I18n.t('home_greet_morning', this.lang);
    }
    if (h < 18) {
      return I18n.t('home_greet_afternoon', this.lang);
    }
    return I18n.t('home_greet_evening', this.lang);
  }

  private formatCount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}w`;
    }
    if (n >= 1000) {
      return `${(n / 1000).toFixed(1)}k`;
    }
    return `${n}`;
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/search/SearchPage' });
  }

  private openInbox(): void {
    LoginGate.ensure(I18n.t('inbox_title', this.lang), () => {
      router.pushUrl({ url: 'pages/profile/InboxPage' });
    });
  }

  private openTab(index: number): void {
    AppStorage.setOrCreate('mainTabIndex', index);
  }

  private onGrid(action: string): void {
    if (action === 'bank') {
      this.openTab(1);
      return;
    }
    if (action === 'book') {
      this.openTab(3);
      return;
    }
    if (action === 'blog') {
      if (this.blogEnabled) {
        router.pushUrl({ url: 'pages/blog/BlogHubPage' });
      }
      return;
    }
    if (action === 'forum') {
      if (this.forumEnabled) {
        router.pushUrl({ url: 'pages/forum/ForumHubPage' });
      }
      return;
    }
    if (action === 'ai') {
      if (this.interviewAiEnabled) {
        this.openTab(2);
      }
      return;
    }
    if (action === 'fav') {
      LoginGate.ensure(I18n.t('favorites', this.lang), () => {
        router.pushUrl({ url: 'pages/profile/FavoritesPage' });
      });
      return;
    }
    if (action === 'mall') {
      LoginGate.ensure(I18n.t('mall_title', this.lang), () => {
        router.pushUrl({ url: 'pages/mall/MallPage' });
      });
      return;
    }
    if (action === 'more') {
      this.openTab(4);
    }
  }

  private gridItems(): HomeGridItem[] {
    const items: HomeGridItem[] = [];
    const a: HomeGridItem = { titleKey: 'home_grid_bank', subKey: 'home_grid_bank_sub', action: 'bank' };
    const b: HomeGridItem = { titleKey: 'home_grid_book', subKey: 'home_grid_book_sub', action: 'book' };
    const c: HomeGridItem = { titleKey: 'home_grid_blog', subKey: 'home_grid_blog_sub', action: 'blog' };
    const d: HomeGridItem = { titleKey: 'home_grid_forum', subKey: 'home_grid_forum_sub', action: 'forum' };
    const e: HomeGridItem = { titleKey: 'home_grid_ai', subKey: 'home_grid_ai_sub', action: 'ai' };
    const f: HomeGridItem = { titleKey: 'home_grid_fav', subKey: 'home_grid_fav_sub', action: 'fav' };
    const g: HomeGridItem = { titleKey: 'home_grid_mall', subKey: 'home_grid_mall_sub', action: 'mall' };
    const h: HomeGridItem = { titleKey: 'home_grid_more', subKey: 'home_grid_more_sub', action: 'more' };
    items.push(a);
    items.push(b);
    items.push(c);
    items.push(d);
    items.push(e);
    items.push(f);
    items.push(g);
    items.push(h);
    return items;
  }

  private gridMedia(action: string): Resource {
    if (action === 'bank') {
      return $r('app.media.home_grid_bank');
    }
    if (action === 'book') {
      return $r('app.media.home_grid_book');
    }
    if (action === 'blog') {
      return $r('app.media.home_grid_blog');
    }
    if (action === 'forum') {
      return $r('app.media.home_grid_forum');
    }
    if (action === 'ai') {
      return $r('app.media.home_grid_ai');
    }
    if (action === 'fav') {
      return $r('app.media.home_grid_fav');
    }
    if (action === 'mall') {
      return $r('app.media.home_grid_mall');
    }
    return $r('app.media.home_grid_more');
  }

  private openQuestion(q: QuestionItem): void {
    router.pushUrl({
      url: 'pages/bank/QuestionDetailPage',
      params: { 'id': q.id, 'title': q.title }
    });
  }

  private openBook(item: BookItem): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({ url: 'pages/book/BookReaderPage', params: { 'id': id } });
  }

  private openBlog(a: BlogArticle): void {
    const id = mallStr(a.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({ url: 'pages/blog/BlogDetailPage', params: { 'articleId': id } });
  }

  private previewTags(q: QuestionItem): string[] {
    if (q.tags.length <= 2) {
      return q.tags;
    }
    return [q.tags[0], q.tags[1]];
  }

  private rankColor(i: number): string {
    if (i === 0) {
      return '#EF4444';
    }
    if (i === 1) {
      return '#F97316';
    }
    if (i === 2) {
      return '#EAB308';
    }
    return '#94A3B8';
  }

  private blogCover(a: BlogArticle): string {
    return mallStr(a.coverUrl);
  }

  private rankBg(i: number): string {
    if (i === 0) {
      return '#FEE2E2';
    }
    if (i === 1) {
      return '#FFEDD5';
    }
    if (i === 2) {
      return '#FEF9C3';
    }
    return '#F1F5F9';
  }

  @Builder
  sectionHeadHot() {
    Row() {
      Text(`🔥 ${I18n.t('home_hot_q', this.lang)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .layoutWeight(1)
      Text(I18n.t('home_more_all', this.lang))
        .fontSize(12)
        .fontColor('#94A3B8')
        .onClick(() => this.openTab(1))
    }
    .width('100%')
  }

  @Builder
  sectionHeadBook() {
    Row() {
      Text(`📖 ${I18n.t('home_rec_books', this.lang)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .layoutWeight(1)
      Text(I18n.t('more', this.lang))
        .fontSize(12)
        .fontColor('#94A3B8')
        .onClick(() => this.openTab(3))
    }
    .width('100%')
  }

  @Builder
  sectionHeadBlog() {
    Row() {
      Text(`📋 ${I18n.t('home_rec_blog', this.lang)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')
        .layoutWeight(1)
      Text(I18n.t('more', this.lang))
        .fontSize(12)
        .fontColor('#94A3B8')
        .onClick(() => {
          router.pushUrl({ url: 'pages/blog/BlogHubPage' });
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 顶部背景区：问候 + 搜索（浅蓝渐变铺满顶栏）
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text(`${this.greet()}👋`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111827')
                Text(I18n.t('home_explore_sub', this.lang))
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Stack({ alignContent: Alignment.TopEnd }) {
                Image($r('app.media.home_bell'))
                  .width(36)
                  .height(36)
                  .objectFit(ImageFit.Contain)
                  .onClick(() => this.openInbox())
                if (this.unread > 0) {
                  Text(this.unread > 99 ? '99+' : `${this.unread}`)
                    .fontSize(9)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                    .constraintSize({ minWidth: 14 })
                    .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                    .backgroundColor('#EF4444')
                    .borderRadius(8)
                    .offset({ x: 2, y: -2 })
                }
              }
            }
            .width('100%')

            Row({ space: 10 }) {
              Image($r('app.media.home_search'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
              Text(I18n.t('home_search_ph_v2', this.lang))
                .fontSize(14)
                .fontColor('#9CA3AF')
                .layoutWeight(1)
              Image($r('app.media.home_scan'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
            }
            .width('100%')
            .height(44)
            .padding({ left: 14, right: 14 })
            .backgroundColor('#FFFFFF')
            .borderRadius(22)
            .shadow({ radius: 6, color: '#0F172A0D', offsetY: 1 })
            .onClick(() => this.openSearch())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          .linearGradient({
            angle: 180,
            colors: [['#DCEBFF', 0], ['#EAF2FF', 0.45], ['#F5F6F8', 1]]
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

          // 正文：统一左右 16 边距
          Column({ space: 14 }) {
            if (this.interviewAiEnabled) {
              Stack({ alignContent: Alignment.Start }) {
                Image($r('app.media.home_ai_banner'))
                  .width('100%')
                  .height(132)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(16)

                Column({ space: 6 }) {
                  Text(I18n.t('home_ai_hero_title', this.lang))
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                  Text(I18n.t('home_ai_hero_sub1', this.lang))
                    .fontSize(11)
                    .fontColor('#E8F1FF')
                  Text(I18n.t('home_ai_hero_sub2', this.lang))
                    .fontSize(11)
                    .fontColor('#E8F1FF')
                  Row() {
                    Text(I18n.t('home_ai_hero_btn', this.lang))
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#FFFFFF')
                      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                      .backgroundColor('#1D4ED8')
                      .borderRadius(16)
                  }
                  .margin({ top: 6 })
                  .onClick(() => this.openTab(2))
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
                .height(132)
                .padding({ left: 18, right: 140 })
              }
              .width('100%')
              .height(132)
              .borderRadius(16)
              .clip(true)
              .onClick(() => this.openTab(2))
            }

            // 功能宫格：白底圆角卡片
            Grid() {
              ForEach(this.gridItems(), (item: HomeGridItem) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Image(this.gridMedia(item.action))
                      .width(48)
                      .height(48)
                      .objectFit(ImageFit.Contain)
                    Text(I18n.t(item.titleKey, this.lang))
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#111827')
                    Text(I18n.t(item.subKey, this.lang))
                      .fontSize(10)
                      .fontColor('#9CA3AF')
                      .maxLines(1)
                  }
                  .width('100%')
                  .padding({ top: 4, bottom: 4 })
                  .onClick(() => this.onGrid(item.action))
                }
              }, (item: HomeGridItem) => item.action)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(10)
            .columnsGap(0)
            .width('100%')
            .padding({ left: 8, right: 8, top: 14, bottom: 14 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Column({ space: 4 }) {
              this.sectionHeadHot()

              if (this.hotQs.length === 0 && !this.loading) {
                Text(I18n.t('home_hot_empty', this.lang))
                  .fontSize(12)
                  .fontColor('#9CA3AF')
                  .padding({ top: 12, bottom: 8 })
              }

              ForEach(this.hotQs, (q: QuestionItem, index: number) => {
                Row({ space: 10 }) {
                  Text(`${index + 1}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.rankColor(index))
                    .width(24)
                    .height(24)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.rankBg(index))
                    .borderRadius(12)
                  Column({ space: 4 }) {
                    Text(q.title)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#111827')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row({ space: 6 }) {
                      ForEach(this.previewTags(q), (t: string) => {
                        Text(t)
                          .fontSize(10)
                          .fontColor('#6B7280')
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .backgroundColor('#F3F4F6')
                          .borderRadius(4)
                      }, (t: string) => t)
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Row({ space: 2 }) {
                    Text('🔥').fontSize(11)
                    Text(this.formatCount(q.viewCount !== undefined ? q.viewCount : 0))
                      .fontSize(11)
                      .fontColor('#9CA3AF')
                  }
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .onClick(() => this.openQuestion(q))
              }, (q: QuestionItem) => q.id)
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 14, bottom: 8 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            if (this.books.length > 0) {
              Column({ space: 12 }) {
                this.sectionHeadBook()
                Scroll() {
                  Row({ space: 12 }) {
                    ForEach(this.books, (b: BookItem) => {
                      Column({ space: 6 }) {
                        BookCover({ item: b, coverWidth: 88, coverHeight: 118 })
                        Text(mallStr(b.title))
                          .fontSize(12)
                          .fontColor('#111827')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width(88)
                        Text(I18n.tf('book_readers', this.formatCount(mallNum(b.viewCount)), this.lang))
                          .fontSize(10)
                          .fontColor('#9CA3AF')
                          .width(88)
                      }
                      .width(88)
                      .alignItems(HorizontalAlign.Start)
                      .onClick(() => this.openBook(b))
                    }, (b: BookItem) => mallStr(b.id))
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
            }

            if (this.blogEnabled && this.blogs.length > 0) {
              Column({ space: 12 }) {
                this.sectionHeadBlog()
                ForEach(this.blogs, (a: BlogArticle) => {
                  Row({ space: 12 }) {
                    if (this.blogCover(a).length > 0) {
                      Image(this.blogCover(a))
                        .width(72)
                        .height(72)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(10)
                    } else {
                      Image($r('app.media.home_sec_blog'))
                        .width(72)
                        .height(72)
                        .objectFit(ImageFit.Contain)
                        .padding(14)
                        .backgroundColor('#ECFDF5')
                        .borderRadius(10)
                    }
                    Column({ space: 6 }) {
                      Text(mallStr(a.title))
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#111827')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(mallStr(a.summary))
                        .fontSize(11)
                        .fontColor('#9CA3AF')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Row({ space: 10 }) {
                        Text(mallStr(a.authorName).length > 0 ? mallStr(a.authorName) : '码上Offer')
                          .fontSize(11)
                          .fontColor('#6B7280')
                          .layoutWeight(1)
                        Text(`♥ ${mallNum(a.likeCount)}`)
                          .fontSize(11)
                          .fontColor('#9CA3AF')
                        Text(`💬 ${mallNum(a.commentCount)}`)
                          .fontSize(11)
                          .fontColor('#9CA3AF')
                      }
                      .width('100%')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ top: 4, bottom: 4 })
                  .onClick(() => this.openBlog(a))
                }, (a: BlogArticle) => mallStr(a.id))
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 24 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
