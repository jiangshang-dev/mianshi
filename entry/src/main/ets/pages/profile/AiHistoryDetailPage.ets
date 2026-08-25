import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { InterviewReportCard } from '../../components/InterviewReportCard';
import { AiHistoryMessage, AiHistoryRepository } from '../../data/repository/AiHistoryRepository';
import { InterviewRepository } from '../../data/repository/InterviewRepository';

interface DetailRouteParams {
  sessionId?: string;
  title?: string;
}

interface HistoryBubble {
  id: string;
  role: string;
  content: string;
  createTime: string;
  hasReport: boolean;
  score: number;
  accuracy: number;
  depth: number;
  expression: number;
  advantages: string[];
  problems: string[];
  suggestions: string[];
}

@Entry
@Component
struct AiHistoryDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = '对话明细';
  @State private sessionId: string = '';
  @State private messages: HistoryBubble[] = [];
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
      const raw = await this.repo.listMessages(this.sessionId);
      const list: HistoryBubble[] = [];
      for (let i = 0; i < raw.length; i++) {
        list.push(AiHistoryDetailPage.toBubble(raw[i]));
      }
      this.messages = list;
    } catch (_e) {
      this.messages = [];
    } finally {
      this.loading = false;
    }
  }

  private static toBubble(m: AiHistoryMessage): HistoryBubble {
    if (m.role === 'user') {
      return {
        id: m.id,
        role: m.role,
        content: m.content,
        createTime: m.createTime,
        hasReport: false,
        score: 0,
        accuracy: 0,
        depth: 0,
        expression: 0,
        advantages: [],
        problems: [],
        suggestions: []
      };
    }
    const parsed = InterviewRepository.parseReply(m.content, '');
    const report = parsed.report;
    if (report === null) {
      return {
        id: m.id,
        role: m.role,
        content: m.content,
        createTime: m.createTime,
        hasReport: false,
        score: 0,
        accuracy: 0,
        depth: 0,
        expression: 0,
        advantages: [],
        problems: [],
        suggestions: []
      };
    }
    return {
      id: m.id,
      role: m.role,
      content: parsed.display,
      createTime: m.createTime,
      hasReport: true,
      score: report.score,
      accuracy: report.accuracy,
      depth: report.depth,
      expression: report.expression,
      advantages: report.advantages,
      problems: report.problems,
      suggestions: report.suggestions
    };
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
          ForEach(this.messages, (m: HistoryBubble) => {
            ListItem() {
              this.historyItem(m)
            }
          }, (m: HistoryBubble) => m.id)
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

  @Builder
  historyItem(m: HistoryBubble) {
    Column({ space: 10 }) {
      if (m.content.length > 0) {
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
      if (m.hasReport) {
        InterviewReportCard({
          report: {
            score: m.score,
            accuracy: m.accuracy,
            depth: m.depth,
            expression: m.expression,
            advantages: m.advantages,
            problems: m.problems,
            suggestions: m.suggestions
          }
        })
      }
    }
    .width('100%')
  }
}
