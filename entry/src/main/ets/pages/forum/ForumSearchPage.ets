import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { mallBool } from '../../common/models/BlogTypes';
import { ForumPost } from '../../common/models/ForumTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { FORUM_SEARCH_HISTORY, SearchHistoryStore } from '../../common/search/SearchHistoryStore';
import { ForumUi } from '../../common/utils/ForumUi';
import { ForumRepository } from '../../data/repository/ForumRepository';

@Entry
@Component
struct ForumSearchPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private keyword: string = '';
  @State private results: ForumPost[] = [];
  @State private searching: boolean = false;
  @State private searched: boolean = false;
  @State private history: string[] = [];
  @State private pageNo: number = 1;
  @State private finished: boolean = false;
  @State private loadingMore: boolean = false;
  private repo: ForumRepository = ForumRepository.getInstance();

  aboutToAppear(): void {
    this.loadHistory();
  }

  private async loadHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.load(ctx, FORUM_SEARCH_HISTORY);
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
      this.history = await SearchHistoryStore.add(ctx, word, FORUM_SEARCH_HISTORY);
      const page = await this.repo.posts('all', 1, 'latest', word);
      const records = page.records !== undefined ? page.records : [];
      this.results = records;
      this.finished = records.length < 20;
      this.searched = true;
    } catch (err) {
      this.results = [];
      this.searched = true;
      promptAction.showToast({
        message: err instanceof Error ? err.message : I18n.t('forum_load_fail', this.lang)
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
      const page = await this.repo.posts('all', nextPage, 'latest', word);
      const records = page.records !== undefined ? page.records : [];
      const next: ForumPost[] = [];
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
      await SearchHistoryStore.clear(ctx, FORUM_SEARCH_HISTORY);
    } catch (_e) {
    }
    this.history = [];
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

  private metaLine(item: ForumPost): string {
    const time = ForumUi.relativeTime(mallStr(item.createTime), this.lang);
    const cat = mallStr(item.categoryName);
    if (cat.length === 0) {
      return time;
    }
    return `${time} · ${cat}`;
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        TextInput({ placeholder: I18n.t('forum_search_ph', this.lang), text: this.keyword })
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
            Text(this.searched ? I18n.t('forum_search_empty', this.lang) : I18n.t('forum_search_idle', this.lang))
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
          ForEach(this.results, (item: ForumPost) => {
            ListItem() {
              this.postCard(item)
            }
          }, (item: ForumPost) => mallStr(item.id))
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
  postCard(item: ForumPost) {
    Column({ space: 8 }) {
      Row() {
        if (mallStr(item.avatar).length > 0) {
          Image(mallStr(item.avatar))
            .width(32)
            .height(32)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .flexShrink(0)
        } else {
          Column() {
            Text(ForumUi.nickInitial(mallStr(item.nickname)))
              .fontSize(13)
              .fontColor('#FFFFFF')
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(ForumUi.avatarColor(mallStr(item.nickname)))
          .flexShrink(0)
        }
        Column({ space: 2 }) {
          Text(mallStr(item.nickname))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
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
            .fontColor(ForumUi.catTone(mallStr(item.categoryName)).fg)
            .backgroundColor(ForumUi.catTone(mallStr(item.categoryName)).bg)
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
      if (mallBool(item.rejected) || mallBool(item.pending)) {
        Text(mallStr(item.rejectHint).length > 0 ? mallStr(item.rejectHint) :
          (mallBool(item.pending) ? I18n.t('forum_pending', this.lang) : I18n.t('forum_rejected', this.lang)))
          .fontSize(12)
          .fontColor('#B45309')
          .width('100%')
      }
      if (this.cardSummary(item).length > 0) {
        Text(this.cardSummary(item))
          .fontSize(13)
          .fontColor('#6B7280')
          .maxLines(2)
          .width('100%')
      }
      if (mallStr(item.coverUrl).length > 0) {
        Image(mallStr(item.coverUrl))
          .width('100%')
          .height(140)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      }
      Row({ space: 12 }) {
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
          Image($r('app.media.ic_forum_comment'))
            .width(12)
            .height(12)
            .fillColor('#9CA3AF')
          Text(ForumUi.formatCount(mallNum(item.replyCount)))
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
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => this.openPost(item))
  }
}
