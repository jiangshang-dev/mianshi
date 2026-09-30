import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import { ListenHistorySession, ListenRepository } from '../../data/repository/ListenRepository';

@Entry
@Component
struct ListenHistoryPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private items: ListenHistorySession[] = [];
  @State private loading: boolean = true;
  private repo: ListenRepository = ListenRepository.getInstance();

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
      this.items = await this.repo.listHistory();
    } catch (_e) {
      this.items = [];
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(I18n.t('listen_logs', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Text(I18n.t('listen_hist_note', this.lang))
        .fontSize(12)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })

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
          Text(I18n.t('listen_hist_empty', this.lang))
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: ListenHistorySession) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(item.title.length > 0 ? item.title : I18n.t('listen_logs', this.lang))
                    .fontSize(15)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(`${item.createTime}  ·  ${item.turnCount} 题`)
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
                  url: 'pages/listen/ListenHistoryDetailPage',
                  params: {
                    'sessionId': item.sessionId,
                    'title': item.title
                  }
                });
              })
            }
          }, (item: ListenHistorySession) => item.sessionId)
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
