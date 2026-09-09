import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { TodayStudyStats, QuestionItem } from '../../common/models/Types';
import { BlogArticle } from '../../common/models/BlogTypes';
import { BookItem } from '../../common/models/BookTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BookCover } from '../../components/BookCover';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { BlogRepository } from '../../data/repository/BlogRepository';
import { BookRepository } from '../../data/repository/BookRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

@Component
export struct StudyPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('blogEnabled') blogEnabled: boolean = true;
  @StorageLink('forumEnabled') forumEnabled: boolean = true;
  @State private stats: TodayStudyStats = {
    questionCount: 0,
    minutes: 0,
    mastered: 0,
    toReview: 0
  };
  @State private hotQs: QuestionItem[] = [];
  @State private blogs: BlogArticle[] = [];
  @State private recent: BookItem = {};
  private qRepo: QuestionRepository = QuestionRepository.getInstance();
  private blogRepo: BlogRepository = BlogRepository.getInstance();
  private bookRepo: BookRepository = BookRepository.getInstance();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.stats = await this.qRepo.getTodayStudyStats();
    } catch (_e) {
      this.stats = { questionCount: 0, minutes: 0, mastered: 0, toReview: 0 };
    }
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.hotQs = await this.qRepo.getHot(ctx);
    } catch (_e) {
      this.hotQs = [];
    }
    if (this.blogEnabled) {
      try {
        const page = await this.blogRepo.articles('recommend', 1, '');
        this.blogs = page.records !== undefined ? page.records : [];
      } catch (_e) {
        this.blogs = [];
      }
    }
    try {
      const home = await this.bookRepo.home();
      this.recent = home.continueReading !== undefined ? home.continueReading : {};
    } catch (_e) {
      this.recent = {};
    }
  }

  private planPct(): number {
    const q = this.stats.questionCount;
    const m = this.stats.mastered;
    if (q <= 0) {
      return this.stats.toReview > 0 ? 20 : 0;
    }
    return Math.min(100, Math.round(m * 100 / Math.max(q, 1)));
  }

  private startStudy(): void {
    if (this.hotQs.length > 0) {
      router.pushUrl({
        url: 'pages/bank/QuestionDetailPage',
        params: { 'id': this.hotQs[0].id }
      });
      return;
    }
    router.pushUrl({ url: 'pages/bank/BankHubPage' });
  }

  private openBank(): void {
    router.pushUrl({ url: 'pages/bank/BankHubPage' });
  }

  private openBlog(): void {
    router.pushUrl({ url: 'pages/blog/BlogHubPage' });
  }

  private openForum(): void {
    router.pushUrl({ url: 'pages/forum/ForumHubPage' });
  }

  private openFav(): void {
    LoginGate.ensure(I18n.t('favorites', this.lang), () => {
      router.pushUrl({ url: 'pages/profile/FavoritesPage' });
    });
  }

  private soon(name: string): void {
    promptAction.showToast({ message: I18n.tf('soon', name, this.lang) });
  }

  private shownBlogs(): BlogArticle[] {
    const out: BlogArticle[] = [];
    const src = this.blogs;
    for (let i = 0; i < src.length && out.length < 2; i++) {
      out.push(src[i]);
    }
    return out;
  }

  private shownQs(): QuestionItem[] {
    const out: QuestionItem[] = [];
    for (let i = 0; i < this.hotQs.length && out.length < 2; i++) {
      out.push(this.hotQs[i]);
    }
    return out;
  }

  private openQuestion(item: QuestionItem): void {
    router.pushUrl({
      url: 'pages/bank/QuestionDetailPage',
      params: { 'id': item.id }
    });
  }

  private openBlogDetail(item: BlogArticle): void {
    router.pushUrl({
      url: 'pages/blog/BlogDetailPage',
      params: { 'articleId': mallStr(item.id) }
    });
  }

  private openRecent(): void {
    const id = mallStr(this.recent.id);
    if (id.length === 0) {
      this.openBank();
      return;
    }
    router.pushUrl({
      url: 'pages/book/BookReaderPage',
      params: { 'id': id }
    });
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Row() {
          Column({ space: 4 }) {
            Text(I18n.t('tab_study', this.lang))
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(I18n.t('study_sub', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('📅')
            .fontSize(22)
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      .linearGradient({
        angle: 180,
        colors: [['#E8F1FF', 0], ['#F4F7FB', 1]]
      })

      Scroll() {
        Column({ space: 14 }) {
          this.planCard()
          this.menuGrid()
          this.hotQuestionBlock()
          if (this.blogEnabled) {
            this.blogBlock()
          }
          if (mallStr(this.recent.id).length > 0) {
            this.recentBlock()
          }
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  planCard() {
    Column({ space: 12 }) {
      Row() {
        Text('📅')
          .fontSize(16)
          .margin({ right: 4 })
        Text(I18n.t('study_plan', this.lang))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(`「${I18n.t('study_quote', this.lang)}」`)
          .fontSize(10)
          .fontColor('#93C5FD')
          .maxLines(1)
          .constraintSize({ maxWidth: 150 })
      }
      .width('100%')
      Row() {
        this.planCell(`${this.stats.questionCount}`, 'study_q')
        this.planCell(`${this.stats.minutes}`, 'study_min_unit')
        this.planCell(`${this.stats.mastered}`, 'study_col')
        this.planCell(`${this.planPct()}%`, 'study_pct')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      Text(I18n.t('study_start', this.lang))
        .fontSize(15)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(42)
        .borderRadius(21)
        .backgroundColor('#2563EB')
        .onClick(() => this.startStudy())
      Text(`「${I18n.t('study_quote2', this.lang)}」`)
        .fontSize(11)
        .fontColor('#93C5FD')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .shadow({ radius: 12, color: '#14000000', offsetY: 4 })
  }

  @Builder
  planCell(value: string, key: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E40AF')
      Text(I18n.t(key, this.lang))
        .fontSize(11)
        .fontColor($r('app.color.text_muted'))
    }
    .layoutWeight(1)
  }

  @Builder
  menuGrid() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        this.menuCard('📚', 'tab_bank', 'study_bank_sub', '#E8F1FF', () => this.openBank())
        if (this.blogEnabled) {
          this.menuCard('📖', 'tab_blog', 'study_blog_sub', '#F3E8FF', () => this.openBlog())
        } else {
          this.menuCard('❌', 'study_wrong', 'study_wrong_sub', '#FEE2E2', () => this.soon(I18n.t('study_wrong', this.lang)))
        }
      }
      .width('100%')
      Row({ space: 10 }) {
        if (this.forumEnabled) {
          this.menuCard('💬', 'tab_forum', 'study_forum_sub', '#E7F8EE', () => this.openForum())
        }
        // else {
        //   this.menuCard('❌', 'study_wrong', 'study_wrong_sub', '#FEE2E2', () => this.soon(I18n.t('study_wrong', this.lang)))
        // }
        this.menuCard('⭐', 'favorites', 'study_fav_sub', '#FFF4E5', () => this.openFav())

        // this.menuCard('❌', 'study_wrong', 'study_wrong_sub', '#FEE2E2', () => this.soon(I18n.t('study_wrong', this.lang)))
      }
      .width('100%')
      // /**/Row({ space: 10 }) {
      //   this.menuCard('⭐', 'favorites', 'study_fav_sub', '#FFF4E5', () => this.openFav())
        // this.menuCard('📊', 'study_log', 'study_log_sub2', '#E7F8EE', () => this.soon(I18n.t('study_log', this.lang)))
      // }
      // .width('100%')
    }
    .width('100%')
  }

  @Builder
  menuCard(icon: string, titleKey: string, subKey: string, bg: string, onTap: () => void) {
    Row({ space: 10 }) {
      Text(icon)
        .fontSize(20)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor(bg)
      Column({ space: 4 }) {
        Text(I18n.t(titleKey, this.lang))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(I18n.t(subKey, this.lang))
          .fontSize(11)
          .fontColor($r('app.color.text_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => onTap())
  }

  @Builder
  hotQuestionBlock() {
    Column({ space: 10 }) {
      Row() {
        Text(I18n.t('study_hot_q', this.lang))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(I18n.t('all_more', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => this.openBank())
      }
      .width('100%')
      if (this.shownQs().length === 0) {
        Text(I18n.t('no_hot', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
      } else {
        Row({ space: 10 }) {
          ForEach(this.shownQs(), (item: QuestionItem) => {
            Column({ space: 8 }) {
              Text(item.title)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text(item.categoryName)
                .fontSize(11)
                .fontColor('#2563EB')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#DBEAFE')
                .borderRadius(8)
            }
            .layoutWeight(1)
            .height(118)
            .alignItems(HorizontalAlign.Start)
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)
            .onClick(() => this.openQuestion(item))
          }, (item: QuestionItem) => item.id)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
  }

  @Builder
  blogBlock() {
    Column({ space: 10 }) {
      Row() {
        Text(I18n.t('study_hot_blog', this.lang))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(I18n.t('all_more', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => this.openBlog())
      }
      .width('100%')
      if (this.shownBlogs().length === 0) {
        Text(I18n.t('blog_empty', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
      } else {
        Row({ space: 10 }) {
          ForEach(this.shownBlogs(), (item: BlogArticle) => {
            Column({ space: 6 }) {
              if (mallStr(item.coverUrl).length > 0) {
                Image(mallStr(item.coverUrl))
                  .width('100%')
                  .height(88)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(10)
              } else {
                Column()
                  .width('100%')
                  .height(88)
                  .borderRadius(10)
                  .backgroundColor('#EEF2FF')
              }
              Text(mallStr(item.title))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .height(36)
              Text(mallStr(item.summary).length > 0 ? mallStr(item.summary) : ' ')
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .height(32)
            }
            .layoutWeight(1)
            .height(186)
            .alignItems(HorizontalAlign.Start)
            .padding(10)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)
            .onClick(() => this.openBlogDetail(item))
          }, (item: BlogArticle) => mallStr(item.id))
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
  }

  @Builder
  recentBlock() {
    Column({ space: 10 }) {
      Row() {
        Text(I18n.t('study_recent', this.lang))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
      }
      .width('100%')
      Row({ space: 12 }) {
        BookCover({ item: this.recent, coverWidth: 48, coverHeight: 64 })
        Column({ space: 6 }) {
          Text(mallStr(this.recent.title))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(I18n.t('tab_book', this.lang))
            .fontSize(10)
            .fontColor('#2563EB')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#DBEAFE')
            .borderRadius(8)
          Row() {
            Column()
              .width(`${Math.max(mallNum(this.recent.percent), 4)}%`)
              .height(6)
              .borderRadius(3)
              .backgroundColor('#2563EB')
          }
          .width('100%')
          .height(6)
          .borderRadius(3)
          .backgroundColor('#E5E7EB')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(14)
      .onClick(() => this.openRecent())
    }
    .width('100%')
  }
}
