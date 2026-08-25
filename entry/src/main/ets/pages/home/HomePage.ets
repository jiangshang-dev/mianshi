import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppConfig } from '../../common/constants/AppConfig';
import { Category, QuestionItem, TodayStudyStats } from '../../common/models/Types';
import { CategoryCard } from '../../components/CategoryCard';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct HomePage {
  @State private categories: Category[] = [];
  @State private hotList: QuestionItem[] = [];
  @State private stats: TodayStudyStats = {
    questionCount: 0,
    minutes: 0,
    mastered: 0,
    toReview: 0
  };
  @State private loading: boolean = true;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await this.repo.init(ctx);
      this.categories = (await this.repo.getCategories(ctx)).slice(0, 8);
      this.hotList = await this.repo.getHot(ctx);
      this.stats = this.repo.getTodayStudyStats();
    } catch (_e) {
      this.categories = [];
      this.hotList = [];
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text('你好，面试选手')
              .fontSize(14)
              .fontColor('#E0E7FF')
            Text(AppConfig.APP_NAME)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
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

        Row() {
          Text('搜面试题 / 知识点 / 技术方向')
            .fontSize(14)
            .fontColor('#94A3B8')
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF22')
        .borderRadius(12)
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
          Text('正在加载本地题库…').fontSize(13).fontColor('#6B7280').margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 12 }) {
              Row() {
                Text('今日学习')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111827')
                Blank()
                Text('继续学习 ›')
                  .fontSize(13)
                  .fontColor('#2563EB')
                  .onClick(() => {
                    if (this.hotList.length > 0) {
                      router.pushUrl({
                        url: 'pages/bank/QuestionDetailPage',
                        params: { 'id': this.hotList[0].id }
                      });
                    }
                  })
              }
              .width('100%')

              Row() {
                this.statCell(`${this.stats.questionCount}`, '道题')
                this.statCell(`${this.stats.minutes}`, '分钟')
                this.statCell(`${this.stats.mastered}`, '掌握')
                this.statCell(`${this.stats.toReview}`, '待复习')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)

            Column({ space: 12 }) {
              Row() {
                Text('技术方向')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text('全部 ›')
                  .fontSize(13)
                  .fontColor('#2563EB')
              }
              .width('100%')

              Grid() {
                ForEach(this.categories, (c: Category) => {
                  GridItem() {
                    CategoryCard({
                      category: c,
                      onCardClick: (cat: Category) => {
                        router.pushUrl({
                          url: 'pages/bank/QuestionListPage',
                          params: {
                            'categoryId': cat.id,
                            'title': cat.name,
                            'source': cat.source
                          }
                        });
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

            Column({ space: 10 }) {
              Text('热门推荐')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

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
            .width('100%')
            .padding({ bottom: 24 })
          }
          .padding({ left: 16, right: 16, top: 16 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  statCell(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E40AF')
      Text(label)
        .fontSize(12)
        .fontColor('#6B7280')
    }
    .layoutWeight(1)
  }
}
