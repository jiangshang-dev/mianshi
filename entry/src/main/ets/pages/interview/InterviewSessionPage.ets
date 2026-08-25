import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import {
  InterviewChatMode,
  InterviewConfig,
  InterviewMessage,
  InterviewReport
} from '../../common/models/InterviewTypes';
import { SpeechService } from '../../common/speech/SpeechService';
import { InterviewEngine } from '../../data/interview/InterviewEngine';

interface SessionRouteParams {
  role?: string;
  level?: string;
  difficulty?: string;
  resumeId?: string;
  resumePreview?: string;
  resumeFileName?: string;
}

@Entry
@Component
struct InterviewSessionPage {
  @State private mode: InterviewChatMode = 'text';
  @State private messages: InterviewMessage[] = [];
  @State private inputText: string = '';
  @State private voiceTranscript: string = '';
  @State private voiceStatus: string = '点击麦克风开始说话';
  @State private isRecording: boolean = false;
  @State private isSpeaking: boolean = false;
  @State private speechReady: boolean = false;
  @State private elapsedSeconds: number = 0;
  @State private showReport: boolean = false;
  @State private report: InterviewReport | null = null;
  @State private sessionTitle: string = '模拟面试';
  @State private waitingAnswer: boolean = false;
  @State private openingSpoken: boolean = false;

  private engine: InterviewEngine | null = null;
  private speech: SpeechService = SpeechService.getInstance();
  private timerHandle: number = -1;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const params = router.getParams() as SessionRouteParams;
    const config: InterviewConfig = {
      role: params.role ?? 'Java 后端',
      level: params.level ?? '1～3 年',
      difficulty: params.difficulty ?? '中等',
      resumeId: params.resumeId ?? '',
      resumePreview: params.resumePreview ?? '',
      resumeFileName: params.resumeFileName ?? ''
    };
    this.sessionTitle = params.resumeFileName && params.resumeFileName.length > 0 ?
      `${config.role} · 已关联简历` : `${config.role} · ${config.level}`;
    this.engine = new InterviewEngine(config);
    const opening = this.engine.getOpening();
    this.messages = [opening];
    this.waitingAnswer = true;
    this.startTimer();
    this.initSpeech();
  }

  aboutToDisappear(): void {
    this.stopTimer();
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

  private async initSpeech(): Promise<void> {
    const ttsOk = await this.speech.initTts();
    const ctx = getContext(this) as common.UIAbilityContext;
    const micOk = await this.speech.requestMicPermission(ctx);
    const asrOk = await this.speech.initAsr(
      (text: string, isLast: boolean) => {
        this.voiceTranscript = text;
        if (isLast && text.trim().length > 0) {
          this.isRecording = false;
          this.voiceStatus = '识别完成，正在提交…';
          this.submitAnswer(text);
        }
      },
      (message: string) => {
        this.isRecording = false;
        this.voiceStatus = message;
        promptAction.showToast({ message });
      }
    );
    this.speechReady = ttsOk && micOk && asrOk;
    if (!this.speechReady) {
      this.voiceStatus = '当前设备语音能力不可用，请使用文字模式';
    } else if (this.mode === 'voice') {
      this.speakOpeningIfNeeded();
    }
  }

  private speakOpeningIfNeeded(): void {
    if (!this.speechReady || this.openingSpoken || this.messages.length === 0) {
      return;
    }
    const opening = this.messages[0];
    if (opening.role === 'interviewer') {
      this.openingSpoken = true;
      this.playVoiceReply(opening.content);
    }
  }

  private appendMessages(list: InterviewMessage[]): void {
    const merged: InterviewMessage[] = [];
    this.messages.forEach((m: InterviewMessage) => merged.push(m));
    list.forEach((m: InterviewMessage) => merged.push(m));
    this.messages = merged;
    this.scroller.scrollEdge(Edge.Bottom);

    const last = list[list.length - 1];
    if (this.mode === 'voice' && last && last.role === 'interviewer' && this.speechReady) {
      this.playVoiceReply(last.content);
    }
    if (this.engine && this.engine.isFinished()) {
      this.stopTimer();
      this.report = this.engine.getReport();
      this.showReport = true;
      this.waitingAnswer = false;
    }
  }

  private async playVoiceReply(text: string): Promise<void> {
    this.isSpeaking = true;
    this.voiceStatus = 'AI 面试官正在说话…';
    await this.speech.speak(text);
    this.isSpeaking = false;
    if (!this.engine?.isFinished()) {
      this.voiceStatus = '点击麦克风开始回答';
    }
  }

  private submitAnswer(answer: string): void {
    if (!this.engine || !this.waitingAnswer) {
      return;
    }
    const replies = this.engine.submitAnswer(answer);
    this.inputText = '';
    this.voiceTranscript = '';
    this.appendMessages(replies);
    if (!this.engine.isFinished()) {
      this.waitingAnswer = true;
      this.voiceStatus = '点击麦克风开始回答';
    }
  }

  private async toggleRecording(): Promise<void> {
    if (!this.speechReady) {
      promptAction.showToast({ message: '语音能力不可用，请切换文字模式' });
      return;
    }
    if (this.isSpeaking) {
      promptAction.showToast({ message: '请等待面试官说完' });
      return;
    }
    if (this.isRecording) {
      await this.speech.stopListening();
      this.isRecording = false;
      this.voiceStatus = '识别结束';
      return;
    }
    this.voiceTranscript = '';
    const ok = await this.speech.startListening();
    if (ok) {
      this.isRecording = true;
      this.voiceStatus = '正在聆听，请作答…';
    } else {
      promptAction.showToast({ message: '无法启动语音识别' });
    }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Column({ space: 2 }) {
          Text('模拟面试')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(this.sessionTitle)
            .fontSize(12)
            .fontColor('#6B7280')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.formatTime(this.elapsedSeconds))
          .fontSize(13)
          .fontColor('#2563EB')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#EFF6FF')
          .borderRadius(10)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 模式切换
      Row({ space: 8 }) {
        this.modeTab('文字聊天', 'text')
        this.modeTab('语音对话', 'voice')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 消息区
      Scroll(this.scroller) {
        Column({ space: 12 }) {
          ForEach(this.messages, (msg: InterviewMessage) => {
            this.messageBubble(msg)
          }, (msg: InterviewMessage) => msg.id)

          if (this.showReport && this.report) {
            this.reportCard(this.report)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部输入区
      if (!this.showReport) {
        if (this.mode === 'text') {
          Row({ space: 8 }) {
            TextInput({ placeholder: '输入你的回答…', text: this.inputText })
              .layoutWeight(1)
              .height(42)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .onChange((v: string) => {
                this.inputText = v;
              })
              .onSubmit(() => {
                this.submitAnswer(this.inputText);
              })
            Button('发送')
              .height(42)
              .backgroundColor('#2563EB')
              .onClick(() => {
                this.submitAnswer(this.inputText);
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        } else {
          Column({ space: 12 }) {
            Text(this.voiceStatus)
              .fontSize(13)
              .fontColor('#6B7280')
              .width('100%')
              .textAlign(TextAlign.Center)

            if (this.voiceTranscript.length > 0) {
              Text(this.voiceTranscript)
                .fontSize(14)
                .fontColor('#111827')
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(12)
            }

            Column() {
              Text(this.isRecording ? '■' : '🎙')
                .fontSize(this.isRecording ? 22 : 28)
                .fontColor(Color.White)
            }
            .width(72)
            .height(72)
            .borderRadius(36)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isRecording ? '#EF4444' : '#2563EB')
            .onClick(() => {
              this.toggleRecording();
            })

            Text(this.isRecording ? '点击结束录音' : '点击开始说话')
              .fontSize(12)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 20 })
        }
      } else {
        Button('返回面试中心')
          .width('90%')
          .height(44)
          .backgroundColor('#2563EB')
          .margin({ bottom: 20 })
          .onClick(() => router.back())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  modeTab(label: string, value: InterviewChatMode) {
    Text(label)
      .fontSize(14)
      .fontColor(this.mode === value ? Color.White : '#374151')
      .backgroundColor(this.mode === value ? '#2563EB' : Color.White)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .borderRadius(20)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.mode = value;
        if (value === 'voice') {
          this.speakOpeningIfNeeded();
        } else if (this.isSpeaking) {
          this.speech.stopSpeak();
          this.isSpeaking = false;
        }
      })
  }

  @Builder
  messageBubble(msg: InterviewMessage) {
    if (msg.role === 'system') {
      Text(msg.content)
        .fontSize(12)
        .fontColor('#9CA3AF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 4, bottom: 4 })
    } else {
      Row() {
        if (msg.role === 'candidate') {
          Blank().layoutWeight(1)
        }
        Column({ space: 4 }) {
          Text(msg.role === 'interviewer' ? '面试官' : '我')
            .fontSize(11)
            .fontColor('#9CA3AF')
            .width('100%')
            .textAlign(msg.role === 'candidate' ? TextAlign.End : TextAlign.Start)
          Text(msg.content)
            .fontSize(14)
            .fontColor('#111827')
            .lineHeight(22)
            .padding(12)
            .backgroundColor(msg.role === 'candidate' ? '#DBEAFE' : Color.White)
            .borderRadius(12)
            .constraintSize({ maxWidth: '82%' })
          Text(msg.time)
            .fontSize(10)
            .fontColor('#D1D5DB')
            .width('100%')
            .textAlign(msg.role === 'candidate' ? TextAlign.End : TextAlign.Start)
        }
        .alignItems(msg.role === 'candidate' ? HorizontalAlign.End : HorizontalAlign.Start)
        if (msg.role === 'interviewer') {
          Blank().layoutWeight(1)
        }
      }
      .width('100%')
    }
  }

  @Builder
  reportCard(r: InterviewReport) {
    Column({ space: 10 }) {
      Text('面试报告')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text(`综合得分 ${r.score}`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2563EB')
        .width('100%')
      Row() {
        this.scoreItem('正确性', r.accuracy)
        this.scoreItem('深度', r.depth)
        this.scoreItem('表达', r.expression)
      }
      .width('100%')
      Text(`优势：${r.advantages.join('；')}`)
        .fontSize(13)
        .fontColor('#374151')
        .width('100%')
      Text(`待提升：${r.problems.join('；')}`)
        .fontSize(13)
        .fontColor('#374151')
        .width('100%')
      Text(`建议：${r.suggestions.join('；')}`)
        .fontSize(13)
        .fontColor('#6B7280')
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

  @Builder
  scoreItem(label: string, value: number) {
    Column({ space: 4 }) {
      Text(`${value}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1E40AF')
      Text(label)
        .fontSize(11)
        .fontColor('#6B7280')
    }
    .layoutWeight(1)
  }

  private formatTime(seconds: number): string {
    const mm = Math.floor(seconds / 60).toString().padStart(2, '0');
    const ss = (seconds % 60).toString().padStart(2, '0');
    return `${mm}:${ss}`;
  }
}
