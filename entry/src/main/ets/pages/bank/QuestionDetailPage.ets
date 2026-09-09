import { common, Want } from '@kit.AbilityKit';
import { promptAction, router, window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { AiChatMessage, AiStreamSnapshot, QuestionItem } from '../../common/models/Types';
import { MdContentView } from '../../components/MdContentView';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { SseAbort } from '../../common/network/HttpClient';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { AiNotice } from '../../common/utils/AiNotice';
import { I18n } from '../../common/i18n/I18n';
import { AiGenMark, AiDisclaimerBar } from '../../components/AiGenMark';
import { MemberBadge, MemberNeedHint } from '../../components/MemberBadge';
import { BilibiliLink, BilibiliVideoItem } from '../../common/utils/BilibiliLink';
import { CommentSection } from '../../components/CommentSection';
import { CommentComposerPanel } from '../../components/CommentComposerPanel';
import { CommentDetailPanel } from '../../components/CommentDetailPanel';
import { CommentUi } from '../../common/utils/CommentUi';
import { AppFeatureRepository } from '../../data/repository/AppFeatureRepository';
import { MemberRepository } from '../../data/repository/MemberRepository';

interface DetailRouteParams {
  id?: string;
}

@Entry
@Component
struct QuestionDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('commentSheetOpen') commentSheetOpen: boolean = false;
  @StorageLink('commentComposeOpen') commentComposeOpen: boolean = false;
  @StorageLink('commentDetailOpen') commentDetailOpen: boolean = false;
  @StorageLink('commentReloadTick') commentReloadTick: number = 0;
  @StorageLink('commentFeatureEnabled') commentFeatureEnabled: boolean = true;
  @StorageLink('questionAiEnabled') @Watch('onQuestionAiFlag') questionAiEnabled: boolean = true;
  @State private question: QuestionItem | null = null;
  @State private loading: boolean = true;
  @State private showAi: boolean = false;
  @State private aiInput: string = '';
  @State private aiMessages: AiChatMessage[] = [];
  @State private aiBusy: boolean = false;
  @State private favorited: boolean = false;
  @State private pageHeight: number = 0;
  @State private aiSheetHeight: number = 480;
  @State private detailTab: string = 'lecture';
  @State private videos: BilibiliVideoItem[] = [];
  @State private videoIndex: number = 0;
  @State private videoFullScreen: boolean = false;
  @State private refreshing: boolean = false;
  private questionId: string = '';
  private dragStartHeight: number = 480;
  private repo: QuestionRepository = QuestionRepository.getInstance();
  private aiAbort: SseAbort | null = null;
  private aiSessionId: string = '';
  private webController: webview.WebviewController = new webview.WebviewController();
  private fsController: webview.WebviewController = new webview.WebviewController();
  private webAttached: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouteParams;
    this.questionId = params.id ?? '';
    AppFeatureRepository.getInstance().refresh();
    MemberRepository.getInstance().refreshStatus();
    this.loadDetail();
  }

  onPageShow(): void {
    AppFeatureRepository.getInstance().refresh();
  }

  onQuestionAiFlag(): void {
    if (!this.questionAiEnabled) {
      this.showAi = false;
      this.stopAi();
    }
  }

  aboutToDisappear(): void {
    this.aiAbort?.abort();
    this.exitVideoFullScreen();
  }

  private async loadDetail(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await this.repo.syncFavorites();
      this.question = await this.repo.getDetail(ctx, this.questionId);
      this.favorited = this.question !== null && this.question.favorited;
      this.videos = this.question ? BilibiliLink.parseList(this.question.bilibiliUrls ?? []) : [];
      this.videoIndex = 0;
      this.detailTab = 'lecture';
      this.webAttached = false;
      if (this.question) {
        this.repo.recordQuestionView(this.question.id);
      }
    } catch (_e) {
      this.question = null;
    } finally {
      this.loading = false;
    }
  }

  private pullRefresh(): void {
    this.refreshing = true;
    CommentUi.bumpReload();
    setTimeout((): void => {
      this.refreshing = false;
    }, 800);
  }

  private async sendAi(text: string): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      LoginGate.ensure(I18n.t('ai_feature', this.lang), () => {
      });
      return;
    }
    if (!this.question || text.trim().length === 0 || this.aiBusy) {
      return;
    }
    const userText = text.trim();
    this.aiMessages = this.aiMessages.concat([
      {
        role: 'user',
        content: userText,
        thinking: '',
        thinkingDone: false,
        thinkingOpen: false,
        phase: ''
      },
      {
        role: 'assistant',
        content: '',
        thinking: '',
        thinkingDone: false,
        thinkingOpen: false,
        phase: 'thinking'
      }
    ]);
    this.aiInput = '';
    this.aiBusy = true;
    const abort = new SseAbort();
    this.aiAbort = abort;
    try {
      const reply = await this.repo.askAiStream(this.question, userText, (snap: AiStreamSnapshot) => {
        if (!abort.stopped) {
          if (snap.sessionId.length > 0) {
            this.aiSessionId = snap.sessionId;
          }
          this.applyStream(snap);
        }
      }, abort, this.aiSessionId);
      if (abort.stopped) {
        return;
      }
      const last = this.lastAssistant();
      if (last && last.phase === 'error' && MemberGate.isQuotaError(last.content)) {
        this.patchLastAssistant({
          role: 'assistant',
          content: MemberGate.displayMessage(last.content),
          thinking: last.thinking,
          thinkingDone: last.thinkingDone,
          thinkingOpen: last.thinkingOpen,
          phase: last.phase
        });
        MemberGate.promptUpgrade(last.content);
      } else if (last && last.content.length === 0 && last.thinking.length === 0) {
        this.applyStream({
          thinking: '',
          markdown: reply.length > 0 ? reply : 'AI 没有返回内容，请稍后重试。',
          phase: 'error',
          thinkingDone: false,
          sessionId: ''
        });
      }
    } catch (_e) {
      if (!abort.stopped) {
        this.applyStream({
          thinking: '',
          markdown: 'AI 服务暂时不可用，请稍后重试。',
          phase: 'error',
          thinkingDone: false,
          sessionId: ''
        });
      }
    } finally {
      if (this.aiAbort === abort) {
        this.aiAbort = null;
      }
      this.aiBusy = false;
    }
  }

  private stopAi(): void {
    if (!this.aiBusy) {
      return;
    }
    this.markStopped();
    this.aiAbort?.abort();
    this.aiBusy = false;
  }

  private markStopped(): void {
    const last = this.lastAssistant();
    if (!last) {
      return;
    }
    const body = last.content.length > 0 ? last.content : last.thinking;
    this.patchLastAssistant({
      role: 'assistant',
      content: body.length > 0 ? `${body}\n\n（已停止）` : '已停止',
      thinking: last.thinking,
      thinkingDone: last.thinking.length > 0,
      thinkingOpen: last.thinkingOpen,
      phase: 'done'
    });
  }

  private lastAssistant(): AiChatMessage | null {
    if (this.aiMessages.length === 0) {
      return null;
    }
    const last = this.aiMessages[this.aiMessages.length - 1];
    return last.role === 'assistant' ? last : null;
  }

  private applyStream(snap: AiStreamSnapshot): void {
    const last = this.lastAssistant();
    if (!last) {
      return;
    }
    this.patchLastAssistant({
      role: 'assistant',
      content: snap.markdown,
      thinking: snap.thinking,
      thinkingDone: snap.thinkingDone,
      thinkingOpen: last.thinkingOpen,
      phase: snap.phase
    });
  }

  private toggleThinking(idx: number): void {
    if (idx < 0 || idx >= this.aiMessages.length) {
      return;
    }
    const list = this.aiMessages.slice();
    const m = list[idx];
    if (m.role !== 'assistant') {
      return;
    }
    list[idx] = {
      role: 'assistant',
      content: m.content,
      thinking: m.thinking,
      thinkingDone: m.thinkingDone,
      thinkingOpen: !m.thinkingOpen,
      phase: m.phase
    };
    this.aiMessages = list;
  }

  private patchLastAssistant(next: AiChatMessage): void {
    if (this.aiMessages.length === 0) {
      return;
    }
    const list = this.aiMessages.slice();
    if (list[list.length - 1].role === 'assistant') {
      list[list.length - 1] = next;
      this.aiMessages = list;
    }
  }

  private minSheetHeight(): number {
    return 168;
  }

  private maxSheetHeight(): number {
    if (this.pageHeight <= 0) {
      return 720;
    }
    return Math.max(this.minSheetHeight(), this.pageHeight - 8);
  }

  private defaultSheetHeight(): number {
    const maxH = this.maxSheetHeight();
    const minH = this.minSheetHeight();
    if (this.pageHeight <= 0) {
      return 480;
    }
    return Math.round(Math.min(maxH, Math.max(minH, this.pageHeight * 0.62)));
  }

  private clampSheetHeight(h: number): number {
    const minH = this.minSheetHeight();
    const maxH = this.maxSheetHeight();
    if (h < minH) {
      return minH;
    }
    if (h > maxH) {
      return maxH;
    }
    return h;
  }

  private openAi(prompt?: string): void {
    if (!this.questionAiEnabled) {
      return;
    }
    LoginGate.ensure(I18n.t('ai_feature', this.lang), () => {
      const ctx = getContext(this) as common.UIAbilityContext;
      AiNotice.ensure(ctx, () => {
        this.showAi = true;
        this.aiSheetHeight = this.defaultSheetHeight();
        if (prompt !== undefined && prompt.length > 0) {
          this.sendAi(prompt);
        }
      });
    });
  }

  private openReport(): void {
    if (!this.question) {
      return;
    }
    const q = this.question;
    LoginGate.ensure(I18n.t('report_feature', this.lang), () => {
      router.pushUrl({
        url: 'pages/bank/QuestionReportPage',
        params: { 'questionId': q.id, 'questionTitle': q.title }
      });
    });
  }

  private toggleStar(): void {
    if (!this.question) {
      return;
    }
    const q = this.question;
    LoginGate.ensure(I18n.t('fav_feature', this.lang), () => {
      this.saveFavorite(q.id, q.title);
    });
  }

  private async saveFavorite(id: string, title: string): Promise<void> {
    this.favorited = await this.repo.toggleFavorite(id, title);
    promptAction.showToast({ message: this.favorited ? I18n.t('fav_on', this.lang) : I18n.t('fav_off', this.lang) });
  }

  private selectVideo(index: number): void {
    if (index < 0 || index >= this.videos.length) {
      return;
    }
    this.videoIndex = index;
    if (this.webAttached) {
      try {
        this.webController.loadUrl(this.videos[index].embedUrl);
      } catch (_e) {
      }
    }
  }

  private enterVideoFullScreen(): void {
    if (this.videos.length === 0) {
      return;
    }
    this.videoFullScreen = true;
    this.applyFullScreenWindow(true);
  }

  private exitVideoFullScreen(): void {
    if (!this.videoFullScreen) {
      return;
    }
    this.videoFullScreen = false;
    this.applyFullScreenWindow(false);
  }

  private async applyFullScreenWindow(on: boolean): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = await window.getLastWindow(ctx);
      if (on) {
        await win.setPreferredOrientation(window.Orientation.LANDSCAPE);
        await win.setWindowLayoutFullScreen(true);
        await win.setWindowSystemBarEnable([]);
      } else {
        await win.setPreferredOrientation(window.Orientation.PORTRAIT);
        await win.setWindowLayoutFullScreen(false);
        await win.setWindowSystemBarEnable(['status', 'navigation']);
      }
    } catch (_e) {
    }
  }

  private currentVideo(): BilibiliVideoItem | null {
    if (this.videoIndex < 0 || this.videoIndex >= this.videos.length) {
      return null;
    }
    return this.videos[this.videoIndex];
  }

  private async openInBiliApp(): Promise<void> {
    const item = this.currentVideo();
    if (item === null) {
      return;
    }
    const ctx = getContext(this) as common.UIAbilityContext;
    if (item.appUrl.length > 0) {
      const appWant: Want = {
        action: 'ohos.want.action.viewData',
        uri: item.appUrl
      };
      try {
        await ctx.startAbility(appWant);
        return;
      } catch (_e) {
      }
    }
    const webWant: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: item.playUrl
    };
    try {
      await ctx.startAbility(webWant);
    } catch (_e) {
      promptAction.showToast({ message: I18n.t('video_open_fail', this.lang) });
    }
  }

  onBackPress(): boolean {
    if (this.videoFullScreen) {
      this.exitVideoFullScreen();
      return true;
    }
    return false;
  }

  private onSheetPanStart(): void {
    this.dragStartHeight = this.aiSheetHeight;
  }

  private onSheetPanUpdate(event: GestureEvent): void {
    this.aiSheetHeight = this.clampSheetHeight(this.dragStartHeight - event.offsetY);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
          Text(I18n.t('detail_title', this.lang)).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).layoutWeight(1)
          Text(I18n.t('report_feature', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.text_muted'))
            .padding({ right: 14, top: 4, bottom: 4 })
            .onClick(() => {
              this.openReport();
            })
          Text(this.favorited ? '★' : '☆')
            .fontSize(22)
            .fontColor(this.favorited ? '#F59E0B' : $r('app.color.chevron'))
            .onClick(() => {
              this.toggleStar();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        if (this.loading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
        } else if (!this.question) {
          Column() {
            Text(I18n.t('not_found', this.lang)).fontSize(15).fontColor($r('app.color.text_muted'))
          }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.refreshing }) {
          Scroll() {
            Column({ space: 14 }) {
              Row({ space: 6 }) {
                // Text(this.question.source === 'local_md' ? I18n.t('src_local', this.lang) : I18n.t('src_remote', this.lang))
                //   .fontSize(11)
                //   .fontColor(this.question.source === 'local_md' ? '#047857' : '#1D4ED8')
                //   .backgroundColor(this.question.source === 'local_md' ? '#D1FAE5' : '#DBEAFE')
                //   .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                //   .borderRadius(6)
                Text(this.question.difficulty)
                  .fontSize(11).fontColor($r('app.color.text_muted')).backgroundColor($r('app.color.page_bg'))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6)
                if (this.question.hot) {
                  Text(I18n.t('hot', this.lang)).fontSize(11).fontColor('#B45309').backgroundColor('#FEF3C7')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6)
                }
              }

              Text(this.question.title)
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%')

              Text(`${this.question.categoryName}${this.question.tags.length > 0 ?
                ' · ' + this.question.tags.join(' / ') : ''}`)
                .fontSize(13).fontColor($r('app.color.text_muted')).width('100%')

              if (this.videos.length > 0) {
                Row({ space: 8 }) {
                  this.detailTabChip('tab_lecture', 'lecture')
                  this.detailTabChip('tab_video', 'video')
                }
                .width('100%')
              }

              if (this.videos.length === 0 || this.detailTab === 'lecture') {
                Column({ space: 8 }) {
                  Text(I18n.t('answer_body', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
                  MdContentView({ content: this.question.content ?? '' })
                }
                .width('100%').padding(14).backgroundColor($r('app.color.card_bg')).borderRadius(14)

                if (this.question.interviewAnswer) {
                  Column({ space: 8 }) {
                    Text(I18n.t('interview_ans', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
                    MdContentView({ content: this.question.interviewAnswer })
                  }
                  .width('100%').padding(14).backgroundColor($r('app.color.card_bg')).borderRadius(14)
                }

                if (this.question.knowledgePoints && this.question.knowledgePoints.length > 0) {
                  Column({ space: 8 }) {
                    Text(I18n.t('knowledge', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
                    Flex({ wrap: FlexWrap.Wrap }) {
                      ForEach(this.question.knowledgePoints, (p: string) => {
                        Text(p).fontSize(12).fontColor('#3730A3').backgroundColor('#E0E7FF')
                          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                          .borderRadius(14).margin({ right: 8, bottom: 8 })
                      }, (p: string) => p)
                    }.width('100%')
                  }
                  .width('100%').padding(14).backgroundColor($r('app.color.card_bg')).borderRadius(14)
                }
              } else {
                this.videoPanel()
              }

              if (this.questionAiEnabled) {
                Column({ space: 8 }) {
                  Text(I18n.t('quick_ai', this.lang)).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(I18n.aiTips(this.lang), (tip: string) => {
                      Text(tip).fontSize(12).fontColor('#1D4ED8')
                        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                        .backgroundColor('#EFF6FF').borderRadius(16)
                        .margin({ right: 8, bottom: 8 })
                        .onClick(() => {
                          this.openAi(tip);
                        })
                    }, (tip: string) => tip)
                  }
                }.width('100%')
              }

              if (this.commentFeatureEnabled) {
                CommentSection({
                  questionId: this.question.id,
                  composeOpen: this.commentComposeOpen,
                  reloadTick: this.commentReloadTick
                })
              }
            }
            .padding({ left: 16, right: 16, bottom: 96 }).width('100%')
          }.layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
          }
          .layoutWeight(1)
          .width('100%')
          .onRefreshing(() => this.pullRefresh())
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.page_bg'))

      if (this.questionAiEnabled && !this.showAi && !this.videoFullScreen && !this.commentSheetOpen) {
        Column() {
          Text('AI').fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_on_color'))
        }
        .width(56).height(56).borderRadius(28).justifyContent(FlexAlign.Center)
        .linearGradient({ angle: 135, colors: [['#4F46E5', 0], ['#2563EB', 1]] })
        .margin({ right: 20, bottom: 28 })
        .onClick(() => {
          this.openAi();
        })
      }

      if (this.questionAiEnabled && this.showAi) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000055')
            .onClick(() => {
              this.showAi = false;
            })

          Column() {
            Column() {
              Column()
                .width(40)
                .height(4)
                .borderRadius(2)
                .backgroundColor('#D1D5DB')
                .margin({ top: 8, bottom: 10 })

              Row({ space: 8 }) {
                Text(I18n.t('ai_helper', this.lang)).fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).layoutWeight(1)
                MemberBadge()
                AiGenMark()
                if (this.aiBusy) {
                  Text(I18n.t('stop', this.lang)).fontSize(13).fontColor('#DC2626').margin({ right: 12 }).onClick(() => {
                    this.stopAi();
                  })
                }
                Text(I18n.t('collapse', this.lang)).fontSize(13).fontColor($r('app.color.accent')).onClick(() => {
                  this.showAi = false;
                })
              }.width('100%').padding({ bottom: 8 })

              Text(this.question ? I18n.tf('cur_q', this.question.title, this.lang) : '')
                .fontSize(12).fontColor($r('app.color.text_muted')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ bottom: 6 })
              AiDisclaimerBar({ shortText: false })
                .margin({ bottom: 10 })
            }
            .width('100%')
            .gesture(
              PanGesture({ fingers: 1, direction: PanDirection.Vertical, distance: 2 })
                .onActionStart(() => {
                  this.onSheetPanStart();
                })
                .onActionUpdate((event: GestureEvent) => {
                  this.onSheetPanUpdate(event);
                })
                .onActionEnd((event: GestureEvent) => {
                  this.onSheetPanUpdate(event);
                })
            )

            if (this.aiMessages.length === 0) {
              Column({ space: 10 }) {
                MemberNeedHint()
                Text(I18n.t('ai_empty', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .width('100%')
              }
              .width('100%')
              .layoutWeight(1)
              .padding({ top: 4, bottom: 8 })
            } else {
              List({ space: 8 }) {
                ForEach(this.aiMessages, (m: AiChatMessage, idx: number) => {
                  ListItem() {
                    Column() {
                      Row({ space: 6 }) {
                        Text(m.role === 'user' ? I18n.t('me', this.lang) : 'AI')
                          .fontSize(11).fontColor($r('app.color.text_muted'))
                        if (m.role !== 'user') {
                          AiGenMark()
                        }
                      }
                      .width('100%')
                      .justifyContent(m.role === 'user' ? FlexAlign.End : FlexAlign.Start)
                      if (m.role === 'user') {
                        Text(m.content).fontSize(14).fontColor($r('app.color.text_primary')).padding(10)
                          .backgroundColor($r('app.color.bubble_mine_bg'))
                          .borderRadius(10)
                      } else {
                        Column({ space: 8 }) {
                          if (m.phase === 'thinking' || m.thinking.length > 0 || m.thinkingDone) {
                            Column({ space: 6 }) {
                              Row() {
                                Text(m.thinkingDone ? I18n.t('thought_done', this.lang) : I18n.t('thinking', this.lang))
                                  .fontSize(12)
                                  .fontWeight(FontWeight.Medium)
                                  .fontColor(m.thinkingDone ? '#059669' : '#2563EB')
                                  .layoutWeight(1)
                                Text(m.thinkingOpen ? I18n.t('collapse', this.lang) : I18n.t('expand', this.lang))
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_muted'))
                              }
                              .width('100%')
                              .onClick(() => {
                                this.toggleThinking(idx);
                              })

                              if (m.thinkingOpen && m.thinking.length > 0) {
                                Text(m.thinking)
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_muted'))
                                  .lineHeight(18)
                                  .width('100%')
                              } else if (m.thinkingOpen) {
                                Text(I18n.t('no_thought', this.lang))
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_muted'))
                                  .width('100%')
                              }
                            }
                            .width('100%')
                            .padding(8)
                            .backgroundColor($r('app.color.preview_bg'))
                            .borderRadius(8)
                          }

                          if (m.thinkingDone) {
                            Text(I18n.t('thought_start', this.lang))
                              .fontSize(12)
                              .fontColor('#059669')
                              .width('100%')
                          }

                          if (m.content.length > 0) {
                            MdContentView({ content: m.content, compact: true })
                          }
                        }
                        .padding(10)
                        .backgroundColor($r('app.color.page_bg'))
                        .borderRadius(10)
                        .width('100%')
                      }
                    }
                    .alignItems(m.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
                    .width('100%')
                  }
                }, (m: AiChatMessage, idx: number) =>
                  `m-${idx}-${m.phase}-${m.thinkingDone}-${m.thinkingOpen}-${m.thinking.length}-${m.content.length}`)
              }
              .width('100%')
              .layoutWeight(1)
              .scrollBar(BarState.Auto)
            }

            AiDisclaimerBar({ shortText: true })
              .margin({ top: 4 })
            Row({ space: 8 }) {
              TextInput({ placeholder: I18n.t('ai_ph', this.lang), text: this.aiInput })
                .layoutWeight(1).height(40).backgroundColor($r('app.color.input_bg'))
                .fontColor($r('app.color.text_primary')).placeholderColor($r('app.color.text_muted'))
                .borderRadius(10)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  this.aiInput = v;
                })
              Button(this.aiBusy ? I18n.t('stop', this.lang) : I18n.t('send', this.lang))
                .height(40)
                .fontColor(this.aiBusy ? '#B91C1C' : $r('app.color.text_on_color'))
                .backgroundColor(this.aiBusy ? '#FEE2E2' : '#2563EB')
                .onClick(() => {
                  if (this.aiBusy) {
                    this.stopAi();
                  } else {
                    this.sendAi(this.aiInput);
                  }
                })
            }.width('100%').padding({ top: 8 })
          }
          .width('100%')
          .height(this.aiSheetHeight)
          .padding({ left: 16, right: 16, bottom: 16 })
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius({ topLeft: 18, topRight: 18 })
          .clip(true)
        }
        .width('100%')
        .height('100%')
      }

      if (this.commentFeatureEnabled && this.commentDetailOpen) {
        CommentDetailPanel({
          composeOpen: this.commentComposeOpen,
          reloadTick: this.commentReloadTick
        })
      }

      if (this.commentFeatureEnabled && this.commentComposeOpen) {
        CommentComposerPanel()
      }

      if (this.videoFullScreen && this.videos.length > 0) {
        Stack() {
          Web({ src: this.videos[this.videoIndex].embedUrl, controller: this.fsController })
            .width('100%')
            .height('100%')
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .mediaPlayGestureAccess(true)
            .onControllerAttached(() => {
              try {
                this.fsController.loadUrl(this.videos[this.videoIndex].embedUrl);
              } catch (_e) {
              }
            })
          Row() {
            Text(I18n.t('video_exit_fs', this.lang))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .padding({ left: 16, right: 12, top: 10, bottom: 10 })
              .onClick(() => {
                this.exitVideoFullScreen();
              })
            Blank()
            Text(I18n.t('video_open_bili', this.lang))
              .fontSize(14)
              .fontColor('#93C5FD')
              .padding({ left: 12, right: 16, top: 10, bottom: 10 })
              .onClick(() => {
                this.openInBiliApp();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
      }
    }
    .width('100%').height('100%')
    .onAreaChange((_old: Area, area: Area) => {
      const h = area.height as number;
      if (h > 0 && Math.abs(h - this.pageHeight) > 1) {
        const first = this.pageHeight <= 0;
        this.pageHeight = h;
        if (this.showAi) {
          this.aiSheetHeight = first ? this.defaultSheetHeight() : this.clampSheetHeight(this.aiSheetHeight);
        }
      }
    })
  }

  @Builder
  detailTabChip(labelKey: string, value: string) {
    Text(I18n.t(labelKey, this.lang))
      .fontSize(14)
      .fontColor(this.detailTab === value ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
      .backgroundColor(this.detailTab === value ? $r('app.color.accent') : $r('app.color.card_bg'))
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .borderRadius(20)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.detailTab = value;
        if (value !== 'video') {
          this.webAttached = false;
        }
      })
  }

  @Builder
  videoPanel() {
    Column({ space: 10 }) {
      if (this.videos.length === 0) {
        Text(I18n.t('video_empty', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
      } else {
        Web({ src: this.videos[this.videoIndex].embedUrl, controller: this.webController })
          .width('100%')
          .height(210)
          .borderRadius(8)
          .clip(true)
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .mediaPlayGestureAccess(true)
          .onControllerAttached(() => {
            this.webAttached = true;
            try {
              this.webController.loadUrl(this.videos[this.videoIndex].embedUrl);
            } catch (_e) {
            }
          })
          .onFullScreenEnter(() => {
            this.enterVideoFullScreen();
          })
        Row({ space: 10 }) {
          Text(this.videos[this.videoIndex].title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(I18n.t('video_fullscreen', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.enterVideoFullScreen();
            })
          Text(I18n.t('video_open_bili', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.openInBiliApp();
            })
        }
        .width('100%')
        Text(I18n.t('video_list', this.lang))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        ForEach(this.videos, (v: BilibiliVideoItem, i: number) => {
          Row({ space: 10 }) {
            Text(`${i + 1}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.videoIndex === i ? $r('app.color.accent') : $r('app.color.text_muted'))
              .width(22)
            Text(v.title)
              .fontSize(14)
              .fontColor(this.videoIndex === i ? $r('app.color.accent') : $r('app.color.text_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .padding(10)
          .borderRadius(10)
          .backgroundColor(this.videoIndex === i ? $r('app.color.bubble_mine_bg') : $r('app.color.chip_idle_bg'))
          .onClick(() => {
            this.selectVideo(i);
          })
        }, (v: BilibiliVideoItem, i: number) => `${v.bvid}-${v.embedUrl}-${i}`)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
  }
}
