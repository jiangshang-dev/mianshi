import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category, CategoryGroupSection } from '../../common/models/Types';
import { CategoryCard } from '../../components/CategoryCard';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct CategoryAllPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private groups: CategoryGroupSection[] = [];
  @State private loading: boolean = true;

  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.groups = await this.repo.getCategoryGroups(ctx);
    } catch (_e) {
      this.groups = [];
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

  private categoryCount(): number {
    let n = 0;
    this.groups.forEach((g: CategoryGroupSection) => {
      n += g.items.length;
    });
    return n;
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('all_cats_title', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(I18n.tf('count_unit', `${this.categoryCount()}`, this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
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
      } else if (this.groups.length === 0) {
        Column({ space: 8 }) {
          Text(I18n.t('no_cat_short', this.lang)).fontSize(16).fontColor($r('app.color.text_muted'))
          Text(I18n.t('no_cat_hint', this.lang)).fontSize(13).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            ForEach(this.groups, (g: CategoryGroupSection) => {
              Column({ space: 10 }) {
                Text(I18n.sectionTitle(g.name, g.title, this.lang))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')

                Grid() {
                  ForEach(g.items, (c: Category) => {
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
            }, (g: CategoryGroupSection) => g.name)
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
    .backgroundColor($r('app.color.page_bg'))
  }
}
