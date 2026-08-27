import { router } from '@kit.ArkUI';
import { InboxItem, RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';
import { LoginGate } from '../../common/utils/LoginGate';
import { I18n } from '../../common/i18n/I18n';

@Entry
@Component
struct InboxPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private items: InboxItem[] = [];
  @State private loading: boolean = true;

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
      this.items = await RemoteApiDataSource.inboxList(LoginGate.currentUserId());
    } catch (_e) {
      this.items = [];
    } finally {
      this.loading = false;
    }
  }

  private async markAll(): Promise<void> {
    const uid = LoginGate.currentUserId();
    if (uid.length === 0) {
      return;
    }
    await RemoteApiDataSource.inboxReadAll(uid);
    await this.loadData();
  }

  private hasUnread(): boolean {
    for (let i = 0; i < this.items.length; i++) {
      if (!this.items[i].read) {
        return true;
      }
    }
    return false;
  }

  private openItem(item: InboxItem): void {
    router.pushUrl({
      url: 'pages/profile/InboxDetailPage',
      params: {
        'id': item.id,
        'title': item.title,
        'content': item.content,
        'time': item.createTime
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('inbox', this.lang)).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).layoutWeight(1)
        if (this.hasUnread()) {
          Text(I18n.t('inbox_all_read', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.markAll();
            })
        }
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
          Text(I18n.t('inbox_login', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
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
          Text(I18n.t('inbox_empty', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: InboxItem) => {
            ListItem() {
              Row({ space: 10 }) {
                Circle()
                  .width(8)
                  .height(8)
                  .fill(item.read ? '#E5E7EB' : '#2563EB')
                Column({ space: 4 }) {
                  Text(item.title)
                    .fontSize(15)
                    .fontWeight(item.read ? FontWeight.Regular : FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(item.content)
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
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
                this.openItem(item);
              })
            }
          }, (item: InboxItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 4, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
