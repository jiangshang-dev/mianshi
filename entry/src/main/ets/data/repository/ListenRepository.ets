import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiStreamSnapshot } from '../../common/models/Types';
import { HttpClient, MultipartPart, SseAbort } from '../../common/network/HttpClient';
import { DeviceProfile } from '../../common/utils/DeviceProfile';
import { AuthRepository } from './AuthRepository';
import { ResumeRepository } from './ResumeRepository';

const DOMAIN = 0xC0DE;

export interface ListenMatch {
  hit: boolean;
  questionId: string;
  title: string;
  interviewAnswer: string;
  content: string;
  score: number;
}

interface SessionBody {
  userId: string;
  resumeId: string;
  resumeFileName: string;
  resumePreview: string;
  userDevice: string;
}

interface MatchBody {
  userId: string;
  sessionId: string;
  text: string;
}

interface TurnBody {
  sessionId: string;
  userId: string;
  turnId: string;
  seq: number;
  questionText: string;
  forceLlm: boolean;
  resumePreview: string;
  userDevice: string;
}

interface SessionDto {
  id?: string;
}

interface MatchDto {
  hit?: boolean;
  questionId?: string;
  title?: string;
  interviewAnswer?: string;
  content?: string;
  score?: number;
}

interface ApiEnvelope<T> {
  message?: string;
  result?: T;
}

export interface ListenHistorySession {
  sessionId: string;
  title: string;
  turnCount: number;
  createTime: string;
}

export interface ListenHistoryTurn {
  id: string;
  turnId: string;
  seq: number;
  questionText: string;
  answerText: string;
  audioUrl: string;
  audioMs: number;
  createTime: string;
}

/** AI 辅助面试。不走 /api/ai/interview。 */
export class ListenRepository {
  private static instance: ListenRepository | null = null;

  static getInstance(): ListenRepository {
    if (!ListenRepository.instance) {
      ListenRepository.instance = new ListenRepository();
    }
    return ListenRepository.instance;
  }

  async openSession(): Promise<string> {
    const user = AuthRepository.getInstance().getCached();
    const resume = ResumeRepository.getInstance().getCached();
    const body: SessionBody = {
      userId: user !== null ? user.userId : '',
      resumeId: resume !== null ? resume.resumeId : '',
      resumeFileName: resume !== null ? resume.fileName : '',
      resumePreview: '',
      userDevice: DeviceProfile.loginDevice()
    };
    const resp = await HttpClient.postJson('/api/ai/listen/session', JSON.stringify(body));
    const parsed = this.readEnvelope<SessionDto>(resp.body);
    const data = parsed.result !== undefined && parsed.result !== null ? parsed.result : undefined;
    const id = data !== undefined && data.id !== undefined && data.id !== null ? data.id : '';
    if (resp.ok && id.length > 0) {
      return id;
    }
    const serverMsg = parsed.message !== undefined ? parsed.message : '';
    if (serverMsg.length > 0) {
      throw new Error(serverMsg);
    }
    if (resp.code === 404) {
      throw new Error('后端还没有辅助面试接口，请重新编译并重启服务');
    }
    if (resp.body.length === 0) {
      throw new Error('连不上辅助面试服务');
    }
    throw new Error('会话没打开');
  }

  private readEnvelope<T>(body: string): ApiEnvelope<T> {
    if (body.length === 0) {
      return {};
    }
    try {
      return JSON.parse(body) as ApiEnvelope<T>;
    } catch (_e) {
      return {};
    }
  }

  async match(sessionId: string, text: string): Promise<ListenMatch> {
    const empty: ListenMatch = {
      hit: false,
      questionId: '',
      title: '',
      interviewAnswer: '',
      content: '',
      score: 0
    };
    const user = AuthRepository.getInstance().getCached();
    const body: MatchBody = {
      userId: user !== null ? user.userId : '',
      sessionId: sessionId,
      text: text
    };
    const resp = await HttpClient.postJson('/api/ai/listen/match', JSON.stringify(body));
    if (!resp.ok || resp.body.length === 0) {
      return empty;
    }
    try {
      const parsed = JSON.parse(resp.body) as ApiEnvelope<MatchDto>;
      const result = parsed.result;
      if (result === undefined) {
        return empty;
      }
      return {
        hit: result.hit === true,
        questionId: result.questionId !== undefined ? result.questionId : '',
        title: result.title !== undefined ? result.title : '',
        interviewAnswer: result.interviewAnswer !== undefined ? result.interviewAnswer : '',
        content: result.content !== undefined ? result.content : '',
        score: result.score !== undefined ? result.score : 0
      };
    } catch (_e) {
      return empty;
    }
  }

  async streamTurn(sessionId: string, turnId: string, seq: number, questionText: string, forceLlm: boolean,
    onUpdate: (snap: AiStreamSnapshot) => void, abort?: SseAbort): Promise<string> {
    const user = AuthRepository.getInstance().getCached();
    const body: TurnBody = {
      sessionId: sessionId,
      userId: user !== null ? user.userId : '',
      turnId: turnId,
      seq: seq,
      questionText: questionText,
      forceLlm: forceLlm,
      resumePreview: '',
      userDevice: DeviceProfile.loginDevice()
    };
    const resp = await HttpClient.postSse('/api/ai/listen/turn', JSON.stringify(body), onUpdate, abort);
    return resp.body;
  }

  async listHistory(): Promise<ListenHistorySession[]> {
    const user = AuthRepository.getInstance().getCached();
    const userId = user !== null ? user.userId : '';
    if (userId.length === 0) {
      return [];
    }
    const resp = await HttpClient.get('/api/ai/listen/history', `userId=${encodeURIComponent(userId)}`);
    return this.readList<ListenHistorySession>(resp.ok, resp.body);
  }

  async listTurns(sessionId: string): Promise<ListenHistoryTurn[]> {
    const user = AuthRepository.getInstance().getCached();
    const userId = user !== null ? user.userId : '';
    if (userId.length === 0 || sessionId.length === 0) {
      return [];
    }
    const resp = await HttpClient.get(`/api/ai/listen/history/${encodeURIComponent(sessionId)}`,
      `userId=${encodeURIComponent(userId)}`);
    return this.readList<ListenHistoryTurn>(resp.ok, resp.body);
  }

  /**
   * 把这一题的面试官原声写成 WAV 上传。服务端转 MP3 再放进 OSS。
   * 失败不影响答法展示。
   */
  async uploadUtterance(cacheDir: string, turnId: string, pcm: Uint8Array): Promise<void> {
    if (pcm.byteLength < 16000 || turnId.length === 0) {
      return;
    }
    const user = AuthRepository.getInstance().getCached();
    const userId = user !== null ? user.userId : '';
    if (userId.length === 0) {
      return;
    }
    const path = `${cacheDir}/listen-${turnId}.wav`;
    try {
      ListenRepository.writeWav(path, pcm);
      const parts: MultipartPart[] = [
        { name: 'userId', data: userId },
        { name: 'turnId', data: turnId },
        { name: 'file', filePath: path, fileName: 'utterance.wav', mimeType: 'audio/wav' }
      ];
      let resp = await HttpClient.postMultipart('/api/ai/listen/audio', parts, 60000);
      if (!resp.ok && resp.body.indexOf('回合还没保存') >= 0) {
        await ListenRepository.sleep(500);
        resp = await HttpClient.postMultipart('/api/ai/listen/audio', parts, 60000);
      }
      if (!resp.ok) {
        hilog.warn(DOMAIN, 'ListenRepository', 'audio upload %{public}d %{public}s', resp.code, resp.body);
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'ListenRepository', 'audio upload failed %{public}s', JSON.stringify(err));
    } finally {
      try {
        fileIo.unlinkSync(path);
      } catch (_e) {
      }
    }
  }

  private readList<T>(ok: boolean, body: string): T[] {
    if (!ok || body.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(body) as ApiEnvelope<T[]>;
      const list = parsed.result;
      return list !== undefined && list !== null ? list : [];
    } catch (_e) {
      return [];
    }
  }

  private static writeWav(path: string, pcm: Uint8Array): void {
    const header = new ArrayBuffer(44);
    const view = new DataView(header);
    ListenRepository.writeAscii(header, 0, 'RIFF');
    view.setUint32(4, 36 + pcm.byteLength, true);
    ListenRepository.writeAscii(header, 8, 'WAVE');
    ListenRepository.writeAscii(header, 12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, 1, true);
    view.setUint32(24, 16000, true);
    view.setUint32(28, 32000, true);
    view.setUint16(32, 2, true);
    view.setUint16(34, 16, true);
    ListenRepository.writeAscii(header, 36, 'data');
    view.setUint32(40, pcm.byteLength, true);
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, header);
      const body = pcm.byteOffset === 0 && pcm.buffer.byteLength === pcm.byteLength ?
        pcm.buffer : pcm.buffer.slice(pcm.byteOffset, pcm.byteOffset + pcm.byteLength);
      fileIo.writeSync(file.fd, body);
    } finally {
      fileIo.closeSync(file);
    }
  }

  private static writeAscii(buffer: ArrayBuffer, offset: number, text: string): void {
    const bytes = new Uint8Array(buffer);
    for (let i = 0; i < text.length; i++) {
      bytes[offset + i] = text.charCodeAt(i);
    }
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
