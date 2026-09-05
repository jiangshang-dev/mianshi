import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BlogArticle, mallBool } from '../../common/models/BlogTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BLOG_SEARCH_HISTORY, SearchHistoryStore } from '../../common/search/SearchHistoryStore';
import { ForumUi } from '../../common/utils/ForumUi';
import { BlogRepository } from '../../data/repository/BlogRepository';

@Entry
@Component
struct BlogSearchPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private keyword: string = '';
  @State private results: BlogArticle[] = [];
  @State private searching: boolean = false;
  @State private searched: boolean = false;
  @State private history: string[] = [];
  @State private pageNo: number = 1;
  @State private finished: boolean = false;
  @State private loadingMore: boolean = false;
  private repo: BlogRepository = BlogRepository.getInstance();

  aboutToAppear(): void {
    this.loadHistory();
  }

  private async loadHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.load(ctx, BLOG_SEARCH_HISTORY);
    } catch (_e) {
      this.history = [];
    }
  }

  private async doSearch(): Promise<void> {
    const word = this.keyword.trim();
    if (word.length === 0) {
      this.results = [];
      this.searched = false;
      this.finished = false;
      return;
    }
    this.searching = true;
    this.pageNo = 1;
    this.finished = false;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.add(ctx, word, BLOG_SEARCH_HISTORY);
      const page = await this.repo.articles('', 1, word);
      const records = page.records !== undefined ? page.records : [];
      this.results = records;
      this.finished = records.length < 20;
      this.searched = true;
    } catch (err) {
      this.results = [];
      this.searched = true;
      promptAction.showToast({
        message: err instanceof Error ? err.message : I18n.t('blog_load_fail', this.lang)
      });
    } finally {
      this.searching = false;
    }
  }

  private async searchWord(word: string): Promise<void> {
    this.keyword = word;
    await this.doSearch();
  }

  private async loadMore(): Promise<void> {
    if (this.finished || this.loadingMore || this.searching || !this.searched) {
      return;
    }
    const word = this.keyword.trim();
    if (word.length === 0) {
      return;
    }
    this.loadingMore = true;
    const nextPage = this.pageNo + 1;
    try {
      const page = await this.repo.articles('', nextPage, word);
      const records = page.records !== undefined ? page.records : [];
      const next: BlogArticle[] = [];
      for (let i = 0; i < this.results.length; i++) {
        next.push(this.results[i]);
      }
      for (let i = 0; i < records.length; i++) {
        next.push(records[i]);
      }
      this.results = next;
      this.pageNo = nextPage;
      this.finished = records.length < 20;
    } catch (_e) {
    } finally {
      this.loadingMore = false;
    }
  }

  private async clearHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await SearchHistoryStore.clear(ctx, BLOG_SEARCH_HISTORY);
    } catch (_e) {
    }
    this.history = [];
  }

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

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        TextInput({ placeholder: I18n.t('blog_search_ph', this.lang), text: this.keyword })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.input_bg'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_muted'))
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
          .onChange((v: string) => {
            this.keyword = v;
          })
          .onSubmit(() => {
            this.doSearch();
          })
        Text(I18n.t('search', this.lang))
          .fontSize(14)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.doSearch();
          })
      }
      .width('100%')
      .padding(16)

      if (this.searching) {
        Column() {
          LoadingProgress().width(36).height(36)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.results.length === 0) {
        Scroll() {
          Column({ space: 16 }) {
            if (this.history.length > 0) {
              this.historySection()
            }
            Text(this.searched ? I18n.t('blog_search_empty', this.lang) : I18n.t('blog_search_idle', this.lang))
              .fontSize(13)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
          .alignItems(HorizontalAlign.Start)
        }
        .align(Alignment.TopStart)
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      } else {
        List({ space: 10 }) {
          ForEach(this.results, (item: BlogArticle) => {
            ListItem() {
              this.articleCard(item)
            }
          }, (item: BlogArticle) => mallStr(item.id))
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 16 })
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          this.loadMore();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  historySection() {
    Column({ space: 8 }) {
      Row() {
        Text(I18n.t('search_history', this.lang))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(I18n.t('clear_history', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .onClick(() => {
            this.clearHistory();
          })
      }
      .width('100%')
      Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        ForEach(this.history, (w: string) => {
          Text(w)
            .fontSize(13)
            .fontColor($r('app.color.chip_idle_text'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .backgroundColor($r('app.color.chip_idle_bg'))
            .borderRadius(16)
            .onClick(() => {
              this.searchWord(w);
            })
        }, (w: string) => w)
      }
      .width('100%')
      .flexShrink(0)
    }
    .width('100%')
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
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
