import { router } from '@kit.ArkUI';
import { AiHistoryMessage, AiHistoryRepository } from '../../data/repository/AiHistoryRepository';
import { I18n } from '../../common/i18n/I18n';

interface DetailRouteParams {
  sessionId?: string;
  title?: string;
}

@Entry
@Component
struct AiHistoryDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = '对话明细';
  @State private sessionId: string = '';
  @State private messages: AiHistoryMessage[] = [];
  @State private loading: boolean = true;
  private repo: AiHistoryRepository = AiHistoryRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouteParams;
    this.sessionId = params.sessionId ?? '';
    this.title = params.title ?? I18n.t('chat_detail', this.lang);
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      this.messages = await this.repo.listMessages(this.sessionId);
    } catch (_e) {
      this.messages = [];
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).padding({ right: 8 }).onClick(() => router.back())
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
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
      } else if (this.messages.length === 0) {
        Column() {
          Text(I18n.t('no_chat', this.lang)).fontSize(14).fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.messages, (m: AiHistoryMessage) => {
            ListItem() {
              Column({ space: 6 }) {
                Row() {
                  Text(m.role === 'user' ? I18n.t('me', this.lang) : 'AI')
                    .fontSize(12)
                    .fontColor(m.role === 'user' ? '#1D4ED8' : '#059669')
                    .layoutWeight(1)
                  Text(m.createTime)
                    .fontSize(11)
                    .fontColor('#9CA3AF')
                }
                .width('100%')
                Text(m.content)
                  .fontSize(14)
                  .fontColor('#111827')
                  .lineHeight(22)
                  .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor(m.role === 'user' ? '#EFF6FF' : Color.White)
              .borderRadius(12)
              .alignItems(HorizontalAlign.Start)
            }
          }, (m: AiHistoryMessage) => m.id)
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
