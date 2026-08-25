import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category } from '../../common/models/Types';
import { CategoryGroupUtil } from '../../common/utils/CategoryGroupUtil';
import { CategoryCard } from '../../components/CategoryCard';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct CategoryAllPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private categories: Category[] = [];
  @State private loading: boolean = true;
  @State private groupNames: string[] = [];

  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.categories = await this.repo.getCategories(ctx);
      const groups: string[] = [];
      this.categories.forEach((c: Category) => {
        const g = CategoryGroupUtil.normalize(c.group);
        if (!groups.includes(g)) {
          groups.push(g);
        }
      });
      this.groupNames = CategoryGroupUtil.sortGroupNames(groups);
    } catch (_e) {
      this.categories = [];
      this.groupNames = [];
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

  private displayList(group: string): Category[] {
    return CategoryGroupUtil.browseItems(this.categories, group);
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('all_cats_title', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(I18n.tf('count_unit', `${this.categories.length}`, this.lang))
          .fontSize(13)
          .fontColor('#6B7280')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.categories.length === 0) {
        Column({ space: 8 }) {
          Text(I18n.t('no_cat_short', this.lang)).fontSize(16).fontColor('#6B7280')
          Text(I18n.t('no_cat_hint', this.lang)).fontSize(13).fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            ForEach(this.groupNames, (group: string) => {
              Column({ space: 10 }) {
                Text(I18n.groupName(group, this.lang))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                  .width('100%')

                Grid() {
                  ForEach(this.displayList(group), (c: Category) => {
                    GridItem() {
                      CategoryCard({
                        category: c,
                        onCardClick: (cat: Category) => {
                          this.openCategory(cat);
                        }
                      })
                    }
                  }, (c: Category) => c.id)
                }
                .columnsTemplate('1fr 1fr 1fr 1fr')
                .columnsGap(10)
                .rowsGap(10)
                .width('100%')
              }
              .width('100%')
            }, (group: string) => group)
          }
          .padding({ left: 16, right: 16, bottom: 24 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
