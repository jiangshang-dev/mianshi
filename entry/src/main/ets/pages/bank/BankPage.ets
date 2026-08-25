import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category } from '../../common/models/Types';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct BankPage {
  @State private localCategories: Category[] = [];
  @State private remoteCategories: Category[] = [];
  @State private loading: boolean = true;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const all = await this.repo.getCategories(ctx);
      this.localCategories = all.filter((c: Category) => c.source === 'local_md');
      this.remoteCategories = all.filter((c: Category) => c.source === 'remote_api');
    } catch (_e) {
      this.localCategories = [];
      this.remoteCategories = [];
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
          Text('题库')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .width('100%')

          this.sectionTitle('本地 Markdown 题库', '来自 rawfile/docs，离线可用')
          this.categoryList(this.localCategories)

          this.sectionTitle('远程 API 题库', '后端接口 / Mock 降级')
          this.categoryList(this.remoteCategories)
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
  sectionTitle(title: string, subtitle: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .width('100%')
      Text(subtitle)
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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
            Text(cat.source === 'local_md' ?
              `${cat.articleCount} 篇文章 · ${cat.children.length} 个子类` :
              `${cat.children.length} 个专题 · 远程拉取`)
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
