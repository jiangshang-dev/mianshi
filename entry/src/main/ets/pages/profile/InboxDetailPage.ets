import { router } from '@kit.ArkUI';
import { LoginGate } from '../../common/utils/LoginGate';
import { RemoteApiDataSource } from '../../data/repository/RemoteApiDataSource';
import { I18n } from '../../common/i18n/I18n';

interface InboxNav {
  id?: string;
  title?: string;
  content?: string;
  time?: string;
}

@Entry
@Component
struct InboxDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = '';
  @State private content: string = '';
  @State private time: string = '';

  aboutToAppear(): void {
    const nav = router.getParams() as InboxNav;
    if (nav !== undefined) {
      this.title = nav.title !== undefined ? nav.title : '';
      this.content = nav.content !== undefined ? nav.content : '';
      this.time = nav.time !== undefined ? nav.time : '';
      const id = nav.id !== undefined ? nav.id : '';
      const uid = LoginGate.currentUserId();
      if (id.length > 0 && uid.length > 0) {
        RemoteApiDataSource.inboxRead(uid, id);
      }
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('inbox', this.lang)).fontSize(18).fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 10 }) {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .width('100%')
          if (this.time.length > 0) {
            Text(this.time).fontSize(12).fontColor('#9CA3AF').width('100%')
          }
          Text(this.content)
            .fontSize(15)
            .fontColor('#374151')
            .lineHeight(24)
            .width('100%')
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
