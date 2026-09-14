import { common } from '@kit.AbilityKit';
import { KeyboardAvoidMode, promptAction, router, window } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import { CsMessage, CsSession } from '../../common/models/CsTypes';
import { CsRepository } from '../../data/repository/CsRepository';

@Entry
@Component
struct CustomerServicePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private sending: boolean = false;
  @State private errorText: string = '';
  @State private title: string = '';
  @State private sessionId: string = '';
  @State private closed: boolean = false;
  @State private messages: CsMessage[] = [];
  @State private draft: string = '';
  private repo: CsRepository = CsRepository.getInstance();
  private scroller: Scroller = new Scroller();
  private lastSyncKey: string = '';
  private hostWin: window.Window | null = null;
  private kbListener: (h: number) => void = (_h: number) => {
  };
  private prevAvoid: KeyboardAvoidMode | null = null;

  aboutToAppear(): void {
    this.title = I18n.t('cs_title', this.lang);
    this.kbListener = (h: number) => {
      this.onKeyboardHeight(h);
    };
    void this.bindKeyboard();
    setTimeout(() => {
      if (!LoginGate.isLoggedIn()) {
        this.loading = false;
        this.errorText = I18n.t('go_login', this.lang);
        LoginGate.goLogin();
        return;
      }
      void this.boot();
    }, 30);
  }

  aboutToDisappear(): void {
    this.repo.stopPoll();
    this.unbindKeyboard();
  }

  private async bindKeyboard(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = await window.getLastWindow(ctx);
      this.hostWin = win;
      try {
        const ui = win.getUIContext();
        this.prevAvoid = ui.getKeyboardAvoidMode();
        ui.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
      } catch (_e) {
      }
      win.on('keyboardHeightChange', this.kbListener);
    } catch (_e) {
    }
  }

  private unbindKeyboard(): void {
    const win = this.hostWin;
    this.hostWin = null;
    if (win) {
      try {
        win.off('keyboardHeightChange');
      } catch (_e) {
      }
      try {
        if (this.prevAvoid !== null) {
          win.getUIContext().setKeyboardAvoidMode(this.prevAvoid);
        }
      } catch (_e) {
      }
    }
  }

  private onKeyboardHeight(px: number): void {
    if (px > 80) {
      this.scrollBottom();
    }
  }

  private async boot(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const session: CsSession = await this.repo.mine();
      const list: CsMessage[] = await this.repo.messages(session.id);
      this.sessionId = session.id;
      this.closed = session.status === 2;
      this.title = this.buildTitle(session);
      this.applyMessages(list, true);
      this.repo.startPoll(session.id, (synced: CsMessage[]) => {
        this.applyMessages(synced, false);
      });
    } catch (e) {
      const err = e as Error;
      this.errorText = err !== null && err.message !== undefined && err.message.length > 0
        ? err.message : I18n.t('cs_open_fail', this.lang);
      promptAction.showToast({ message: this.errorText });
    } finally {
      this.loading = false;
    }
  }

  private buildTitle(session: CsSession): string {
    if (session.status === 2) {
      return I18n.t('cs_closed', this.lang);
    }
    if (session.status === 1 || (session.agentName !== undefined && session.agentName.length > 0)) {
      return I18n.t('cs_title', this.lang);
    }
    return I18n.t('cs_queue', this.lang);
  }

  private applyMessages(list: CsMessage[], forceScroll: boolean): void {
    const safe: CsMessage[] = list !== null && list !== undefined ? list : [];
    let key = `${safe.length}`;
    for (let i = 0; i < safe.length; i++) {
      key = `${key}|${safe[i].id}`;
    }
    if (!forceScroll && key === this.lastSyncKey) {
      return;
    }
    const grew = safe.length > this.messages.length;
    this.lastSyncKey = key;
    this.messages = safe;
    if (forceScroll || grew) {
      this.scrollBottom();
    }
  }

  private scrollBottom(): void {
    setTimeout(() => {
      try {
        this.scroller.scrollEdge(Edge.Bottom);
      } catch (_e) {
      }
    }, 80);
  }

  private async send(): Promise<void> {
    const text = this.draft.trim();
    if (text.length === 0 || this.sessionId.length === 0 || this.sending || this.closed) {
      return;
    }
    this.sending = true;
    try {
      const msg = await this.repo.send(this.sessionId, text);
      this.draft = '';
      const next: CsMessage[] = [];
      for (let i = 0; i < this.messages.length; i++) {
        next.push(this.messages[i]);
      }
      if (next.findIndex((m: CsMessage) => m.id === msg.id) < 0) {
        next.push(msg);
      }
      this.applyMessages(next, true);
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({
        message: err !== null && err.message !== undefined && err.message.length > 0
          ? err.message : I18n.t('cs_send_fail', this.lang)
      });
    } finally {
      this.sending = false;
    }
  }

  private senderLabel(m: CsMessage): string {
    if (m.senderType === 'agent') {
      return I18n.t('cs_title', this.lang);
    }
    if (m.senderName !== undefined && m.senderName.length > 0) {
      return m.senderName;
    }
    return m.senderType !== undefined ? m.senderType : '';
  }

  private displayContent(m: CsMessage): string {
    const text = m.content !== undefined ? m.content : '';
    if (m.senderType === 'system' && text.indexOf('已接入') >= 0) {
      return '在线客服已接入';
    }
    return text;
  }

  private isUser(m: CsMessage): boolean {
    return m.senderType === 'user';
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => {
            router.back();
          })
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .flexShrink(0)

      if (this.loading) {
        Text(I18n.t('cs_loading', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 48 })
          .layoutWeight(1)
      } else if (this.errorText.length > 0 && this.sessionId.length === 0) {
        Column({ space: 12 }) {
          Text(this.errorText)
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
          Button(I18n.t('cs_title', this.lang))
            .onClick(() => {
              void this.boot();
            })
        }
        .margin({ top: 48 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (m: CsMessage) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(this.senderLabel(m))
                  .fontSize(11)
                  .fontColor($r('app.color.text_muted'))
                  .width('100%')
                  .textAlign(this.isUser(m) ? TextAlign.End : TextAlign.Start)
                Text(this.displayContent(m))
                  .fontSize(14)
                  .fontColor(this.isUser(m) ? '#FFFFFF' : $r('app.color.text_primary'))
                  .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                  .borderRadius(10)
                  .backgroundColor(this.isUser(m) ? '#2563EB' : '#F3F4F6')
              }
              .width('100%')
              .alignItems(this.isUser(m) ? HorizontalAlign.End : HorizontalAlign.Start)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            }
          }, (m: CsMessage) => `${m.id}`)
        }
        .layoutWeight(1)
        .width('100%')
        .clip(true)
        .backgroundColor($r('app.color.page_bg'))

        Row({ space: 8 }) {
          TextInput({ text: this.draft, placeholder: I18n.t('cs_hint', this.lang) })
            .layoutWeight(1)
            .height(40)
            .onChange((v: string) => {
              this.draft = v;
            })
            .onFocus(() => {
              this.scrollBottom();
            })
          Button(this.sending ? '...' : I18n.t('cs_send', this.lang))
            .height(40)
            .enabled(!this.sending && !this.closed && this.draft.trim().length > 0)
            .onClick(() => {
              void this.send();
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.card_bg'))
        .flexShrink(0)
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
