import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AiChatMessage, AiStreamSnapshot, QuestionItem } from '../../common/models/Types';
import { MdContentView } from '../../components/MdContentView';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { SseAbort } from '../../common/network/HttpClient';

interface DetailRouteParams {
  id?: string;
}

@Entry
@Component
struct QuestionDetailPage {
  @State private question: QuestionItem | null = null;
  @State private loading: boolean = true;
  @State private showAi: boolean = false;
  @State private aiInput: string = '';
  @State private aiMessages: AiChatMessage[] = [];
  @State private aiBusy: boolean = false;
  @State private favorited: boolean = false;
  @State private pageHeight: number = 0;
  @State private aiSheetHeight: number = 480;
  private questionId: string = '';
  private dragStartHeight: number = 480;
  private repo: QuestionRepository = QuestionRepository.getInstance();
  private aiAbort: SseAbort | null = null;

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouteParams;
    this.questionId = params.id ?? '';
    this.loadDetail();
  }

  aboutToDisappear(): void {
    this.aiAbort?.abort();
  }

  private async loadDetail(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.question = await this.repo.getDetail(ctx, this.questionId);
      this.favorited = this.question?.favorited ?? false;
      if (this.question) {
        this.repo.recordQuestionView(this.question.id);
      }
    } catch (_e) {
      this.question = null;
    } finally {
      this.loading = false;
    }
  }

  private async sendAi(text: string): Promise<void> {
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
          this.applyStream(snap);
        }
      }, abort);
      if (abort.stopped) {
        return;
      }
      const last = this.lastAssistant();
      if (last && last.content.length === 0 && last.thinking.length === 0) {
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
    this.showAi = true;
    this.aiSheetHeight = this.defaultSheetHeight();
    if (prompt !== undefined && prompt.length > 0) {
      this.sendAi(prompt);
    }
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
          Text('‹').fontSize(28).padding({ right: 8 }).onClick(() => router.back())
          Text('题目详情').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1)
          Text(this.favorited ? '★' : '☆')
            .fontSize(22)
            .fontColor(this.favorited ? '#F59E0B' : '#9CA3AF')
            .onClick(() => {
              if (this.question) {
                this.favorited = this.repo.toggleFavorite(this.question.id);
                promptAction.showToast({ message: this.favorited ? '已收藏' : '已取消收藏' });
              }
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
            Text('未找到题目内容').fontSize(15).fontColor('#6B7280')
          }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 14 }) {
              Row({ space: 6 }) {
                Text(this.question.source === 'local_md' ? '本地 MD' : '远程 API')
                  .fontSize(11)
                  .fontColor(this.question.source === 'local_md' ? '#047857' : '#1D4ED8')
                  .backgroundColor(this.question.source === 'local_md' ? '#D1FAE5' : '#DBEAFE')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(6)
                Text(this.question.difficulty)
                  .fontSize(11).fontColor('#6B7280').backgroundColor('#F3F4F6')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6)
                if (this.question.hot) {
                  Text('高频').fontSize(11).fontColor('#B45309').backgroundColor('#FEF3C7')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(6)
                }
              }

              Text(this.question.title)
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#111827').width('100%')

              Text(`${this.question.categoryName}${this.question.tags.length > 0 ?
                ' · ' + this.question.tags.join(' / ') : ''}`)
                .fontSize(13).fontColor('#6B7280').width('100%')

              Column({ space: 8 }) {
                Text('标准答案 / 正文').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
                MdContentView({ content: this.question.content ?? '' })
              }
              .width('100%').padding(14).backgroundColor(Color.White).borderRadius(14)

              if (this.question.interviewAnswer) {
                Column({ space: 8 }) {
                  Text('面试推荐回答').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
                  MdContentView({ content: this.question.interviewAnswer })
                }
                .width('100%').padding(14).backgroundColor('#EEF2FF').borderRadius(14)
              }

              if (this.question.knowledgePoints && this.question.knowledgePoints.length > 0) {
                Column({ space: 8 }) {
                  Text('知识点').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.question.knowledgePoints, (p: string) => {
                      Text(p).fontSize(12).fontColor('#3730A3').backgroundColor('#E0E7FF')
                        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                        .borderRadius(14).margin({ right: 8, bottom: 8 })
                    }, (p: string) => p)
                  }.width('100%')
                }
                .width('100%').padding(14).backgroundColor(Color.White).borderRadius(14)
              }

              Column({ space: 8 }) {
                Text('快捷提问 AI').fontSize(15).fontWeight(FontWeight.Medium).width('100%')
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(['看不懂', '简单解释', '举个例子', '面试怎么答', '可能追问'], (tip: string) => {
                    Text(tip).fontSize(12).fontColor('#1D4ED8')
                      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                      .backgroundColor('#EFF6FF').borderRadius(16)
                      .margin({ right: 8, bottom: 8 })
                      .onClick(() => {
                        this.openAi(tip);
                      })
                  }, (tip: string) => tip)
                }
              }.width('100%').padding({ bottom: 80 })
            }
            .padding({ left: 16, right: 16, bottom: 16 }).width('100%')
          }.layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
        }
      }
      .width('100%').height('100%').backgroundColor('#F3F4F6')

      if (!this.showAi) {
        Column() {
          Text('AI').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
        }
        .width(56).height(56).borderRadius(28).justifyContent(FlexAlign.Center)
        .linearGradient({ angle: 135, colors: [['#4F46E5', 0], ['#2563EB', 1]] })
        .margin({ right: 20, bottom: 28 })
        .onClick(() => {
          this.openAi();
        })
      }

      if (this.showAi) {
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

              Row() {
                Text('AI 面试助手').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
                if (this.aiBusy) {
                  Text('停止').fontSize(13).fontColor('#DC2626').margin({ right: 12 }).onClick(() => {
                    this.stopAi();
                  })
                }
                Text('收起').fontSize(13).fontColor('#2563EB').onClick(() => {
                  this.showAi = false;
                })
              }.width('100%').padding({ bottom: 8 })

              Text(this.question ? `当前题目：${this.question.title}` : '')
                .fontSize(12).fontColor('#6B7280').maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ bottom: 10 })
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
              Text('可以问这道题的解法、例子或面试怎么答')
                .fontSize(13)
                .fontColor('#9CA3AF')
                .width('100%')
                .layoutWeight(1)
                .padding({ top: 4, bottom: 8 })
            } else {
              List({ space: 8 }) {
                ForEach(this.aiMessages, (m: AiChatMessage, idx: number) => {
                  ListItem() {
                    Column() {
                      Text(m.role === 'user' ? '我' : 'AI')
                        .fontSize(11).fontColor('#9CA3AF').width('100%')
                        .textAlign(m.role === 'user' ? TextAlign.End : TextAlign.Start)
                      if (m.role === 'user') {
                        Text(m.content).fontSize(14).fontColor('#111827').padding(10)
                          .backgroundColor('#DBEAFE')
                          .borderRadius(10)
                      } else {
                        Column({ space: 8 }) {
                          if (m.phase === 'thinking' || m.thinking.length > 0 || m.thinkingDone) {
                            Column({ space: 6 }) {
                              Row() {
                                Text(m.thinkingDone ? '思考完成' : '正在思考…')
                                  .fontSize(12)
                                  .fontWeight(FontWeight.Medium)
                                  .fontColor(m.thinkingDone ? '#059669' : '#2563EB')
                                  .layoutWeight(1)
                                Text(m.thinkingOpen ? '收起' : '展开')
                                  .fontSize(12)
                                  .fontColor('#6B7280')
                              }
                              .width('100%')
                              .onClick(() => {
                                this.toggleThinking(idx);
                              })

                              if (m.thinkingOpen && m.thinking.length > 0) {
                                Text(m.thinking)
                                  .fontSize(12)
                                  .fontColor('#6B7280')
                                  .lineHeight(18)
                                  .width('100%')
                              } else if (m.thinkingOpen) {
                                Text('暂无思考步骤')
                                  .fontSize(12)
                                  .fontColor('#9CA3AF')
                                  .width('100%')
                              }
                            }
                            .width('100%')
                            .padding(8)
                            .backgroundColor('#EEF2FF')
                            .borderRadius(8)
                          }

                          if (m.thinkingDone) {
                            Text('思考完成，开始输出正文')
                              .fontSize(12)
                              .fontColor('#059669')
                              .width('100%')
                          }

                          if (m.content.length > 0) {
                            MdContentView({ content: m.content, compact: true })
                          }
                        }
                        .padding(10)
                        .backgroundColor('#F3F4F6')
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

            Row({ space: 8 }) {
              TextInput({ placeholder: '针对这道题提问…', text: this.aiInput })
                .layoutWeight(1).height(40).backgroundColor('#F9FAFB').borderRadius(10)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  this.aiInput = v;
                })
              Button(this.aiBusy ? '停止' : '发送')
                .height(40)
                .fontColor(this.aiBusy ? '#B91C1C' : Color.White)
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
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 18, topRight: 18 })
          .clip(true)
        }
        .width('100%')
        .height('100%')
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
}
