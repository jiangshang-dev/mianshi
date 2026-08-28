import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { QuestionItem } from '../../common/models/Types';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { SearchHistoryStore } from '../../common/search/SearchHistoryStore';
import { I18n } from '../../common/i18n/I18n';

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
  @State private results: QuestionItem[] = [];
  @State private searching: boolean = false;
  @State private searched: boolean = false;
  @State private history: string[] = [];
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadHistory();
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
      this.results = [];
      this.searched = false;
      return;
    }
    this.searching = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.history = await SearchHistoryStore.add(ctx, word);
      this.results = await this.repo.search(ctx, word);
      this.searched = true;
    } catch (_e) {
      this.results = [];
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

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
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
      .padding(16)

      if (this.searching) {
        Column() {
          LoadingProgress().width(36).height(36)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.results.length === 0) {
        Scroll() {
          Column({ space: 16 }) {
            if (this.history.length > 0) {
              this.wordSection(I18n.t('search_history', this.lang), this.history, true)
            }
            this.wordSection(I18n.t('hot_search', this.lang), HOT_WORDS, false)
            Text(this.searched ? I18n.t('search_empty', this.lang) : I18n.t('search_idle', this.lang))
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
          ForEach(this.results, (item: QuestionItem) => {
            ListItem() {
              QuestionListItem({
                item: item,
                onItemClick: (q: QuestionItem) => {
                  router.pushUrl({
                    url: 'pages/bank/QuestionDetailPage',
                    params: { 'id': q.id }
                  });
                }
              })
            }
          }, (item: QuestionItem) => item.id)
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
