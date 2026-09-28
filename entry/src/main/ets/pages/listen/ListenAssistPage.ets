import { common } from '@kit.AbilityKit';
import { promptAction, router, window } from '@kit.ArkUI';
import { AiStreamSnapshot } from '../../common/models/Types';
import { SseAbort } from '../../common/network/HttpClient';
import { SpeechService } from '../../common/speech/SpeechService';
import { QuestionSegmenter } from '../../data/listen/QuestionSegmenter';
import { ListenRepository } from '../../data/repository/ListenRepository';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { AiNotice } from '../../common/utils/AiNotice';
import { AiDisclaimerBar, AiGenMark } from '../../components/AiGenMark';

/**
 * AI 辅助面试：只听面试官，屏幕上写「你可以这样说」。
 * 不进入模拟面试页，不打分。
 */
@Entry
@Component
struct ListenAssistPage {
  @State private statusText: string = '把手机放在电脑旁，听面试官提问';
  @State private draft: string = '';
  @State private question: string = '';
  @State private answer: string = '';
  @State private sourceLabel: string = '';
  @State private paste: string = '';
  @State private hearing: boolean = false;
  @State private busy: boolean = false;
  @State private resumeHint: string = '';

  private speech: SpeechService = SpeechService.getInstance();
  private repo: ListenRepository = ListenRepository.getInstance();
  private segmenter: QuestionSegmenter = new QuestionSegmenter();
  private sessionId: string = '';
  private seq: number = 0;
  private abort: SseAbort | null = null;
  private stableTimer: number = -1;

  aboutToAppear(): void {
    if (!LoginGate.isLoggedIn()) {
      router.back();
      LoginGate.goLogin();
      return;
    }
    this.prepare();
  }

  aboutToDisappear(): void {
    this.clearStable();
    this.abort?.abort();
    this.speech.stopContinuous();
    this.speech.release();
    this.keepScreen(false);
  }

  private async prepare(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const resume = await ResumeRepository.getInstance().load(ctx);
    this.resumeHint = resume !== null && resume.fileName.length > 0 ? `已带上简历 ${resume.fileName}` : '未关联简历，按面试官原话作答';
    this.keepScreen(true);
    this.sessionId = await this.repo.openSession();
    if (this.sessionId.length === 0) {
      this.statusText = '会话没打开，确认已执行 aifuzhu.sql 且服务已重启';
    }
  }

  private async keepScreen(on: boolean): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = await window.getLastWindow(ctx);
      await win.setWindowKeepScreenOn(on);
    } catch (_e) {
    }
  }

  private async startHear(): Promise<void> {
    if (this.sessionId.length === 0) {
      this.statusText = '会话未就绪';
      return;
    }
    const ctx = getContext(this) as common.UIAbilityContext;
    AiNotice.ensure(ctx, () => {
      this.grantAndListen(ctx);
    });
  }

  private async grantAndListen(ctx: common.UIAbilityContext): Promise<void> {
    const micOk = await this.speech.requestMicPermission(ctx);
    if (!micOk) {
      this.statusText = '没有麦克风权限，可以把面试官的话粘贴到下面';
      return;
    }
    const ok = await this.speech.beginContinuous(
      (text: string, isLast: boolean) => {
        this.draft = text;
        this.scheduleCommit(isLast);
      },
      (message: string) => {
        this.hearing = false;
        this.statusText = message;
      }
    );
    this.hearing = ok;
    this.statusText = ok ? '正在听面试官' : '这台设备不能听写，请粘贴面试官原话';
  }

  private async stopHear(): Promise<void> {
    this.clearStable();
    await this.speech.stopContinuous();
    this.hearing = false;
    this.statusText = '已停止';
  }

  private scheduleCommit(isLast: boolean): void {
    this.clearStable();
    const wait = isLast ? 200 : 700;
    this.stableTimer = setTimeout(() => {
      this.stableTimer = -1;
      this.commit(this.draft, false);
    }, wait);
  }

  private clearStable(): void {
    if (this.stableTimer >= 0) {
      clearTimeout(this.stableTimer);
      this.stableTimer = -1;
    }
  }

  private commit(raw: string, force: boolean): void {
    if (this.busy && !force) {
      return;
    }
    const text = this.segmenter.tryCommit(raw, this.answer, force);
    if (text.length === 0) {
      return;
    }
    this.ask(text, false);
  }

  private async ask(questionText: string, forceLlm: boolean): Promise<void> {
    if (this.sessionId.length === 0 || questionText.trim().length === 0) {
      return;
    }
    this.abort?.abort();
    this.abort = new SseAbort();
    this.seq++;
    const turnId = `${Date.now()}-${this.seq}`;
    this.question = questionText;
    this.answer = '';
    this.sourceLabel = forceLlm ? 'AI 生成' : '正在组织说法';
    this.busy = true;
    this.statusText = '正在组织说法';
    const current = this.abort;
    await this.repo.streamTurn(this.sessionId, turnId, this.seq, questionText, forceLlm, (snap: AiStreamSnapshot) => {
      if (snap.markdown.length > 0) {
        this.answer = snap.markdown;
      }
      if (snap.phase === 'error' && MemberGate.isQuotaError(snap.markdown)) {
        this.answer = MemberGate.displayMessage(snap.markdown);
        MemberGate.promptUpgrade(snap.markdown);
      }
    }, current);
    if (this.answer.length === 0) {
      this.answer = '没有生成答法，可点「换一种说法」或检查网络';
    }
    if (this.sourceLabel === '正在组织说法') {
      this.sourceLabel = '你可以这样说';
    }
    this.busy = false;
    this.segmenter.hold(2500);
    if (this.hearing) {
      this.statusText = '正在听面试官';
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(22)
          .width(36)
          .onClick(() => router.back())
        Text('AI辅助面试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.hearing ? '停止' : '听面试官')
          .fontSize(14)
          .fontColor('#2563EB')
          .onClick(() => {
            if (this.hearing) {
              this.stopHear();
            } else {
              this.startHear();
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 12, bottom: 8 })

      Text(this.statusText)
        .fontSize(13)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .padding({ left: 16, right: 16 })
      Text(this.resumeHint)
        .fontSize(12)
        .fontColor($r('app.color.accent'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 4 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 8 }) {
            Text('面试官')
              .fontSize(13)
              .fontColor($r('app.color.text_muted'))
            Text(this.question.length > 0 ? this.question : (this.draft.length > 0 ? this.draft : '等待面试官提问'))
              .fontSize(16)
              .fontColor(this.question.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_muted'))
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Column({ space: 8 }) {
            Row({ space: 6 }) {
              Text('你可以这样说')
                .fontSize(13)
                .fontColor($r('app.color.text_muted'))
                .layoutWeight(1)
              Text(this.sourceLabel)
                .fontSize(12)
                .fontColor($r('app.color.accent'))
            }
            .width('100%')
            Text(this.answer.length > 0 ? this.answer : '答法会出现在这里，照着说即可')
              .fontSize(16)
              .lineHeight(24)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            Row({ space: 6 }) {
              AiGenMark()
              Text('辅助口述，请用自己的话讲')
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
            }
            AiDisclaimerBar()
            if (this.question.length > 0) {
              Text('换一种说法')
                .fontSize(13)
                .fontColor('#2563EB')
                .onClick(() => this.ask(this.question, true))
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          TextInput({ text: this.paste, placeholder: '听不清时，把面试官的话粘贴到这里' })
            .width('100%')
            .onChange((value: string) => {
              this.paste = value;
            })
          Button('按这句出答案')
            .width('100%')
            .height(40)
            .backgroundColor('#2563EB')
            .onClick(() => {
              const text = this.paste.trim();
              if (text.length === 0) {
                promptAction.showToast({ message: '先贴上面试官的问题' });
                return;
              }
              this.segmenter.clearHold();
              this.ask(text, false);
            })
          Button('听下一题')
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.chip_idle_bg'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => {
              this.segmenter.clearHold();
              this.draft = '';
              this.statusText = this.hearing ? '正在听面试官' : '点右上角开始听';
            })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
