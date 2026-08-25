import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { QuestionItem } from '../../common/models/Types';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Entry
@Component
struct SearchPage {
  @State private keyword: string = '';
  @State private results: QuestionItem[] = [];
  @State private searching: boolean = false;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  private async doSearch(): Promise<void> {
    if (this.keyword.trim().length === 0) {
      this.results = [];
      return;
    }
    this.searching = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.results = await this.repo.search(ctx, this.keyword.trim());
    } catch (_e) {
      this.results = [];
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
        TextInput({ placeholder: '搜题目 / 知识点 / 分类', text: this.keyword })
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
        Text('搜索')
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
