import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { GlobalSearchHit, GlobalSearchResult } from '../../common/models/SearchTypes';
import { mallStr } from '../../common/models/MallTypes';
import { SearchHistoryStore } from '../../common/search/SearchHistoryStore';
import { GlobalSearchRepository } from '../../data/repository/GlobalSearchRepository';
import { NavBackButton } from '../../components/NavBackButton';

interface SearchTab {
  id: string;
  name: string;
}

const HOT_WORDS: string[] = [
  'HashMap',
  'JVM',
  'Redis',
  'Spring',
  '微服务',
  '线程池',
  'MySQL',
  'Kafka'
];

@Entry
@Component
struct SearchPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private keyword: string = '';
  @State private tabId: string = 'all';
  @State private tabs: SearchTab[] = [];
  @State private result: GlobalSearchResult = {
    all: [],
    questions: [],
    books: [],
    blogs: [],
    forums: []
  };
  @State private searching: boolean = false;
  @State private searched: boolean = false;
  @State private history: string[] = [];
  private repo: GlobalSearchRepository = GlobalSearchRepository.getInstance();

  aboutToAppear(): void {
    this.rebuildTabs();
    this.loadHistory();
  }

  private rebuildTabs(): void {
    this.tabs = [
      { id: 'all', name: I18n.t('search_tab_all', this.lang) },
      { id: 'question', name: I18n.t('search_tab_q', this.lang) },
      { id: 'book', name: I18n.t('search_tab_book', this.lang) },
      { id: 'blog', name: I18n.t('search_tab_blog', this.lang) },
      { id: 'forum', name: I18n.t('search_tab_forum', this.lang) }
    ];
  }

  private async loadHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.load(ctx);
    } catch (_e) {
      this.history = [];
    }
  }

  private async doSearch(): Promise<void> {
    const word = this.keyword.trim();
    if (word.length === 0) {
      this.result = { all: [], questions: [], books: [], blogs: [], forums: [] };
      this.searched = false;
      return;
    }
    this.searching = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.add(ctx, word);
      this.result = await this.repo.search(word);
      this.searched = true;
    } catch (_e) {
      this.result = { all: [], questions: [], books: [], blogs: [], forums: [] };
      this.searched = true;
    } finally {
      this.searching = false;
    }
  }

  private async searchWord(word: string): Promise<void> {
    this.keyword = word;
    await this.doSearch();
  }

  private async clearHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await SearchHistoryStore.clear(ctx);
    } catch (_e) {
    }
    this.history = [];
  }

  private shown(): GlobalSearchHit[] {
    return GlobalSearchRepository.listOf(this.result, this.tabId);
  }

  private openHit(item: GlobalSearchHit): void {
    const id = mallStr(item.id);
    const type = mallStr(item.type);
    if (id.length === 0) {
      return;
    }
    if (type === 'book') {
      router.pushUrl({ url: 'pages/book/BookReaderPage', params: { 'id': id } });
      return;
    }
    if (type === 'blog') {
      router.pushUrl({ url: 'pages/blog/BlogDetailPage', params: { 'articleId': id } });
      return;
    }
    if (type === 'forum') {
      router.pushUrl({ url: 'pages/forum/ForumDetailPage', params: { 'postId': id } });
      return;
    }
    router.pushUrl({ url: 'pages/bank/QuestionDetailPage', params: { 'id': id } });
  }

  private typeColor(type: string): string {
    if (type === 'book') {
      return '#2563EB';
    }
    if (type === 'blog') {
      return '#7C3AED';
    }
    if (type === 'forum') {
      return '#059669';
    }
    return '#D97706';
  }

  private typeBg(type: string): string {
    if (type === 'book') {
      return '#DBEAFE';
    }
    if (type === 'blog') {
      return '#EDE9FE';
    }
    if (type === 'forum') {
      return '#D1FAE5';
    }
    return '#FEF3C7';
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton({ onBack: () => router.back() })
        TextInput({ placeholder: I18n.t('search_ph', this.lang), text: this.keyword })
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
      .padding({ left: 12, right: 16, top: 12, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      if (this.searched || this.searching) {
        Row({ space: 16 }) {
          ForEach(this.tabs, (tab: SearchTab) => {
            Column({ space: 4 }) {
              Text(tab.name)
                .fontSize(14)
                .fontWeight(this.tabId === tab.id ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(this.tabId === tab.id ? $r('app.color.accent') : $r('app.color.text_secondary'))
              Row()
                .width(18)
                .height(3)
                .borderRadius(2)
                .backgroundColor(this.tabId === tab.id ? $r('app.color.accent') : Color.Transparent)
            }
            .onClick(() => {
              this.tabId = tab.id;
            })
          }, (tab: SearchTab) => tab.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.searching) {
        Column() {
          LoadingProgress().width(36).height(36)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (!this.searched) {
        Scroll() {
          Column({ space: 16 }) {
            if (this.history.length > 0) {
              this.wordSection(I18n.t('search_history', this.lang), this.history, true)
            }
            this.wordSection(I18n.t('hot_search', this.lang), HOT_WORDS, false)
            Text(I18n.t('search_idle', this.lang))
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
      } else if (this.shown().length === 0) {
        Column() {
          Text(I18n.t('search_empty_all', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.shown(), (item: GlobalSearchHit) => {
            ListItem() {
              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Text(mallStr(item.typeLabel).length > 0 ? mallStr(item.typeLabel) : mallStr(item.type))
                    .fontSize(11)
                    .fontColor(this.typeColor(mallStr(item.type)))
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor(this.typeBg(mallStr(item.type)))
                    .borderRadius(8)
                  if (mallStr(item.categoryName).length > 0) {
                    Text(mallStr(item.categoryName))
                      .fontSize(11)
                      .fontColor($r('app.color.text_muted'))
                  }
                }
                .width('100%')
                Text(mallStr(item.title))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .textAlign(TextAlign.Start)
                if (mallStr(item.summary).length > 0) {
                  Text(mallStr(item.summary))
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
                if (mallStr(item.authorName).length > 0) {
                  Text(mallStr(item.authorName))
                    .fontSize(11)
                    .fontColor($r('app.color.text_muted'))
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .onClick(() => this.openHit(item))
            }
          }, (item: GlobalSearchHit) => `${mallStr(item.type)}-${mallStr(item.id)}`)
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
  wordSection(title: string, words: string[], showClear: boolean) {
    Column({ space: 8 }) {
      Row() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        if (showClear) {
          Text(I18n.t('clear_history', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .onClick(() => {
              this.clearHistory();
            })
        }
      }
      .width('100%')
      Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        ForEach(words, (w: string) => {
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
}
