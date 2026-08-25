import { router } from '@kit.ArkUI';
import { AiHistoryRepository, AiHistorySession } from '../../data/repository/AiHistoryRepository';
import { LoginGate } from '../../common/utils/LoginGate';

interface HistoryRouteParams {
  scene?: string;
  title?: string;
}

@Entry
@Component
struct AiHistoryPage {
  @State private title: string = 'AI 记录';
  @State private scene: string = 'chat';
  @State private items: AiHistorySession[] = [];
  @State private loading: boolean = true;
  private repo: AiHistoryRepository = AiHistoryRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as HistoryRouteParams;
    this.scene = params.scene ?? 'chat';
    this.title = params.title ?? (this.scene === 'interview' ? '面试记录' : 'AI 问答记录');
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      if (!LoginGate.isLoggedIn()) {
        this.items = [];
        return;
      }
      this.items = await this.repo.listSessions(this.scene);
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
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1)
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
          Text('登录后查看历史记录').fontSize(14).fontColor('#6B7280')
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
          Text(this.scene === 'interview' ? '还没有模拟面试记录' : '还没有 AI 问答记录')
            .fontSize(14)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: AiHistorySession) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(item.questionTitle.length > 0 ? item.questionTitle : '未命名会话')
                    .fontSize(15)
                    .fontColor('#111827')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(item.updateTime.length > 0 ? item.updateTime : item.createTime)
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
                  url: 'pages/profile/AiHistoryDetailPage',
                  params: {
                    'sessionId': item.id,
                    'title': item.questionTitle
                  }
                });
              })
            }
          }, (item: AiHistorySession) => item.id)
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
