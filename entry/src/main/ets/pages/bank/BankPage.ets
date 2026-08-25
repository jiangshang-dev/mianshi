import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category } from '../../common/models/Types';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct BankPage {
  @State private categories: Category[] = [];
  @State private loading: boolean = true;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.categories = await this.repo.getCategories(ctx);
    } catch (_e) {
      this.categories = [];
    } finally {
      this.loading = false;
    }
  }

  private openCategory(cat: Category): void {
    router.pushUrl({
      url: 'pages/bank/QuestionListPage',
      params: {
        'categoryId': cat.id,
        'title': cat.name,
        'source': cat.source
      }
    });
  }

  build() {
    if (this.loading) {
      Column() {
        LoadingProgress().width(36).height(36)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F3F4F6')
    } else {
      Scroll() {
        Column({ space: 10 }) {
          Row() {
            Text('题库')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .layoutWeight(1)
            Text('全部分类 ›')
              .fontSize(13)
              .fontColor('#2563EB')
              .onClick(() => {
                router.pushUrl({ url: 'pages/bank/CategoryAllPage' });
              })
          }
          .width('100%')

          Text('数据来自后端服务接口')
            .fontSize(12)
            .fontColor('#9CA3AF')
            .width('100%')

          this.categoryList(this.categories)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F3F4F6')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
  }

  @Builder
  categoryList(list: Category[]) {
    Column({ space: 10 }) {
      ForEach(list, (cat: Category) => {
        Row() {
          Text(cat.icon)
            .fontSize(26)
            .margin({ right: 12 })
          Column({ space: 4 }) {
            Text(cat.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Text(cat.articleCount > 0 ?
              `${cat.articleCount} 道题 · ${cat.children.length} 个子类` :
              `${cat.children.length} 个专题`)
              .fontSize(12)
              .fontColor('#6B7280')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('›').fontSize(20).fontColor('#D1D5DB')
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .onClick(() => this.openCategory(cat))
      }, (cat: Category) => cat.id)
    }
    .width('100%')
  }
}
