import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
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
import { AiDisclaimerBar } from '../../components/AiGenMark';

/**
 * AI 辅助面试：聆听页、回答建议、追问预测。
 * 只听面试官，不进入模拟面试，不打分。
 */
@Entry
@Component
struct ListenAssistPage {
  @State private notice: string = '';
  @State private draft: string = '';
  @State private question: string = '';
  @State private answer: string = '';
  @State private paste: string = '';
  @State private hearing: boolean = false;
  @State private busy: boolean = false;
  @State private resumeHint: string = '';
  @State private tab: number = 0;
  @State private showTools: boolean = false;
  @State private questionClock: string = '';
  @State private elapsedSec: number = 0;
  @State private follows: string[] = [];
  @State private points: string[] = [];
  @State private followBusy: boolean = false;

  private speech: SpeechService = SpeechService.getInstance();
  private repo: ListenRepository = ListenRepository.getInstance();
  private segmenter: QuestionSegmenter = new QuestionSegmenter();
  private sessionId: string = '';
  private seq: number = 0;
  private abort: SseAbort | null = null;
  private abortFollow: SseAbort | null = null;
  private pendingRaw: string = '';
  private stableTimer: number = -1;
  private clockTimer: number = -1;
  private questionAt: number = 0;

  aboutToAppear(): void {
    if (!LoginGate.isLoggedIn()) {
      router.back();
      LoginGate.goLogin();
      return;
    }
    this.clockTimer = setInterval(() => {
      if (this.questionAt > 0) {
        this.elapsedSec = Math.floor((Date.now() - this.questionAt) / 1000);
      }
    }, 1000);
    this.prepare();
  }

  aboutToDisappear(): void {
    this.clearStable();
    if (this.clockTimer >= 0) {
      clearInterval(this.clockTimer);
      this.clockTimer = -1;
    }
    this.abort?.abort();
    this.abortFollow?.abort();
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
      this.notice = '会话没打开，确认已执行 aifuzhu.sql 且服务已重启';
      return;
    }
    this.startHear();
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
      this.notice = '会话未就绪';
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
      this.notice = '没有麦克风权限，可点右上角粘贴面试官的话';
      return;
    }
    const ok = await this.speech.beginContinuous(
      (text: string, isLast: boolean) => {
        setTimeout(() => {
          this.draft = text;
          this.scheduleCommit(isLast);
        }, 0);
      },
      (message: string) => {
        setTimeout(() => {
          this.hearing = false;
          this.notice = message;
        }, 0);
      }
    );
    this.hearing = ok;
    if (ok) {
      this.notice = '';
    }
  }

  private async finishAssist(): Promise<void> {
    this.clearStable();
    await this.speech.stopContinuous();
    this.hearing = false;
    router.back();
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
      this.pendingRaw = raw;
      return;
    }
    const text = this.segmenter.tryCommit(raw, this.answer, force);
    if (text.length === 0) {
      return;
    }
    this.pendingRaw = '';
    this.ask(text, false);
  }

  private async ask(questionText: string, forceLlm: boolean): Promise<void> {
    if (this.sessionId.length === 0 || questionText.trim().length === 0) {
      return;
    }
    this.abort?.abort();
    this.abortFollow?.abort();
    this.abort = new SseAbort();
    this.seq++;
    const turnId = `${Date.now()}-${this.seq}`;
    const changed = this.question !== questionText;
    this.question = questionText;
    this.answer = '';
    this.follows = [];
    this.points = [];
    this.followBusy = false;
    if (changed) {
      this.questionAt = Date.now();
      this.elapsedSec = 0;
      this.questionClock = this.formatClock(this.questionAt);
      this.tab = 0;
    }
    this.busy = true;
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
      this.answer = '没有生成答法，可点「详细回答」重试，或检查网络';
    }
    this.busy = false;
    this.segmenter.hold(2500);
    const pending = this.pendingRaw;
    this.pendingRaw = '';
    if (pending.length > 0 && pending !== questionText) {
      this.commit(pending, false);
    }
    if (this.tab === 2) {
      this.fetchFollows();
    }
  }

  private async fetchFollows(): Promise<void> {
    if (this.sessionId.length === 0 || this.question.length === 0 || this.followBusy) {
      return;
    }
    this.followBusy = true;
    this.abortFollow?.abort();
    this.abortFollow = new SseAbort();
    this.seq++;
    const turnId = `follow-${Date.now()}-${this.seq}`;
    const asked = this.question;
    const prompt = `不要回答这道题。面试官问题是：${asked}。请只输出 8 行。前 5 行每行一个追问，以「追问」开头。后 3 行每行一个知识点名称，以「知识点」开头。`;
    const current = this.abortFollow;
    await this.repo.streamTurn(this.sessionId, turnId, this.seq, prompt, true, (snap: AiStreamSnapshot) => {
      if (snap.markdown.length > 0 && this.question === asked) {
        this.applyFollow(snap.markdown);
      }
      if (snap.phase === 'error' && MemberGate.isQuotaError(snap.markdown)) {
        this.notice = MemberGate.displayMessage(snap.markdown);
        MemberGate.promptUpgrade(snap.markdown);
      }
    }, current);
    if (this.question === asked) {
      this.followBusy = false;
    }
  }

  private refreshFollows(): void {
    this.abortFollow?.abort();
    this.followBusy = false;
    this.follows = [];
    this.points = [];
    this.fetchFollows();
  }

  private openFollow(): void {
    this.tab = 2;
    if (this.follows.length === 0 && !this.busy && this.answer.length > 0) {
      this.fetchFollows();
    }
  }

  private askFollow(text: string): void {
    this.showTools = false;
    this.segmenter.clearHold();
    this.tab = 0;
    this.ask(text, false);
  }

  private copyAnswer(): void {
    const text = this.visibleAnswer();
    if (text.length === 0) {
      promptAction.showToast({ message: '还没有可复制的回答' });
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      promptAction.showToast({ message: '已复制回答' });
    }).catch(() => {
      promptAction.showToast({ message: '已复制回答' });
    });
  }

  private submitPaste(): void {
    const text = this.paste.trim();
    if (text.length === 0) {
      promptAction.showToast({ message: '先贴上面试官的问题' });
      return;
    }
    this.showTools = false;
    this.segmenter.clearHold();
    this.ask(text, false);
  }

  private visibleAnswer(): string {
    if (this.tab === 1) {
      return this.plain(this.answer);
    }
    return this.briefOf(this.answer);
  }

  private suggestSeconds(): number {
    const text = this.visibleAnswer();
    if (text.length === 0) {
      return 0;
    }
    let sec = Math.round(text.length / 4);
    if (sec < 20) {
      sec = 20;
    }
    if (sec > 90) {
      sec = 90;
    }
    return sec;
  }

  private elapsedLabel(): string {
    const sec = this.elapsedSec < 0 ? 0 : this.elapsedSec;
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    const mm = m < 10 ? `0${m}` : `${m}`;
    const ss = s < 10 ? `0${s}` : `${s}`;
    return `${mm}:${ss}`;
  }

  private formatClock(ms: number): string {
    const date = new Date(ms);
    const h = date.getHours();
    const m = date.getMinutes();
    const hh = h < 10 ? `0${h}` : `${h}`;
    const mm = m < 10 ? `0${m}` : `${m}`;
    return `${hh}:${mm}`;
  }

  private plain(raw: string): string {
    const stripped = raw.split('**').join('').split('__').join('');
    const lines = stripped.split('\n');
    const out: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      while (line.startsWith('#')) {
        line = line.substring(1).trim();
      }
      out.push(line);
    }
    return out.join('\n').trim();
  }

  private briefOf(full: string): string {
    const text = this.plain(full);
    if (text.length === 0) {
      return '';
    }
    const lines = text.split('\n');
    const kept: string[] = [];
    let bullets = 0;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.length === 0) {
        continue;
      }
      if (this.isBullet(line)) {
        bullets++;
        if (bullets <= 4) {
          kept.push(line);
        }
      } else if (bullets === 0 && kept.length < 2) {
        kept.push(line);
      } else if (bullets > 0) {
        break;
      }
    }
    if (kept.length === 0) {
      return text.length > 180 ? text.substring(0, 180) : text;
    }
    return kept.join('\n');
  }

  private isBullet(line: string): boolean {
    if (line.startsWith('-') || line.startsWith('·') || line.startsWith('•')) {
      return true;
    }
    const code = line.charCodeAt(0);
    return code >= 48 && code <= 57;
  }

  private applyFollow(raw: string): void {
    const lines = this.plain(raw).split('\n');
    const follows: string[] = [];
    const points: string[] = [];
    let mode = 0;
    for (let i = 0; i < lines.length; i++) {
      const line = this.cleanLine(lines[i]);
      if (line.length === 0) {
        continue;
      }
      if (line.indexOf('知识点') >= 0 && line.length <= 16) {
        mode = 2;
        continue;
      }
      if (line.indexOf('追问') >= 0 && line.length <= 16) {
        mode = 1;
        continue;
      }
      if (line.indexOf('追问') === 0) {
        const rest = this.afterLabel(line, '追问');
        if (rest.length > 0 && follows.length < 8) {
          follows.push(rest);
        }
        continue;
      }
      if (line.indexOf('知识点') === 0) {
        const rest = this.afterLabel(line, '知识点');
        if (rest.length > 0 && points.length < 6) {
          points.push(rest);
        }
        continue;
      }
      if (mode === 2 && points.length < 6) {
        points.push(line);
      } else if (mode === 1 && follows.length < 8) {
        follows.push(line);
      } else if (mode === 0 && (line.endsWith('？') || line.endsWith('?')) && follows.length < 8) {
        follows.push(line);
      }
    }
    this.follows = follows;
    this.points = points;
  }

  private afterLabel(line: string, label: string): string {
    let rest = line.substring(label.length).trim();
    while (rest.startsWith('：') || rest.startsWith(':') || rest.startsWith(' ')) {
      rest = rest.substring(1).trim();
    }
    return this.cleanLine(rest);
  }

  private cleanLine(raw: string): string {
    let line = raw.trim();
    while (line.startsWith('-') || line.startsWith('*') || line.startsWith('·') || line.startsWith('•')) {
      line = line.substring(1).trim();
    }
    let i = 0;
    while (i < line.length) {
      const code = line.charCodeAt(i);
      if (code < 48 || code > 57) {
        break;
      }
      i++;
    }
    if (i > 0 && i < line.length) {
      const mark = line.charAt(i);
      if (mark === '.' || mark === '、' || mark === ' ') {
        line = line.substring(i + 1).trim();
      }
    }
    return line;
  }

  private barHeight(base: number): number {
    if (!this.hearing) {
      return base;
    }
    const delta = this.elapsedSec % 2 === 0 ? 6 : -4;
    const h = base + delta;
    return h < 8 ? 8 : h;
  }

  build() {
    Stack() {
      Column() {
        this.header()
        if (this.question.length === 0) {
          this.listenBody()
          this.endButton()
        } else {
          Scroll() {
            Column({ space: 12 }) {
              this.recognizedChip()
              if (this.tab === 2) {
                this.followBody()
              } else {
                this.answerBody()
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 16 })
          }
          .layoutWeight(1)
          .align(Alignment.Top)
          this.bottomBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F6F7FB')

      if (this.showTools) {
        this.toolsSheet()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private header() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor('#1F2430')
        .width(40)
        .textAlign(TextAlign.Center)
        .onClick(() => this.finishAssist())
      Text('AI 辅助面试')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2430')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('⚙')
        .fontSize(20)
        .fontColor('#1F2430')
        .width(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showTools = true;
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  private listenBody() {
    Column() {
      Blank()
        .layoutWeight(1)
      this.micHero()
      Text(this.hearing ? '正在聆听面试...' : '准备聆听面试')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2430')
        .margin({ top: 28 })
      Text('请将手机放在一旁，AI 会实时识别面试官的问题\n并生成回答建议')
        .fontSize(13)
        .fontColor('#8B93A7')
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .margin({ top: 10 })
      if (this.draft.length > 0) {
        Text(this.draft)
          .fontSize(14)
          .fontColor('#5B4BDB')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 10, left: 12, right: 12 })
      }
      if (this.notice.length > 0) {
        Text(this.notice)
          .fontSize(12)
          .fontColor('#DC2626')
          .textAlign(TextAlign.Center)
          .margin({ top: 8, left: 12, right: 12 })
      }
      this.tipsCard()
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  private micHero() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(250)
        .height(250)
        .radialGradient({
          center: ['50%', '50%'],
          radius: '50%',
          colors: [['#E4DCFF', 0], ['#F6F7FB', 1]]
        })
      Row() {
        this.waveSide(0)
        Column() {
          this.micGlyph()
        }
        .width(118)
        .height(118)
        .borderRadius(59)
        .justifyContent(FlexAlign.Center)
        .linearGradient({ angle: 165, colors: [['#9B8CFF', 0], ['#6A5CFF', 0.55], ['#4C7DFF', 1]] })
        .shadow({ radius: 24, color: '#6A5CFF44', offsetY: 8 })
        .margin({ left: 16, right: 16 })
        this.waveSide(4)
      }
    }
    .width(280)
    .height(220)
  }

  @Builder
  private micGlyph() {
    Column() {
      Column()
        .width(26)
        .height(36)
        .borderRadius(13)
        .border({ width: 2.5, color: Color.White })
      Column()
        .width(2.5)
        .height(12)
        .backgroundColor(Color.White)
        .margin({ top: 2 })
      Row()
        .width(18)
        .height(2.5)
        .borderRadius(2)
        .backgroundColor(Color.White)
    }
  }

  @Builder
  private waveSide(seed: number) {
    Row({ space: 5 }) {
      this.bar(this.barHeight(12 + seed), '#D9CCFF')
      this.bar(this.barHeight(22), '#C0B0FF')
      this.bar(this.barHeight(34), '#8E7CFF')
      this.bar(this.barHeight(18), '#B7A6FF')
      this.bar(this.barHeight(26), '#A594FF')
    }
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private bar(h: number, color: string) {
    Column()
      .width(4)
      .height(h)
      .borderRadius(2)
      .backgroundColor(color)
  }

  @Builder
  private tipsCard() {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        Text('💡')
          .fontSize(16)
        Text('使用提示')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2430')
      }
      .width('100%')
      this.tipRow(1, '保持手机靠近面试环境')
      this.tipRow(2, '在面试官提问结束后，AI 会自动生成答案')
      this.tipRow(3, '可查看精简/详细回答和可能的追问')
      this.tipRow(4, '建议佩戴耳机或放在桌面方便查看')
    }
    .width('100%')
    .padding(16)
    .margin({ top: 28 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 12, color: '#1F24300F', offsetY: 4 })
  }

  @Builder
  private tipRow(index: number, text: string) {
    Row({ space: 10 }) {
      Text(`${index}`)
        .fontSize(12)
        .fontColor(Color.White)
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .borderRadius(10)
        .backgroundColor('#7C6BF2')
      Text(text)
        .fontSize(13)
        .fontColor('#4B5160')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private endButton() {
    Row({ space: 8 }) {
      Column()
        .width(10)
        .height(10)
        .borderRadius(2)
        .backgroundColor(Color.White)
      Text(this.hearing ? '结束辅助面试' : '开始聆听')
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(52)
    .margin({ left: 20, right: 20, bottom: 28 })
    .borderRadius(26)
    .justifyContent(FlexAlign.Center)
    .linearGradient({ angle: 90, colors: [['#FF7A8A', 0], ['#FF4D6A', 1]] })
    .shadow({ radius: 16, color: '#FF4D6A33', offsetY: 6 })
    .onClick(() => {
      if (this.hearing) {
        this.finishAssist();
      } else {
        this.startHear();
      }
    })
  }

  @Builder
  private recognizedChip() {
    Row({ space: 8 }) {
      this.miniWave()
      Text(this.busy ? '正在生成回答建议' : (this.hearing ? '继续聆听下一题' : '已识别面试官问题'))
        .fontSize(13)
        .fontColor('#5B4BDB')
        .layoutWeight(1)
      Text(this.elapsedLabel())
        .fontSize(13)
        .fontColor('#8B93A7')
    }
    .width('100%')
    .height(40)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#F3F0FF')
    .borderRadius(20)
  }

  @Builder
  private miniWave() {
    Row({ space: 2 }) {
      Column().width(2).height(8).borderRadius(1).backgroundColor('#8E7CFF')
      Column().width(2).height(14).borderRadius(1).backgroundColor('#6A5CFF')
      Column().width(2).height(10).borderRadius(1).backgroundColor('#8E7CFF')
    }
    .height(16)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private answerBody() {
    Column({ space: 12 }) {
      this.questionCard(false)
      Column({ space: 12 }) {
        Row() {
          Text('✦')
            .fontSize(14)
            .fontColor('#7C6BF2')
            .margin({ right: 6 })
          Text('AI 回答建议')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2430')
            .layoutWeight(1)
          this.modeChip('精简回答', 0)
          Text('详细回答')
            .fontSize(13)
            .fontColor(this.tab === 1 ? '#5B4BDB' : '#8B93A7')
            .margin({ left: 10 })
            .onClick(() => {
              this.tab = 1;
            })
        }
        .width('100%')

        Text(this.answer.length > 0 ? this.visibleAnswer() : '正在生成回答建议…')
          .fontSize(14)
          .lineHeight(24)
          .fontColor('#2C3340')
          .width('100%')

        Row() {
          Text('◷')
            .fontSize(13)
            .fontColor('#8B93A7')
            .margin({ right: 4 })
          Text(this.suggestSeconds() > 0 ? `建议回答时间：${this.suggestSeconds()} 秒` : '正在估算回答时长')
            .fontSize(12)
            .fontColor('#8B93A7')
            .layoutWeight(1)
          Text('复制')
            .fontSize(13)
            .fontColor('#5B4BDB')
            .onClick(() => this.copyAnswer())
        }
        .width('100%')
        AiDisclaimerBar({ shortText: true })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#1F24300F', offsetY: 4 })

      if (this.notice.length > 0) {
        Text(this.notice)
          .fontSize(12)
          .fontColor('#DC2626')
          .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private followBody() {
    Column({ space: 12 }) {
      this.questionCard(true)
      Row() {
        Text('✓')
          .fontSize(14)
          .fontColor('#22A06B')
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .borderRadius(11)
          .backgroundColor('#DDF6EA')
          .margin({ right: 8 })
        Text(this.answer.length > 0 ? '已为你生成回答建议' : '回答还在生成')
          .fontSize(14)
          .fontColor('#1F2430')
          .layoutWeight(1)
        Text('⌄')
          .fontSize(16)
          .fontColor('#B0B6C3')
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F1FFF7')
      .borderRadius(12)
      .onClick(() => {
        this.tab = 0;
      })

      Column({ space: 4 }) {
        Row() {
          Text('◎')
            .fontSize(14)
            .fontColor('#7C6BF2')
            .margin({ right: 6 })
          Text('面试官可能继续追问')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2430')
            .layoutWeight(1)
          Text('换一批')
            .fontSize(13)
            .fontColor('#5B4BDB')
            .onClick(() => this.refreshFollows())
        }
        .width('100%')
        .margin({ bottom: 6 })

        if (this.followBusy && this.follows.length === 0) {
          Text('正在整理可能的追问…')
            .fontSize(13)
            .fontColor('#8B93A7')
            .padding({ top: 8, bottom: 8 })
        } else if (this.follows.length === 0) {
          Text(this.busy ? '回答生成后会整理追问' : '还没有拆出追问，点「换一批」再试')
            .fontSize(13)
            .fontColor('#8B93A7')
            .padding({ top: 8, bottom: 8 })
        } else {
          ForEach(this.follows, (item: string, index: number) => {
            this.listRow(`${index + 1}`, item, true)
          }, (item: string, index: number) => `f-${index}-${item}`)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 12, color: '#1F24300F', offsetY: 4 })

      if (this.points.length > 0 || this.followBusy) {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text('▤')
              .fontSize(14)
              .fontColor('#3D6BFF')
            Text('相关知识点')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2430')
          }
          .width('100%')
          .margin({ bottom: 6 })
          if (this.points.length === 0) {
            Text('正在整理知识点…')
              .fontSize(13)
              .fontColor('#8B93A7')
              .padding({ top: 8, bottom: 8 })
          } else {
            ForEach(this.points, (item: string, index: number) => {
              this.listRow('', item, false)
            }, (item: string, index: number) => `p-${index}-${item}`)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 12, color: '#1F24300F', offsetY: 4 })
      }
    }
    .width('100%')
  }

  @Builder
  private questionCard(bothTimes: boolean) {
    Column({ space: 8 }) {
      Text('面试官')
        .fontSize(12)
        .fontColor('#8B93A7')
        .width('100%')
      Text(this.question)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2430')
        .width('100%')
      if (this.draft.length > 0 && this.draft !== this.question) {
        Text(this.draft)
          .fontSize(13)
          .fontColor('#5B4BDB')
          .width('100%')
      }
      if (bothTimes) {
        Row() {
          Text(this.questionClock)
            .fontSize(12)
            .fontColor('#B0B6C3')
            .layoutWeight(1)
          Text(this.questionClock)
            .fontSize(12)
            .fontColor('#B0B6C3')
        }
        .width('100%')
      } else {
        Text(this.questionClock)
          .fontSize(12)
          .fontColor('#B0B6C3')
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 12, color: '#1F24300F', offsetY: 4 })
  }

  @Builder
  private modeChip(label: string, index: number) {
    Text(label)
      .fontSize(12)
      .fontColor(this.tab === index ? '#5B4BDB' : '#8B93A7')
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(12)
      .backgroundColor(this.tab === index ? '#EEF0FF' : Color.Transparent)
      .onClick(() => {
        this.tab = index;
      })
  }

  @Builder
  private listRow(badge: string, text: string, numbered: boolean) {
    Row({ space: 10 }) {
      if (numbered) {
        Text(badge)
          .fontSize(12)
          .fontColor('#6D5EF5')
          .width(22)
          .height(22)
          .textAlign(TextAlign.Center)
          .borderRadius(11)
          .backgroundColor('#F3F0FF')
      }
      Text(text)
        .fontSize(14)
        .fontColor('#2C3340')
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('›')
        .fontSize(16)
        .fontColor('#C5CAD6')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => this.askFollow(text))
  }

  @Builder
  private bottomBar() {
    Row({ space: 8 }) {
      this.bottomTab('精简回答', 0, false)
      this.bottomTab('详细回答', 1, false)
      this.bottomTab('追问预测', 2, true)
    }
    .width('100%')
    .padding(6)
    .margin({ left: 16, right: 16, bottom: 18 })
    .backgroundColor(Color.White)
    .borderRadius(28)
    .shadow({ radius: 16, color: '#1F243014', offsetY: 4 })
  }

  @Builder
  private bottomTab(label: string, index: number, primary: boolean) {
    Text(label)
      .fontSize(13)
      .fontWeight(primary || this.tab === index ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(primary ? Color.White : (this.tab === index ? '#3D6BFF' : '#4B5160'))
      .layoutWeight(1)
      .height(40)
      .textAlign(TextAlign.Center)
      .borderRadius(20)
      .backgroundColor(primary ? '#3D6BFF' : (this.tab === index ? '#EEF3FF' : Color.Transparent))
      .onClick(() => {
        if (index === 2) {
          this.openFollow();
        } else {
          this.tab = index;
        }
      })
  }

  @Builder
  private toolsSheet() {
    Column() {
      Column()
        .layoutWeight(1)
        .width('100%')
        .onClick(() => {
          this.showTools = false;
        })
      Column({ space: 12 }) {
        Text('听不清时')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2430')
          .width('100%')
        Text(this.resumeHint)
          .fontSize(12)
          .fontColor('#8B93A7')
          .width('100%')
        TextInput({ text: this.paste, placeholder: '把面试官的话粘贴到这里' })
          .width('100%')
          .onChange((value: string) => {
            this.paste = value;
          })
        Row() {
          Text('按这句出答案')
            .fontSize(15)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(44)
        .borderRadius(22)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#3D6BFF')
        .onClick(() => this.submitPaste())
        if (this.question.length > 0) {
          Text('换一种说法')
            .fontSize(14)
            .fontColor('#5B4BDB')
            .width('100%')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.showTools = false;
              this.ask(this.question, true);
            })
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }
}
