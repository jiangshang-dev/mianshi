import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { speechRecognizer, textToSpeech } from '@kit.CoreSpeechKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xC0DE;
const SESSION_ID = 'interview-session';
const MIC_PERMISSION = 'ohos.permission.MICROPHONE';
/** writeAudio 只接受 640 或 1280 字节。1280 字节约 40ms（16kHz / 16bit / 单声道）。 */
const PCM_CHUNK = 1280;
/** 会话切换时最多留 2 秒，避免句首被裁掉。 */
const PCM_HOLD = 16000 * 2 * 2;

export type AsrResultCallback = (text: string, isLast: boolean) => void;
export type AsrErrorCallback = (message: string) => void;
/** 只在正在往识别引擎送音时回调。停麦后不再回调，避免录到候选人自己的回答。 */
export type PcmTap = (chunk: Uint8Array) => void;

/** 语音服务：TTS 播报 + ASR 听写（CoreSpeechKit）。听写必须自己采集麦克风再 writeAudio。 */
export class SpeechService {
  private static instance: SpeechService | null = null;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private capturer: audio.AudioCapturer | null = null;
  private ttsReady: boolean = false;
  private asrReady: boolean = false;
  private listening: boolean = false;
  private continuous: boolean = false;
  private feeding: boolean = false;
  private restarting: boolean = false;
  private utteranceSeq: number = 0;
  private activeSessionId: string = '';
  private pcmCarry: Uint8Array = new Uint8Array(0);
  private writeFailCount: number = 0;
  private sessionStartedAt: number = 0;
  private asrOnline: number = 0;
  private heardText: boolean = false;
  private swapped: boolean = false;
  /** 用户主动停麦时，结束会话触发的识别错误不再提示。 */
  private intentionalStop: boolean = false;
  private lastAsrError: string = '';
  private onResult: AsrResultCallback | null = null;
  private onError: AsrErrorCallback | null = null;
  private pcmTap: PcmTap | null = null;

  static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  isTtsReady(): boolean {
    return this.ttsReady;
  }

  isAsrReady(): boolean {
    return this.asrReady;
  }

  isListening(): boolean {
    return this.listening;
  }

  /** 聆听面试官时抄一份 PCM。传 null 表示停止抄录。 */
  setPcmTap(tap: PcmTap | null): void {
    this.pcmTap = tap;
  }

  async requestMicPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, [
        MIC_PERMISSION
      ]);
      if (result.authResults.length > 0) {
        return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      }
      return false;
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'requestMicPermission failed %{public}s', JSON.stringify(err));
      return false;
    }
  }

  async initTts(): Promise<boolean> {
    if (this.ttsReady && this.ttsEngine) {
      return true;
    }
    if (!canIUse('SystemCapability.AI.TextToSpeech')) {
      return false;
    }
    const params: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1
    };
    try {
      const engine = await textToSpeech.createEngine(params);
      this.ttsEngine = engine;
      this.ttsReady = true;
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'initTts failed %{public}s', JSON.stringify(err));
      return false;
    }
  }

  async speak(text: string): Promise<void> {
    if (!this.ttsEngine || text.trim().length === 0) {
      return;
    }
    await this.stopSpeak();
    const speakParams: textToSpeech.SpeakParams = {
      requestId: `${Date.now()}`
    };
    try {
      this.ttsEngine.speak(text, speakParams);
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'speak failed %{public}s', JSON.stringify(err));
    }
  }

  async stopSpeak(): Promise<void> {
    if (!this.ttsEngine) {
      return;
    }
    try {
      this.ttsEngine.stop();
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'stopSpeak failed %{public}s', JSON.stringify(err));
    }
  }

  async initAsr(onResult: AsrResultCallback, onError: AsrErrorCallback): Promise<boolean> {
    this.onResult = onResult;
    this.onError = onError;
    if (this.asrReady && this.asrEngine) {
      return true;
    }
    if (!canIUse('SystemCapability.AI.SpeechRecognizer')) {
      this.lastAsrError = '设备没有语音识别能力';
      return false;
    }
    return await this.createAsrEngine();
  }

  async startListening(): Promise<boolean> {
    if (!this.asrEngine) {
      return false;
    }
    this.continuous = false;
    return await this.openSession(SESSION_ID);
  }

  /** AI 辅助面试：麦克风持续采集，一句结束后换 session 再听。不朗读。 */
  async beginContinuous(onResult: AsrResultCallback, onError: AsrErrorCallback): Promise<boolean> {
    const ready = await this.initAsr(onResult, onError);
    if (!ready) {
      const hint = this.lastAsrError.length > 0 ? this.lastAsrError : '设备不支持语音识别';
      this.reportError(`听写引擎没起来：${hint}`);
      return false;
    }
    this.continuous = true;
    this.heardText = false;
    this.swapped = false;
    this.intentionalStop = true;
    const opened = await this.listenNext();
    this.intentionalStop = !opened;
    if (!opened) {
      this.continuous = false;
      const hint = this.lastAsrError.length > 0 ? this.lastAsrError : '听写没有开始';
      this.reportError(hint);
    }
    return opened;
  }

  async stopContinuous(): Promise<void> {
    this.intentionalStop = true;
    this.continuous = false;
    this.restarting = false;
    await this.stopListening();
  }

  private async listenNext(): Promise<boolean> {
    if (!this.asrEngine || !this.continuous) {
      return false;
    }
    this.feeding = false;
    const previous = this.activeSessionId;
    if (previous.length > 0) {
      try {
        this.asrEngine.cancel(previous);
      } catch (err) {
        hilog.warn(DOMAIN, 'SpeechService', 'cancel previous failed %{public}s', JSON.stringify(err));
      }
    }
    for (let attempt = 0; attempt < 4; attempt++) {
      if (!this.continuous || !this.asrEngine) {
        return false;
      }
      this.utteranceSeq++;
      const opened = await this.openSession(`listen-${this.utteranceSeq}`);
      if (opened) {
        return true;
      }
      await SpeechService.sleep(320);
    }
    return false;
  }

  async stopListening(): Promise<void> {
    this.feeding = false;
    this.restarting = false;
    await this.stopCapturer();
    const engine = this.asrEngine;
    const sessionId = this.activeSessionId;
    this.activeSessionId = '';
    this.pcmCarry = new Uint8Array(0);
    this.listening = false;
    if (!engine || sessionId.length === 0) {
      return;
    }
    try {
      engine.finish(sessionId);
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'finish failed %{public}s', JSON.stringify(err));
      try {
        engine.cancel(sessionId);
      } catch (_e) {
      }
    }
  }

  release(): void {
    this.pcmTap = null;
    this.intentionalStop = true;
    this.continuous = false;
    this.feeding = false;
    this.listening = false;
    this.restarting = false;
    const sessionId = this.activeSessionId;
    this.activeSessionId = '';
    this.pcmCarry = new Uint8Array(0);
    this.stopCapturer();
    try {
      if (this.asrEngine && sessionId.length > 0) {
        this.asrEngine.cancel(sessionId);
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'release cancel failed %{public}s', JSON.stringify(err));
    }
    try {
      if (this.ttsEngine) {
        this.ttsEngine.shutdown();
      }
      if (this.asrEngine) {
        this.asrEngine.shutdown();
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'release failed %{public}s', JSON.stringify(err));
    }
    this.ttsEngine = null;
    this.asrEngine = null;
    this.ttsReady = false;
    this.asrReady = false;
  }

  private async createAsrEngine(): Promise<boolean> {
    const modes: number[] = [0, 1];
    let last = '';
    for (let i = 0; i < modes.length; i++) {
      const params: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: modes[i],
        extraParams: SpeechService.engineExtra()
      };
      try {
        const engine = await speechRecognizer.createEngine(params);
        this.asrEngine = engine;
        this.bindAsrListener();
        this.asrReady = true;
        this.asrOnline = modes[i];
        this.lastAsrError = '';
        hilog.info(DOMAIN, 'SpeechService', 'asr engine online=%{public}d', modes[i]);
        return true;
      } catch (err) {
        last = SpeechService.brief(err);
        hilog.warn(DOMAIN, 'SpeechService', 'createEngine online=%{public}d failed %{public}s', modes[i], last);
      }
    }
    this.lastAsrError = last.length > 0 ? last : '创建听写引擎失败';
    return false;
  }

  private async openSession(sessionId: string): Promise<boolean> {
    if (!this.asrEngine) {
      return false;
    }
    this.feeding = false;
    this.writeFailCount = 0;
    this.activeSessionId = sessionId;
    const started = this.startEngine(sessionId);
    if (!started) {
      this.listening = false;
      this.activeSessionId = '';
      return false;
    }
    const capOk = await this.ensureCapturer();
    if (!capOk) {
      this.listening = false;
      try {
        this.asrEngine.cancel(sessionId);
      } catch (_e) {
      }
      this.activeSessionId = '';
      return false;
    }
    this.sessionStartedAt = Date.now();
    this.feeding = true;
    this.listening = true;
    this.drain();
    return true;
  }

  private startEngine(sessionId: string): boolean {
    if (!this.asrEngine) {
      return false;
    }
    const audioInfo: speechRecognizer.AudioInfo = {
      audioType: 'pcm',
      sampleRate: 16000,
      soundChannel: 1,
      sampleBit: 16
    };
    const withExtra: speechRecognizer.StartParams = {
      sessionId: sessionId,
      audioInfo: audioInfo,
      extraParams: SpeechService.startExtra()
    };
    try {
      this.asrEngine.startListening(withExtra);
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'startListening extra failed %{public}s', JSON.stringify(err));
    }
    const plain: speechRecognizer.StartParams = {
      sessionId: sessionId,
      audioInfo: audioInfo
    };
    try {
      this.asrEngine.startListening(plain);
      return true;
    } catch (err) {
      this.lastAsrError = `听写启动失败：${SpeechService.brief(err)}`;
      hilog.warn(DOMAIN, 'SpeechService', 'startListening failed %{public}s', this.lastAsrError);
      return false;
    }
  }

  private async ensureCapturer(): Promise<boolean> {
    if (this.capturer) {
      return true;
    }
    const sources: audio.SourceType[] = [
      audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
      audio.SourceType.SOURCE_TYPE_MIC
    ];
    let last = '';
    for (let i = 0; i < sources.length; i++) {
      try {
        const cap = await audio.createAudioCapturer(SpeechService.capturerOptions(sources[i]));
        cap.on('readData', (buffer: ArrayBuffer) => {
          this.onPcm(buffer);
        });
        await cap.start();
        this.capturer = cap;
        hilog.info(DOMAIN, 'SpeechService', 'capturer started source=%{public}d', sources[i]);
        return true;
      } catch (err) {
        last = SpeechService.brief(err);
        hilog.warn(DOMAIN, 'SpeechService', 'capturer source=%{public}d failed %{public}s', sources[i], last);
      }
    }
    this.lastAsrError = `麦克风打不开：${last}`;
    return false;
  }

  private async stopCapturer(): Promise<void> {
    const cap = this.capturer;
    this.capturer = null;
    if (!cap) {
      return;
    }
    try {
      cap.off('readData');
    } catch (_e) {
    }
    try {
      await cap.stop();
    } catch (_e) {
    }
    try {
      await cap.release();
    } catch (_e) {
    }
  }

  private onPcm(buffer: ArrayBuffer): void {
    if (buffer.byteLength === 0) {
      return;
    }
    const view = new Uint8Array(buffer);
    const copy = new Uint8Array(view.length);
    copy.set(view);
    this.enqueue(copy);
    this.drain();
  }

  private enqueue(incoming: Uint8Array): void {
    const merged = new Uint8Array(this.pcmCarry.length + incoming.length);
    merged.set(this.pcmCarry, 0);
    merged.set(incoming, this.pcmCarry.length);
    if (merged.length > PCM_HOLD) {
      this.pcmCarry = merged.slice(merged.length - PCM_HOLD);
    } else {
      this.pcmCarry = merged;
    }
  }

  private drain(): void {
    if (!this.feeding || this.activeSessionId.length === 0) {
      return;
    }
    let offset = 0;
    while (this.pcmCarry.length - offset >= PCM_CHUNK) {
      const chunk = this.pcmCarry.slice(offset, offset + PCM_CHUNK);
      offset += PCM_CHUNK;
      this.writeChunk(chunk);
    }
    if (offset > 0) {
      this.pcmCarry = offset >= this.pcmCarry.length ? new Uint8Array(0) : this.pcmCarry.slice(offset);
    }
  }

  private writeChunk(chunk: Uint8Array): void {
    if (!this.asrEngine || !this.feeding || this.activeSessionId.length === 0) {
      return;
    }
    const tap = this.pcmTap;
    if (tap !== null) {
      tap(chunk);
    }
    try {
      this.asrEngine.writeAudio(this.activeSessionId, chunk);
      this.writeFailCount = 0;
    } catch (err) {
      this.writeFailCount++;
      if (this.writeFailCount === 1 || this.writeFailCount === 40) {
        hilog.warn(DOMAIN, 'SpeechService', 'writeAudio failed %{public}s', JSON.stringify(err));
      }
      if (this.writeFailCount >= 12) {
        this.writeFailCount = 0;
        this.scheduleRestart(this.activeSessionId);
      }
    }
  }

  private bindAsrListener(): void {
    if (!this.asrEngine) {
      return;
    }
    const listener: speechRecognizer.RecognitionListener = {
      onStart: (sessionId: string, _eventMessage: string) => {
        if (sessionId === this.activeSessionId) {
          this.feeding = true;
          this.listening = true;
          this.drain();
        }
      },
      onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
        hilog.info(DOMAIN, 'SpeechService', 'asr event %{public}d %{public}s %{public}s', eventCode, sessionId, eventMessage);
      },
      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        if (this.activeSessionId.length > 0 && sessionId !== this.activeSessionId) {
          return;
        }
        if (result.result.length > 0) {
          this.heardText = true;
          if (this.onResult) {
            this.onResult(result.result, result.isFinal || result.isLast);
          }
        }
        if (result.isLast && !this.sessionTooYoung()) {
          this.scheduleRestart(sessionId);
        }
      },
      onComplete: (sessionId: string, _eventMessage: string) => {
        if (sessionId !== this.activeSessionId || this.sessionTooYoung()) {
          return;
        }
        this.listening = false;
        this.scheduleRestart(sessionId);
      },
      onError: (sessionId: string, errorCode: number, errorMessage: string) => {
        hilog.warn(DOMAIN, 'SpeechService', 'asr error %{public}d %{public}s', errorCode, errorMessage);
        if (this.intentionalStop || this.restarting) {
          return;
        }
        if (this.activeSessionId.length > 0 && sessionId !== this.activeSessionId) {
          return;
        }
        this.listening = false;
        this.feeding = false;
        if (!this.continuous) {
          this.reportError(`识别失败(${errorCode}): ${errorMessage}`);
          return;
        }
        if (!this.heardText && !this.swapped && (errorCode === 1002200001 || errorCode === 1002200007)) {
          this.swapped = true;
          this.swapEngine();
          return;
        }
        this.scheduleRestart(sessionId);
      }
    };
    this.asrEngine.setListener(listener);
  }

  private async swapEngine(): Promise<void> {
    const next = this.asrOnline === 0 ? 1 : 0;
    this.feeding = false;
    this.restarting = true;
    const previous = this.activeSessionId;
    try {
      if (this.asrEngine && previous.length > 0) {
        this.asrEngine.cancel(previous);
      }
    } catch (_e) {
    }
    try {
      if (this.asrEngine) {
        this.asrEngine.shutdown();
      }
    } catch (_e) {
    }
    this.asrEngine = null;
    this.asrReady = false;
    this.activeSessionId = '';
    const params: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: next,
      extraParams: SpeechService.engineExtra()
    };
    try {
      const engine = await speechRecognizer.createEngine(params);
      this.asrEngine = engine;
      this.bindAsrListener();
      this.asrReady = true;
      this.asrOnline = next;
      hilog.info(DOMAIN, 'SpeechService', 'asr swapped online=%{public}d', next);
      this.restarting = false;
      const opened = await this.listenNext();
      if (!opened) {
        this.continuous = false;
        this.reportError(this.lastAsrError.length > 0 ? this.lastAsrError : '听写引擎切换失败');
      }
    } catch (err) {
      this.restarting = false;
      this.continuous = false;
      this.reportError(`听写引擎切换失败：${SpeechService.brief(err)}`);
    }
  }

  private sessionTooYoung(): boolean {
    return Date.now() - this.sessionStartedAt < 900;
  }

  private scheduleRestart(sessionId: string): void {
    if (!this.continuous || this.restarting) {
      return;
    }
    if (sessionId.length > 0 && this.activeSessionId.length > 0 && sessionId !== this.activeSessionId) {
      return;
    }
    this.restarting = true;
    this.feeding = false;
    this.writeFailCount = 0;
    this.pcmCarry = new Uint8Array(0);
    setTimeout(() => {
      if (!this.continuous) {
        this.restarting = false;
        return;
      }
      this.listenNext().then((ok: boolean) => {
        this.restarting = false;
        if (!ok && this.continuous) {
          this.reportError(this.lastAsrError.length > 0 ? this.lastAsrError : '听写中断，请点「开始聆听」再试一次');
        }
      });
    }, 400);
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  private reportError(message: string): void {
    if (this.onError) {
      this.onError(message);
    }
  }

  private static engineExtra(): Record<string, Object> {
    const option: Record<string, Object> = {
      'enablePartialResult': true
    };
    const extra: Record<string, Object> = {
      'locate': 'CN',
      'recognizerOption': option
    };
    return extra;
  }

  private static startExtra(): Record<string, Object> {
    const extra: Record<string, Object> = {
      'recognitionMode': 0,
      'vadBegin': 2000,
      'vadEnd': 3000,
      'maxAudioDuration': 60000
    };
    return extra;
  }

  private static capturerOptions(source: audio.SourceType): audio.AudioCapturerOptions {
    const streamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };
    const capturerInfo: audio.AudioCapturerInfo = {
      source: source,
      capturerFlags: 0
    };
    const options: audio.AudioCapturerOptions = {
      streamInfo: streamInfo,
      capturerInfo: capturerInfo
    };
    return options;
  }

  private static brief(err: Object): string {
    const text = JSON.stringify(err);
    if (text.length > 160) {
      return text.substring(0, 160);
    }
    return text;
  }
}
