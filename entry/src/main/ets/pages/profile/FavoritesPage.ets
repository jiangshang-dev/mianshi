import { router } from '@kit.ArkUI';
import { FavoriteItem, FavoriteRepository } from '../../data/repository/FavoriteRepository';
import { LoginGate } from '../../common/utils/LoginGate';

@Entry
@Component
struct FavoritesPage {
  @State private items: FavoriteItem[] = [];
  @State private loading: boolean = true;
  private repo: FavoriteRepository = FavoriteRepository.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      if (!LoginGate.isLoggedIn()) {
        this.items = [];
        return;
      }
      await this.repo.sync();
      this.items = await this.repo.list();
    } catch (_e) {
      this.items = [];
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).padding({ right: 8 }).onClick(() => router.back())
        Text('收藏夹').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1)
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
      } else if (!LoginGate.isLoggedIn()) {
        Column({ space: 12 }) {
          Text('登录后查看收藏的题目').fontSize(14).fontColor('#6B7280')
          Button('去登录')
            .width(140)
            .height(40)
            .backgroundColor('#2563EB')
            .onClick(() => LoginGate.goLogin())
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Column() {
          Text('还没有收藏题目').fontSize(14).fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: FavoriteItem) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(item.questionTitle.length > 0 ? item.questionTitle : '未命名题目')
                    .fontSize(15)
                    .fontColor('#111827')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(item.createTime)
                    .fontSize(12)
                    .fontColor('#9CA3AF')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›').fontSize(18).fontColor('#D1D5DB')
              }
              .width('100%')
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/bank/QuestionDetailPage',
                  params: { 'id': item.questionId }
                });
              })
            }
          }, (item: FavoriteItem) => item.id)
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
