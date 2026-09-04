import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category, CategoryGroupSection, QuestionItem, TodayStudyStats } from '../../common/models/Types';
import { CategoryTagSection } from '../../components/CategoryTagSection';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

@Component
export struct HomePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private groups: CategoryGroupSection[] = [];
  @State private hotList: QuestionItem[] = [];
  @State private stats: TodayStudyStats = {
    questionCount: 0,
    minutes: 0,
    mastered: 0,
    toReview: 0
  };
  @State private loading: boolean = true;
  @State private refreshing: boolean = false;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData(false);
  }

  private async loadData(silent: boolean): Promise<void> {
    if (!silent) {
      this.loading = true;
    }
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await this.repo.init(ctx);
      this.groups = await this.repo.getCategoryGroups(ctx);
      this.hotList = await this.repo.getHot(ctx);
      this.stats = await this.repo.getTodayStudyStats();
    } catch (_e) {
      this.groups = [];
      this.hotList = [];
      this.stats = { questionCount: 0, minutes: 0, mastered: 0, toReview: 0 };
    } finally {
      this.loading = false;
    }
  }

  private pullRefresh(): void {
    this.refreshing = true;
    this.loadData(true).then(() => {
      this.refreshing = false;
    }).catch(() => {
      this.refreshing = false;
    });
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text(I18n.t('hello_candidate', this.lang))
              .fontSize(14)
              .fontColor('#E0E7FF')
            Text(I18n.t('app_name', this.lang))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_on_color'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('🔍')
            .fontSize(22)
            .padding(8)
            .onClick(() => {
              router.pushUrl({ url: 'pages/search/SearchPage' });
            })
        }
        .width('100%')

        Row({ space: 8 }) {
          Text('🔍')
            .fontSize(14)
          Text(I18n.t('search_home', this.lang))
            .fontSize(14)
            .fontColor($r('app.color.header_search_text'))
            .layoutWeight(1)
        }
        .width('100%')
        .height(40)
        .padding({ left: 14, right: 14 })
        .backgroundColor($r('app.color.header_search_bg'))
        .borderRadius(20)
        .onClick(() => {
          router.pushUrl({ url: 'pages/search/SearchPage' });
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .linearGradient({
        angle: 135,
        colors: [['#1E3A8A', 0], ['#2563EB', 0.55], ['#0EA5E9', 1]]
      })

      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2563EB')
          Text(I18n.t('loading', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.refreshing }) {
          List({ space: 16 }) {
            ListItem() {
              this.todayCard()
            }
            ListItem() {
              Column({ space: 16 }) {
                if (this.groups.length === 0) {
                  Text(I18n.t('no_cat_home', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.text_muted'))
                    .width('100%')
                }
                ForEach(this.groups, (g: CategoryGroupSection) => {
                  CategoryTagSection({
                    title: I18n.sectionTitle(g.name, g.title, this.lang),
                    items: g.items,
                    textColor: g.textColor,
                    chipColor: g.bgColor,
                    onTagClick: (cat: Category) => this.openCategory(cat)
                  })
                }, (g: CategoryGroupSection) => g.name)
                Text(I18n.t('all_more', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.accent'))
                  .width('100%')
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/bank/CategoryAllPage' });
                  })
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
            }
            ListItem() {
              Column({ space: 10 }) {
                Text(I18n.t('hot_recommend', this.lang))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                if (this.hotList.length === 0) {
                  Text(I18n.t('no_hot', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.text_muted'))
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                } else {
                  ForEach(this.hotList, (item: QuestionItem) => {
                    QuestionListItem({
                      item: item,
                      onItemClick: (q: QuestionItem) => {
                        router.pushUrl({
                          url: 'pages/bank/QuestionDetailPage',
                          params: { 'id': q.id }
                        });
                      }
                    })
                  }, (item: QuestionItem) => item.id)
                }
              }
              .width('100%')
              .padding({ bottom: 24 })
            }
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
        }
        .layoutWeight(1)
        .width('100%')
        .onRefreshing(() => this.pullRefresh())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private continueStudy(): void {
    if (this.hotList.length > 0) {
      router.pushUrl({
        url: 'pages/bank/QuestionDetailPage',
        params: { 'id': this.hotList[0].id }
      });
      return;
    }
    AppStorage.setOrCreate('mainTabIndex', 1);
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

  @Builder
  todayCard() {
    Column({ space: 12 }) {
      Row() {
        Text(I18n.t('today_study', this.lang))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(I18n.t('continue_study', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => this.continueStudy())
      }
      .width('100%')

      Row() {
        this.statCell(`${this.stats.questionCount}`, 'stat_q')
        this.statCell(`${this.stats.minutes}`, 'stat_min')
        this.statCell(`${this.stats.mastered}`, 'stat_master')
        this.statCell(`${this.stats.toReview}`, 'stat_review')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  @Builder
  statCell(value: string, labelKey: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.stat_value'))
      Text(I18n.t(labelKey, this.lang))
        .fontSize(12)
        .fontColor($r('app.color.text_muted'))
    }
    .layoutWeight(1)
  }
}
