import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppConfig } from '../../common/constants/AppConfig';
import { Category, QuestionItem, TodayStudyStats } from '../../common/models/Types';
import { CategoryGroupUtil } from '../../common/utils/CategoryGroupUtil';
import { CategoryTagSection } from '../../components/CategoryTagSection';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

@Component
export struct HomePage {
  @State private skills: Category[] = [];
  @State private companies: Category[] = [];
  @State private specials: Category[] = [];
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
      const all = await this.repo.getCategories(ctx);
      this.skills = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.SKILL);
      this.companies = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.COMPANY);
      this.specials = CategoryGroupUtil.browseItems(all, CategoryGroupUtil.SPECIAL);
      this.hotList = await this.repo.getHot(ctx);
      this.stats = await this.repo.getTodayStudyStats();
    } catch (_e) {
      this.skills = [];
      this.companies = [];
      this.specials = [];
      this.hotList = [];
      this.stats = { questionCount: 0, minutes: 0, mastered: 0, toReview: 0 };
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
          Text('搜面试题 / 技能 / 公司题库')
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
          Text('正在加载…').fontSize(13).fontColor('#6B7280').margin({ top: 8 })
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
                  .onClick(() => this.continueStudy())
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

            if (this.skills.length === 0 && this.companies.length === 0 && this.specials.length === 0) {
              Text('未拉到分类，请检查网络与后端地址')
                .fontSize(13)
                .fontColor('#9CA3AF')
                .width('100%')
            }

            Column({ space: 16 }) {
              CategoryTagSection({
                title: '热门技能',
                items: this.skills,
                textColor: '#9A3412',
                chipColor: '#FFEDD5',
                onTagClick: (cat: Category) => this.openCategory(cat)
              })
              CategoryTagSection({
                title: '公司题库',
                items: this.companies,
                textColor: '#1E40AF',
                chipColor: '#DBEAFE',
                onTagClick: (cat: Category) => this.openCategory(cat)
              })
              CategoryTagSection({
                title: '专项',
                items: this.specials,
                textColor: '#166534',
                chipColor: '#DCFCE7',
                onTagClick: (cat: Category) => this.openCategory(cat)
              })
              Text('全部 ›')
                .fontSize(13)
                .fontColor('#2563EB')
                .width('100%')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/bank/CategoryAllPage' });
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)

            Column({ space: 10 }) {
              Text('热门推荐')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              if (this.hotList.length === 0) {
                Text('暂无推荐题目')
                  .fontSize(13)
                  .fontColor('#9CA3AF')
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
