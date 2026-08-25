import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category } from '../../common/models/Types';
import { CategoryGroupUtil } from '../../common/utils/CategoryGroupUtil';
import { CategoryIcon } from '../../components/CategoryIcon';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct BankPage {
  @State private skills: Category[] = [];
  @State private companies: Category[] = [];
  @State private specials: Category[] = [];
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
      this.skills = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.SKILL);
      this.companies = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.COMPANY);
      this.specials = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.SPECIAL);
    } catch (_e) {
      this.skills = [];
      this.companies = [];
      this.specials = [];
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

  private isEmpty(): boolean {
    return this.skills.length === 0 && this.companies.length === 0 && this.specials.length === 0;
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
        Column({ space: 16 }) {
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

          if (this.isEmpty()) {
            Text('未拉到分类，请确认后端已启动且手机与电脑在同一局域网')
              .fontSize(13)
              .fontColor('#9CA3AF')
              .margin({ top: 40 })
              .width('100%')
          } else {
            this.groupBlock('技能', this.skills)
            this.groupBlock('公司题库', this.companies)
            this.groupBlock('专项', this.specials)
          }
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
  groupBlock(title: string, list: Category[]) {
    if (list.length === 0) {
      Column().width(0).height(0)
    } else {
      Column({ space: 10 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#374151')
          .width('100%')
        ForEach(list, (cat: Category) => {
          Row() {
            CategoryIcon({ icon: cat.icon, iconSize: 26 })
              .margin({ right: 12 })
            Column({ space: 4 }) {
              Text(cat.name)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')
              Text(cat.articleCount > 0 ?
                `${cat.articleCount} 道题` :
                (cat.children.length > 0 ? `${cat.children.length} 个专题` : '题库'))
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
}
