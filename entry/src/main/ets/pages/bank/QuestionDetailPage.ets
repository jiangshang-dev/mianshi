import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AiChatMessage, QuestionItem } from '../../common/models/Types';
import { MdContentView } from '../../components/MdContentView';
import { MdParser } from '../../data/parser/MdParser';
import { QuestionRepository } from '../../data/repository/QuestionRepository';

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
  private questionId: string = '';
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouteParams;
    this.questionId = params.id ?? '';
    this.loadDetail();
  }

  private async loadDetail(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.question = await this.repo.getDetail(ctx, this.questionId);
      this.favorited = this.question?.favorited ?? false;
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
    this.aiMessages = this.aiMessages.concat([{ role: 'user', content: userText }]);
    this.aiInput = '';
    this.aiBusy = true;
    try {
      const reply = await this.repo.askAi(this.question, userText);
      this.aiMessages = this.aiMessages.concat([{ role: 'assistant', content: reply }]);
    } catch (_e) {
      this.aiMessages = this.aiMessages.concat([{
        role: 'assistant',
        content: 'AI 服务暂时不可用，请稍后重试。'
      }]);
    } finally {
      this.aiBusy = false;
    }
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
                  Text(MdParser.toPlainReadable(this.question.interviewAnswer))
                    .fontSize(14).fontColor('#1F2937').lineHeight(22).width('100%')
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
                        this.showAi = true;
                        this.sendAi(tip);
                      })
                  }, (tip: string) => tip)
                }
              }.width('100%').padding({ bottom: 80 })
            }
            .padding({ left: 16, right: 16, bottom: 16 }).width('100%')
          }.layoutWeight(1).scrollBar(BarState.Off)
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
          this.showAi = true;
        })
      }

      if (this.showAi) {
        Column() {
          Column() {
            Row() {
              Text('AI 面试助手').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
              Text('收起').fontSize(13).fontColor('#2563EB').onClick(() => {
                this.showAi = false;
              })
            }.width('100%').padding({ bottom: 8 })

            Text(this.question ? `当前题目：${this.question.title}` : '')
              .fontSize(12).fontColor('#6B7280').maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ bottom: 10 })

            List({ space: 8 }) {
              ForEach(this.aiMessages, (m: AiChatMessage, idx: number) => {
                ListItem() {
                  Column() {
                    Text(m.role === 'user' ? '我' : 'AI')
                      .fontSize(11).fontColor('#9CA3AF').width('100%')
                      .textAlign(m.role === 'user' ? TextAlign.End : TextAlign.Start)
                    Text(m.content).fontSize(14).fontColor('#111827').padding(10)
                      .backgroundColor(m.role === 'user' ? '#DBEAFE' : '#F3F4F6')
                      .borderRadius(10).width('100%')
                  }
                  .alignItems(m.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
                  .width('100%')
                }
              }, (_m: AiChatMessage, idx: number) => `m-${idx}`)
            }.layoutWeight(1).width('100%')

            Row({ space: 8 }) {
              TextInput({ placeholder: '针对这道题提问…', text: this.aiInput })
                .layoutWeight(1).height(40).backgroundColor('#F9FAFB').borderRadius(10)
                .padding({ left: 10, right: 10 })
                .onChange((v: string) => {
                  this.aiInput = v;
                })
              Button(this.aiBusy ? '…' : '发送').height(40).enabled(!this.aiBusy).onClick(() => {
                this.sendAi(this.aiInput);
              })
            }.width('100%').padding({ top: 8 })
          }
          .width('100%').height('55%').padding(16).backgroundColor(Color.White)
          .borderRadius({ topLeft: 18, topRight: 18 })
        }
        .width('100%').height('100%').backgroundColor('#00000055').justifyContent(FlexAlign.End)
      }
    }
    .width('100%').height('100%')
  }
}
