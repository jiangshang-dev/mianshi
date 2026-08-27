import { router } from '@kit.ArkUI';
import { AiHistoryRepository, AiHistorySession } from '../../data/repository/AiHistoryRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

interface HistoryRouteParams {
  scene?: string;
  title?: string;
}

@Entry
@Component
struct AiHistoryPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = 'AI 记录';
  @State private scene: string = 'chat';
  @State private items: AiHistorySession[] = [];
  @State private loading: boolean = true;
  private repo: AiHistoryRepository = AiHistoryRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as HistoryRouteParams;
    this.scene = params.scene ?? 'chat';
    this.title = params.title ?? (this.scene === 'interview' ? I18n.t('iv_logs', this.lang) : I18n.t('ai_qa_title', this.lang));
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
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).layoutWeight(1)
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
          Text(I18n.t('hist_login', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
          Button(I18n.t('go_login', this.lang))
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
          Text(this.scene === 'interview' ? I18n.t('hist_empty_iv', this.lang) : I18n.t('hist_empty_ai', this.lang))
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
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
                  Text(item.questionTitle.length > 0 ? item.questionTitle : I18n.t('unnamed_session', this.lang))
                    .fontSize(15)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(item.updateTime.length > 0 ? item.updateTime : item.createTime)
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›').fontSize(18).fontColor('#D1D5DB')
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
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
    .backgroundColor($r('app.color.page_bg'))
  }
}
