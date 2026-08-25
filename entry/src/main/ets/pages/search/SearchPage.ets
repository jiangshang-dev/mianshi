import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { QuestionItem } from '../../common/models/Types';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct SearchPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private keyword: string = '';
  @State private results: QuestionItem[] = [];
  @State private searching: boolean = false;
  @State private searched: boolean = false;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  private async doSearch(): Promise<void> {
    if (this.keyword.trim().length === 0) {
      this.results = [];
      this.searched = false;
      return;
    }
    this.searching = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.results = await this.repo.search(ctx, this.keyword.trim());
      this.searched = true;
    } catch (_e) {
      this.results = [];
      this.searched = true;
    } finally {
      this.searching = false;
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(28)
          .onClick(() => router.back())
        TextInput({ placeholder: I18n.t('search_ph', this.lang), text: this.keyword })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.White)
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
          .fontColor('#2563EB')
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
        Column() {
          Text(this.searched ? I18n.t('search_empty', this.lang) : I18n.t('search_idle', this.lang))
            .fontSize(14)
            .fontColor('#9CA3AF')
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 32, right: 32 })
        .justifyContent(FlexAlign.Center)
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
    .backgroundColor('#F3F4F6')
  }
}
