import { router } from '@kit.ArkUI';
import { BlogArticle, copyBlogArticle } from '../../common/models/BlogTypes';
import { ForumPost, ForumTab, copyForumPost } from '../../common/models/ForumTypes';
import { mallStr } from '../../common/models/MallTypes';
import { FavoriteItem, FavoriteRepository } from '../../data/repository/FavoriteRepository';
import { BlogRepository } from '../../data/repository/BlogRepository';
import { ForumRepository } from '../../data/repository/ForumRepository';
import { NavBackButton } from '../../components/NavBackButton';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct FavoritesPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private tabId: string = 'question';
  @State private tabs: ForumTab[] = [];
  @State private questions: FavoriteItem[] = [];
  @State private blogs: BlogArticle[] = [];
  @State private posts: ForumPost[] = [];
  @State private loading: boolean = true;
  private qRepo: FavoriteRepository = FavoriteRepository.getInstance();
  private blogRepo: BlogRepository = BlogRepository.getInstance();
  private forumRepo: ForumRepository = ForumRepository.getInstance();
  private pageReady: boolean = false;

  aboutToAppear(): void {
    this.syncTabs();
    this.loadData();
  }

  onPageShow(): void {
    if (!this.pageReady) {
      this.pageReady = true;
      return;
    }
    this.loadData();
  }

  private syncTabs(): void {
    const next: ForumTab[] = [];
    const q: ForumTab = { id: 'question', name: I18n.t('fav_tab_q', this.lang) };
    const blog: ForumTab = { id: 'blog', name: I18n.t('fav_tab_blog', this.lang) };
    const forum: ForumTab = { id: 'forum', name: I18n.t('fav_tab_forum', this.lang) };
    next.push(q);
    next.push(blog);
    next.push(forum);
    this.tabs = next;
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      if (!LoginGate.isLoggedIn()) {
        this.questions = [];
        this.blogs = [];
        this.posts = [];
        return;
      }
      this.questions = await this.loadQuestions();
      this.blogs = await this.loadBlogs();
      this.posts = await this.loadPosts();
    } catch (_e) {
      this.questions = [];
      this.blogs = [];
      this.posts = [];
    } finally {
      this.loading = false;
    }
  }

  private async loadQuestions(): Promise<FavoriteItem[]> {
    try {
      await this.qRepo.sync();
      return await this.qRepo.list();
    } catch (_e) {
      const empty: FavoriteItem[] = [];
      return empty;
    }
  }

  private async loadBlogs(): Promise<BlogArticle[]> {
    try {
      const raw = await this.blogRepo.listFavorites();
      const list: BlogArticle[] = [];
      for (let i = 0; i < raw.length; i++) {
        list.push(copyBlogArticle(raw[i]));
      }
      return list;
    } catch (_e) {
      const empty: BlogArticle[] = [];
      return empty;
    }
  }

  private async loadPosts(): Promise<ForumPost[]> {
    try {
      const raw = await this.forumRepo.listFavorites();
      const list: ForumPost[] = [];
      for (let i = 0; i < raw.length; i++) {
        list.push(copyForumPost(raw[i]));
      }
      return list;
    } catch (_e) {
      const empty: ForumPost[] = [];
      return empty;
    }
  }

  private emptyText(): string {
    if (this.tabId === 'blog') {
      return I18n.t('fav_empty_blog', this.lang);
    }
    if (this.tabId === 'forum') {
      return I18n.t('fav_empty_forum', this.lang);
    }
    return I18n.t('fav_empty_q', this.lang);
  }

  private currentEmpty(): boolean {
    if (this.tabId === 'blog') {
      return this.blogs.length === 0;
    }
    if (this.tabId === 'forum') {
      return this.posts.length === 0;
    }
    return this.questions.length === 0;
  }

  private postTitle(item: ForumPost): string {
    const title = mallStr(item.title);
    if (title.length > 0) {
      return title;
    }
    const summary = mallStr(item.summary);
    if (summary.length > 0) {
      return summary;
    }
    return I18n.t('forum_untitled', this.lang);
  }

  private blogMeta(item: BlogArticle): string {
    const cat = mallStr(item.categoryName);
    const time = mallStr(item.publishTime);
    if (cat.length > 0 && time.length > 0) {
      return `${cat} · ${time}`;
    }
    if (cat.length > 0) {
      return cat;
    }
    return time;
  }

  private postMeta(item: ForumPost): string {
    const cat = mallStr(item.categoryName);
    const time = mallStr(item.createTime);
    if (cat.length > 0 && time.length > 0) {
      return `${cat} · ${time}`;
    }
    if (cat.length > 0) {
      return cat;
    }
    return time;
  }

  private openQuestion(item: FavoriteItem): void {
    router.pushUrl({
      url: 'pages/bank/QuestionDetailPage',
      params: { 'id': item.questionId }
    });
  }

  private openBlog(item: BlogArticle): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/blog/BlogDetailPage',
      params: { 'articleId': id }
    });
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

  build() {
    Column() {
      Row() {
        NavBackButton({ onBack: () => router.back() })
        Text(I18n.t('favorites', this.lang))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Row({ space: 24 }) {
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
          .onClick(() => {
            this.tabId = tab.id;
          })
        }, (tab: ForumTab) => tab.id)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!LoginGate.isLoggedIn()) {
        Column({ space: 12 }) {
          Text(I18n.t('fav_login', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
          Button(I18n.t('go_login', this.lang))
            .width(140)
            .height(40)
            .backgroundColor('#2563EB')
            .onClick(() => LoginGate.goLogin())
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.currentEmpty()) {
        Column() {
          Text(this.emptyText()).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.tabId === 'blog') {
        List({ space: 10 }) {
          ForEach(this.blogs, (item: BlogArticle) => {
            ListItem() {
              Column() {
                this.favCard(mallStr(item.title), this.blogMeta(item))
              }
              .onClick(() => this.openBlog(item))
            }
          }, (item: BlogArticle) => `b-${mallStr(item.id)}`)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      } else if (this.tabId === 'forum') {
        List({ space: 10 }) {
          ForEach(this.posts, (item: ForumPost) => {
            ListItem() {
              Column() {
                this.favCard(this.postTitle(item), this.postMeta(item))
              }
              .onClick(() => this.openPost(item))
            }
          }, (item: ForumPost) => `f-${mallStr(item.id)}`)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      } else {
        List({ space: 10 }) {
          ForEach(this.questions, (item: FavoriteItem) => {
            ListItem() {
              Column() {
                this.favCard(
                  item.questionTitle.length > 0 ? item.questionTitle : I18n.t('unnamed_q', this.lang),
                  item.createTime
                )
              }
              .onClick(() => this.openQuestion(item))
            }
          }, (item: FavoriteItem) => `q-${item.id}`)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  favCard(title: string, meta: string) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (meta.length > 0) {
          Text(meta)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(18).fontColor('#D1D5DB')
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }
}
