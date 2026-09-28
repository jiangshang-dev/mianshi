import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { AiStreamSnapshot } from '../../common/models/Types';
import {
  InterviewChatMode,
  InterviewConfig,
  InterviewMessage,
  InterviewReport
} from '../../common/models/InterviewTypes';
import { SseAbort } from '../../common/network/HttpClient';
import { SpeechService } from '../../common/speech/SpeechService';
import { InterviewEngine } from '../../data/interview/InterviewEngine';
import { ResumeInsightBuilder } from '../../data/interview/ResumeInsight';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { InterviewParsedReply, InterviewRepository } from '../../data/repository/InterviewRepository';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { ResumeRepository } from '../../data/repository/ResumeRepository';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { InterviewReportCard } from '../../components/InterviewReportCard';
import { I18n } from '../../common/i18n/I18n';
import { AiGenMark, AiDisclaimerBar } from '../../components/AiGenMark';
import { MemberBadge } from '../../components/MemberBadge';

interface SessionRouteParams {
  role?: string;
  level?: string;
  difficulty?: string;
}

/**
 * AI面试官
 */
@Entry
@Component
struct InterviewSessionPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private mode: InterviewChatMode = 'text';
  @State private messages: InterviewMessage[] = [];
  @State private inputText: string = '';
  @State private voiceTranscript: string = '';
  @State private voiceStatus: string = '点麦克风回答';
  @State private isRecording: boolean = false;
  @State private isSpeaking: boolean = false;
  @State private voiceMuted: boolean = false;
  @State private speechReady: boolean = false;
  @State private micReady: boolean = false;
  @State private elapsedSeconds: number = 0;
  @State private showReport: boolean = false;
  @State private report: InterviewReport | null = null;
  @State private sessionTitle: string = '模拟面试';
  @State private waitingAnswer: boolean = false;
  @State private streaming: boolean = false;
  @State private openingSpoken: boolean = false;
  @State private trackHint: string = '结合岗位与简历提问';

  private engine: InterviewEngine | null = null;
  private config: InterviewConfig | null = null;
  private repo: InterviewRepository = InterviewRepository.getInstance();
  private speech: SpeechService = SpeechService.getInstance();
  private timerHandle: number = -1;
  private speakTimer: number = -1;
  private scroller: Scroller = new Scroller();
  private aiSessionId: string = '';
  private streamBubbleId: string = '';
  private aiAbort: SseAbort | null = null;

  aboutToAppear(): void {
    this.startTimer();
    this.initSpeech();
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      router.back();
      LoginGate.goLogin();
      return;
    }
    const params = router.getParams() as SessionRouteParams;
    const ctx = getContext(this) as common.UIAbilityContext;
    const resume = await ResumeRepository.getInstance().load(ctx);
    const insight = ResumeInsightBuilder.from(resume);
    const role = params.role ?? insight.role;
    const level = params.level ?? insight.level;
    const config: InterviewConfig = {
      role: role,
      level: level,
      difficulty: params.difficulty ?? '中等',
      resumeId: resume !== null ? resume.resumeId : '',
      resumePreview: InterviewSessionPage.resumeBody(resume),
      resumeFileName: resume !== null ? resume.fileName : '',
      focus: ResumeInsightBuilder.modulesOf(resume, role).join('、'),
      interviewerTitle: ResumeInsightBuilder.interviewerOf(role)
    };
    this.config = config;
    this.sessionTitle = config.resumeFileName.length > 0 ?
      `${config.role} · 已关联简历` : `${config.role} · ${config.level}`;
    this.trackHint = `${config.interviewerTitle} · ${config.focus}`;
    this.engine = new InterviewEngine(config);
    await this.beginInterview();
  }

  aboutToDisappear(): void {
    this.stopTimer();
    this.clearSpeakTimer();
    this.aiAbort?.abort();
    this.speech.release();
  }

  private startTimer(): void {
    this.timerHandle = setInterval(() => {
      this.elapsedSeconds++;
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timerHandle >= 0) {
      clearInterval(this.timerHandle);
      this.timerHandle = -1;
    }
  }

  private clearSpeakTimer(): void {
    if (this.speakTimer >= 0) {
      clearTimeout(this.speakTimer);
      this.speakTimer = -1;
    }
  }

  private async initSpeech(): Promise<void> {
    const ttsOk = await this.speech.initTts();
    this.speechReady = ttsOk;
    const ctx = getContext(this) as common.UIAbilityContext;
    const micOk = await this.speech.requestMicPermission(ctx);
    const asrOk = await this.speech.initAsr(
      (text: string, isLast: boolean) => {
        setTimeout(() => {
          if (!this.isRecording) {
            return;
          }
          this.voiceTranscript = text;
          if (isLast && text.trim().length > 0) {
            this.isRecording = false;
            this.voiceStatus = '识别完成，正在交给面试官…';
            this.submitAnswer(text);
          }
        }, 0);
      },
      (message: string) => {
        setTimeout(() => {
          if (!this.isRecording) {
            return;
          }
          this.isRecording = false;
          this.voiceStatus = message;
          promptAction.showToast({ message });
        }, 0);
      }
    );
    this.micReady = micOk && asrOk;
    if (!this.micReady) {
      this.voiceStatus = '麦克风不可用，可以改用文字聊天';
    } else if (!this.speechReady) {
      this.voiceStatus = '点麦克风回答。本机暂不能朗读题目';
    } else {
      this.voiceStatus = '点麦克风回答';
    }
  }

  private async beginInterview(): Promise<void> {
    this.streaming = true;
    this.waitingAnswer = false;
    const ctx = getContext(this) as common.UIAbilityContext;
    await AuthRepository.getInstance().load(ctx);
    const bubble = this.makeMsg('interviewer', '面试官正在准备开场…');
    this.messages = [bubble];
    this.streamBubbleId = bubble.id;
    this.waitingAnswer = false;
    const parsed = await this.streamAction('start', '');
    if (!parsed) {
      return;
    }
    if (MemberGate.isQuotaError(parsed.display)) {
      const shown = MemberGate.displayMessage(parsed.display);
      this.replaceBubble(this.streamBubbleId, shown);
      this.waitingAnswer = false;
      MemberGate.promptUpgrade(parsed.display);
      return;
    }
    if (InterviewRepository.looksLikeError(parsed.display) && this.engine) {
      const opening = this.engine.getOpening();
      this.replaceBubble(this.streamBubbleId, opening.content);
      this.maybeSpeak(opening.content);
      this.waitingAnswer = true;
      return;
    }
    this.replaceBubble(this.streamBubbleId, parsed.display.length > 0 ? parsed.display : '你好，请先做一下自我介绍。');
    this.applyReport(parsed);
    if (!this.showReport) {
      this.waitingAnswer = true;
      this.maybeSpeak(parsed.spoken);
    }
  }

  private async streamAction(action: string, message: string): Promise<InterviewParsedReply | null> {
    if (!this.config) {
      return null;
    }
    this.streaming = true;
    const abort = new SseAbort();
    this.aiAbort = abort;
    try {
      const parsed = await this.repo.streamTurn({
        sessionId: this.aiSessionId,
        action: action,
        message: message,
        config: this.config
      }, (snap: AiStreamSnapshot) => {
        if (!abort.stopped) {
          this.applyStream(snap);
        }
      }, abort);
      if (abort.stopped) {
        return null;
      }
      if (parsed.sessionId.length > 0) {
        this.aiSessionId = parsed.sessionId;
      }
      return parsed;
    } catch (_e) {
      if (abort.stopped) {
        return null;
      }
      return {
        spoken: 'AI 服务暂时不可用，请稍后重试。',
        display: 'AI 服务暂时不可用，请稍后重试。',
        report: null,
        sessionId: this.aiSessionId
      };
    } finally {
      if (this.aiAbort === abort) {
        this.aiAbort = null;
      }
      this.streaming = false;
    }
  }

  /** 对齐题目 AI：改最后一条面试官气泡，ForEach key 必须带 content.length 才会重绘 */
  private applyStream(snap: AiStreamSnapshot): void {
    if (snap.sessionId.length > 0) {
      this.aiSessionId = snap.sessionId;
    }
    if (this.messages.length === 0) {
      return;
    }
    let idx = -1;
    for (let i = this.messages.length - 1; i >= 0; i--) {
      if (this.messages[i].role === 'interviewer') {
        idx = i;
        break;
      }
    }
    if (idx < 0) {
      return;
    }
    let content = this.messages[idx].content;
    if (snap.markdown.length > 0) {
      const parsed = InterviewRepository.parseReply(snap.markdown, snap.sessionId);
      content = parsed.display.length > 0 ? parsed.display : snap.markdown;
    } else if (snap.phase === 'thinking' || snap.thinking.length > 0) {
      content = '面试官正在思考…';
    }
    this.patchInterviewer(idx, content);
    this.scroller.scrollEdge(Edge.Bottom);
  }

  private patchInterviewer(idx: number, content: string): void {
    const list = this.messages.slice();
    const old = list[idx];
    list[idx] = {
      id: old.id,
      role: old.role,
      content: content,
      time: old.time
    };
    this.messages = list;
  }

  private applyReport(parsed: InterviewParsedReply): void {
    if (!parsed.report) {
      return;
    }
    this.stopTimer();
    this.report = parsed.report;
    this.showReport = true;
    this.waitingAnswer = false;
    this.speech.stopSpeak();
    this.clearSpeakTimer();
    this.isSpeaking = false;
    this.isRecording = false;
  }

  private maybeSpeak(text: string): void {
    if (this.mode !== 'voice' || this.voiceMuted || !this.speechReady) {
      return;
    }
    if (text.length === 0 || text.indexOf('正在思考') >= 0 || text.indexOf('正在准备') >= 0) {
      return;
    }
    this.openingSpoken = true;
    this.playVoiceReply(text);
  }

  private replaceBubble(id: string, content: string): void {
    const next: InterviewMessage[] = [];
    this.messages.forEach((m: InterviewMessage) => {
      if (m.id === id) {
        next.push({
          id: m.id,
          role: m.role,
          content: content,
          time: m.time
        });
      } else {
        next.push(m);
      }
    });
    this.messages = next;
  }

  private async playVoiceReply(text: string): Promise<void> {
    if (this.voiceMuted || this.mode !== 'voice' || text.trim().length === 0) {
      return;
    }
    this.clearSpeakTimer();
    this.isSpeaking = true;
    this.voiceStatus = '面试官正在朗读，可点静音';
    await this.speech.speak(text);
    const waitMs = Math.min(90000, Math.max(2800, text.length * 160));
    this.speakTimer = setTimeout(() => {
      this.isSpeaking = false;
      if (!this.showReport && !this.voiceMuted && !this.isRecording) {
        this.voiceStatus = this.waitingAnswer ? '轮到你了，点麦克风回答' : '点麦克风回答';
      }
    }, waitMs);
  }

  private async stopVoicePlayback(): Promise<void> {
    this.clearSpeakTimer();
    await this.speech.stopSpeak();
    this.isSpeaking = false;
  }

  private async toggleMute(): Promise<void> {
    this.voiceMuted = !this.voiceMuted;
    if (this.voiceMuted) {
      await this.stopVoicePlayback();
      this.voiceStatus = '已静音，面试官不再朗读';
      promptAction.showToast({ message: I18n.t('tts_off', this.lang) });
    } else {
      this.voiceStatus = this.waitingAnswer ? '轮到你了，点麦克风回答' : '已开启朗读';
      promptAction.showToast({ message: I18n.t('tts_on', this.lang) });
    }
  }

  private submitAnswer(answer: string): void {
    const text = answer.trim();
    if (text.length === 0) {
      promptAction.showToast({ message: I18n.t('need_answer', this.lang) });
      return;
    }
    if (this.streaming || this.showReport || !this.waitingAnswer) {
      return;
    }
    this.inputText = '';
    this.voiceTranscript = '';
    this.runTurn('chat', text, true);
  }

  private async endInterview(): Promise<void> {
    if (this.streaming || this.showReport) {
      return;
    }
    this.isRecording = false;
    await this.speech.stopListening();
    await this.stopVoicePlayback();
    this.runTurn('finish', '', false);
  }

  private async runTurn(action: string, text: string, appendCandidate: boolean): Promise<void> {
    this.waitingAnswer = false;
    const next: InterviewMessage[] = [];
    this.messages.forEach((m: InterviewMessage) => next.push(m));
    if (appendCandidate) {
      next.push(this.makeMsg('candidate', text));
    }
    const bubble = this.makeMsg('interviewer', '面试官正在思考…');
    next.push(bubble);
    this.messages = next;
    this.streamBubbleId = bubble.id;
    this.scroller.scrollEdge(Edge.Bottom);

    const parsed = await this.streamAction(action, text);
    if (!parsed) {
      this.waitingAnswer = !this.showReport;
      return;
    }
    if (MemberGate.isQuotaError(parsed.display)) {
      this.replaceBubble(this.streamBubbleId, MemberGate.displayMessage(parsed.display));
      this.waitingAnswer = false;
      MemberGate.promptUpgrade(parsed.display);
      return;
    }
    if (InterviewRepository.looksLikeError(parsed.display)) {
      const engine = this.engine;
      if (engine && appendCandidate) {
        const replies = engine.submitAnswer(text);
        const fallback: string[] = [];
        replies.forEach((m: InterviewMessage) => {
          if (m.role === 'interviewer') {
            fallback.push(m.content);
          }
        });
        const joined = fallback.join('\n\n');
        this.replaceBubble(this.streamBubbleId, joined.length > 0 ? joined : '面试官暂时无法回复，请稍后重试。');
        if (engine.isFinished()) {
          this.stopTimer();
          this.report = engine.getReport();
          this.showReport = true;
          this.waitingAnswer = false;
          return;
        }
        this.waitingAnswer = true;
        this.maybeSpeak(joined);
        return;
      }
      if (engine && action === 'finish') {
        this.replaceBubble(this.streamBubbleId, '本场模拟面试先告一段落，下面是参考报告。');
        this.stopTimer();
        this.report = engine.getReport();
        this.showReport = true;
        this.waitingAnswer = false;
        return;
      }
    }
    const display = parsed.display.length > 0 ? parsed.display : '请继续作答。';
    this.replaceBubble(this.streamBubbleId, display);
    this.applyReport(parsed);
    if (action === 'finish' && !this.showReport && this.engine) {
      this.stopTimer();
      this.report = this.engine.getReport();
      this.showReport = true;
      this.waitingAnswer = false;
      this.speech.stopSpeak();
      this.isSpeaking = false;
    }
    if (!this.showReport) {
      this.waitingAnswer = true;
      this.maybeSpeak(parsed.spoken.length > 0 ? parsed.spoken : display);
    } else {
      this.voiceStatus = '本场结束，下面是综合评分';
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  private async toggleRecording(): Promise<void> {
    if (!this.micReady) {
      promptAction.showToast({ message: I18n.t('voice_unavail', this.lang) });
      return;
    }
    if (this.streaming || !this.waitingAnswer || this.showReport) {
      promptAction.showToast({ message: I18n.t('wait_reply', this.lang) });
      return;
    }
    if (this.isSpeaking) {
      await this.stopVoicePlayback();
    }
    if (this.isRecording) {
      const heard = this.voiceTranscript.trim();
      this.isRecording = false;
      await this.speech.stopListening();
      if (heard.length > 0) {
        this.voiceStatus = '识别完成，正在交给面试官…';
        this.submitAnswer(heard);
      } else {
        this.voiceStatus = '没有听清，请再点一次麦克风';
      }
      return;
    }
    this.voiceTranscript = '';
    const ok = await this.speech.startListening();
    if (ok) {
      this.isRecording = true;
      this.voiceStatus = '正在听你的回答…';
    } else {
      promptAction.showToast({ message: I18n.t('asr_fail', this.lang) });
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
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(I18n.t('mock_iv', this.lang))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            MemberBadge({ tapToOpen: false })
          }
          Text(this.sessionTitle)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // if (this.mode === 'voice') {
        //   Text(this.voiceMuted ? '🔇' : '🔊')
        //     .fontSize(18)
        //     .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        //     .backgroundColor(this.voiceMuted ? $r('app.color.chip_idle_bg') : $r('app.color.bubble_mine_bg'))
        //     .borderRadius(10)
        //     .onClick(() => {
        //       this.toggleMute();
        //     })
        // }

        Text(this.formatTime(this.elapsedSeconds))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#EFF6FF')
          .borderRadius(10)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      AiDisclaimerBar({ shortText: true })
        .padding({ left: 16, right: 16, bottom: 6 })

      //  todo 语音Tab
      Row({ space: 8 }) {
        this.modeTab('mode_text', 'text')
        this.modeTab('mode_voice', 'voice')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (!this.showReport) {
        Row() {
          Text(this.streaming ? I18n.t('replying', this.lang) : this.trackHint)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ right: 12 })
          Text(I18n.t('end_iv', this.lang))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.streaming ? $r('app.color.text_muted') : '#DC2626')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.streaming ? $r('app.color.chip_idle_bg') : '#FEF2F2')
            .borderRadius(8)
            .onClick(() => {
              if (!this.streaming) {
                this.endInterview();
              }
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 16, right: 16, top: 2, bottom: 8 })
      }

      List({ space: 12, scroller: this.scroller }) {
        ForEach(this.messages, (msg: InterviewMessage) => {
          ListItem() {
            this.messageBubble(msg)
          }
        }, (msg: InterviewMessage) => `${msg.id}-${msg.content.length}`)

        if (this.showReport && this.report) {
          ListItem() {
            InterviewReportCard({ report: this.report })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      if (!this.showReport) {
        if (this.mode === 'text') {
          Row({ space: 8 }) {
            TextInput({ placeholder: I18n.t('input_ans', this.lang), text: this.inputText })
              .layoutWeight(1)
              .height(42)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .enabled(!this.streaming)
              .onChange((v: string) => {
                this.inputText = v;
              })
              .onSubmit(() => {
                this.submitAnswer(this.inputText);
              })
            Button(I18n.t('send', this.lang))
              .height(42)
              .backgroundColor(this.streaming ? '#93C5FD' : '#2563EB')
              .enabled(!this.streaming)
              .onClick(() => {
                this.submitAnswer(this.inputText);
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        } else {
          this.voiceDock()
        }
      } else {
        Button(I18n.t('back_iv', this.lang))
          .width('90%')
          .height(44)
          .backgroundColor('#2563EB')
          .margin({ bottom: 20 })
          .onClick(() => router.back())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  private voiceDock() {
    Column({ space: 12 }) {
      Text(this.voiceStatus)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isRecording ? '#DC2626' : '#1F2430')
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.voiceTranscript.length > 0) {
        Text(this.voiceTranscript)
          .fontSize(14)
          .fontColor('#1F2430')
          .width('100%')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding(12)
          .backgroundColor('#F4F7FF')
          .borderRadius(12)
      }

      Row() {
        Column({ space: 6 }) {
          Text(this.voiceMuted ? '静' : '读')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.voiceMuted ? '#6B7280' : '#2563EB')
          Text(this.voiceMuted ? I18n.t('muted', this.lang) : I18n.t('mute', this.lang))
            .fontSize(11)
            .fontColor($r('app.color.text_muted'))
        }
        .width(64)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.voiceMuted ? '#F3F4F6' : '#EFF6FF')
        .borderRadius(16)
        .onClick(() => {
          this.toggleMute();
        })

        Blank().layoutWeight(1)

        Column() {
          if (this.isRecording) {
            Column()
              .width(18)
              .height(18)
              .borderRadius(4)
              .backgroundColor(Color.White)
          } else {
            this.micMark()
          }
        }
        .width(76)
        .height(76)
        .borderRadius(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isRecording ? '#EF4444' : (this.micReady && this.waitingAnswer && !this.streaming ? '#2563EB' : '#CBD5E1'))
        .shadow({ radius: 16, color: '#2563EB33', offsetY: 6 })
        .onClick(() => {
          this.toggleRecording();
        })

        Blank().layoutWeight(1)

        Column({ space: 6 }) {
          Text('停')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.streaming ? '#9CA3AF' : '#DC2626')
          Text(I18n.t('end_iv', this.lang))
            .fontSize(11)
            .fontColor(this.streaming ? '#9CA3AF' : '#DC2626')
        }
        .width(72)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.streaming ? '#F3F4F6' : '#FEF2F2')
        .borderRadius(16)
        .onClick(() => {
          if (!this.streaming) {
            this.endInterview();
          }
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.isRecording ? '再说完后点红色按钮提交。结束面试后会给出综合评分' :
        '按当前简历出题。回答结束后点「结束面试」，查看综合评分')
        .fontSize(12)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .lineHeight(18)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 18 })
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  private micMark() {
    Column() {
      Column()
        .width(16)
        .height(24)
        .borderRadius(8)
        .border({ width: 2, color: Color.White })
      Column()
        .width(2)
        .height(8)
        .backgroundColor(Color.White)
        .margin({ top: 2 })
      Row()
        .width(12)
        .height(2)
        .borderRadius(1)
        .backgroundColor(Color.White)
    }
  }

  @Builder
  modeTab(labelKey: string, value: InterviewChatMode) {
    Text(I18n.t(labelKey, this.lang))
      .fontSize(14)
      .fontColor(this.mode === value ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
      .backgroundColor(this.mode === value ? $r('app.color.accent') : $r('app.color.card_bg'))
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .borderRadius(20)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.mode = value;
        if (value === 'voice') {
          this.speakLastInterviewerIfNeeded();
        } else {
          this.stopVoicePlayback();
        }
      })
  }

  private speakLastInterviewerIfNeeded(): void {
    if (this.openingSpoken || this.voiceMuted || !this.speechReady || this.streaming) {
      return;
    }
    for (let i = this.messages.length - 1; i >= 0; i--) {
      const msg = this.messages[i];
      if (msg.role === 'interviewer' && msg.content.indexOf('正在思考') < 0 &&
        msg.content.indexOf('正在准备') < 0) {
        this.maybeSpeak(msg.content);
        return;
      }
    }
  }

  @Builder
  messageBubble(msg: InterviewMessage) {
    if (msg.role === 'system') {
      Text(msg.content)
        .fontSize(12)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 4, bottom: 4 })
    } else {
      Row() {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(msg.role === 'interviewer' ? I18n.t('role_iv', this.lang) : I18n.t('me', this.lang))
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
            if (msg.role === 'interviewer') {
              AiGenMark()
            }
          }
          .width('100%')
          .justifyContent(msg.role === 'candidate' ? FlexAlign.End : FlexAlign.Start)
          Text(msg.content)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
            .padding(12)
            .backgroundColor(msg.role === 'candidate' ? $r('app.color.bubble_mine_bg') : $r('app.color.card_bg'))
            .borderRadius(12)
            .constraintSize({ maxWidth: '82%' })
          Text(msg.time)
            .fontSize(10)
            .fontColor('#D1D5DB')
            .width('100%')
            .textAlign(msg.role === 'candidate' ? TextAlign.End : TextAlign.Start)
        }
        .alignItems(msg.role === 'candidate' ? HorizontalAlign.End : HorizontalAlign.Start)
      }
      .width('100%')
      .justifyContent(msg.role === 'candidate' ? FlexAlign.End : FlexAlign.Start)
    }
  }

  private makeMsg(role: 'interviewer' | 'candidate' | 'system', content: string): InterviewMessage {
    const now = new Date();
    const hh = now.getHours().toString().padStart(2, '0');
    const mm = now.getMinutes().toString().padStart(2, '0');
    return {
      id: `${Date.now()}-${Math.random()}`,
      role: role,
      content: content,
      time: `${hh}:${mm}`
    };
  }

  private static resumeBody(resume: ResumeProfile | null): string {
    if (resume === null) {
      return '';
    }
    const text = resume.textContent.length > 0 ? resume.textContent : '';
    if (text.length < 40) {
      return '';
    }
    if (text.indexOf('服务端将解析') >= 0 || text.indexOf('没有解析出简历正文') >= 0 || text.indexOf('扫描件') >= 0) {
      return '';
    }
    return text;
  }

  private formatTime(seconds: number): string {
    const mm = Math.floor(seconds / 60).toString().padStart(2, '0');
    const ss = (seconds % 60).toString().padStart(2, '0');
    return `${mm}:${ss}`;
  }
}
