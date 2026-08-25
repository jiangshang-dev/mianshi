import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { speechRecognizer, textToSpeech } from '@kit.CoreSpeechKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xC0DE;
const SESSION_ID = 'interview-session';
const MIC_PERMISSION = 'ohos.permission.MICROPHONE';

export type AsrResultCallback = (text: string, isLast: boolean) => void;
export type AsrErrorCallback = (message: string) => void;

/** 语音服务：TTS 播报 + ASR 听写（CoreSpeechKit） */
export class SpeechService {
  private static instance: SpeechService | null = null;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private ttsReady: boolean = false;
  private asrReady: boolean = false;
  private listening: boolean = false;
  private onResult: AsrResultCallback | null = null;
  private onError: AsrErrorCallback | null = null;

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
      return false;
    }
    const params: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: 1
    };
    try {
      const engine = await speechRecognizer.createEngine(params);
      this.asrEngine = engine;
      this.bindAsrListener();
      this.asrReady = true;
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'initAsr failed %{public}s', JSON.stringify(err));
      return false;
    }
  }

  async startListening(): Promise<boolean> {
    if (!this.asrEngine) {
      return false;
    }
    const startParams: speechRecognizer.StartParams = {
      sessionId: SESSION_ID,
      audioInfo: {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      }
    };
    try {
      await this.asrEngine.startListening(startParams);
      this.listening = true;
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'startListening failed %{public}s', JSON.stringify(err));
      return false;
    }
  }

  async stopListening(): Promise<void> {
    if (!this.asrEngine || !this.listening) {
      return;
    }
    try {
      await this.asrEngine.finish(SESSION_ID);
    } catch (err) {
      hilog.warn(DOMAIN, 'SpeechService', 'stopListening failed %{public}s', JSON.stringify(err));
    } finally {
      this.listening = false;
    }
  }

  release(): void {
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
    this.listening = false;
  }

  private bindAsrListener(): void {
    if (!this.asrEngine) {
      return;
    }
    const listener: speechRecognizer.RecognitionListener = {
      onStart: (_sessionId: string, _eventMessage: string) => {
      },
      onEvent: (_sessionId: string, _eventCode: number, _eventMessage: string) => {
      },
      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        if (this.onResult) {
          this.onResult(result.result, result.isLast);
        }
        if (result.isLast) {
          this.listening = false;
        }
      },
      onComplete: (_sessionId: string, _eventMessage: string) => {
        this.listening = false;
      },
      onError: (sessionId: string, errorCode: number, errorMessage: string) => {
        this.listening = false;
        if (this.onError) {
          this.onError(`识别失败(${errorCode}): ${errorMessage}`);
        }
      }
    };
    this.asrEngine.setListener(listener);
  }
}
