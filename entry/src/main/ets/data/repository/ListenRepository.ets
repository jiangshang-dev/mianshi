import { AiStreamSnapshot } from '../../common/models/Types';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { HttpClient, SseAbort } from '../../common/network/HttpClient';
import { DeviceProfile } from '../../common/utils/DeviceProfile';
import { AuthRepository } from './AuthRepository';
import { ResumeRepository } from './ResumeRepository';

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
      resumePreview: ListenRepository.resumeText(resume),
      userDevice: DeviceProfile.loginDevice()
    };
    const resp = await HttpClient.postJson('/api/ai/listen/session', JSON.stringify(body));
    if (!resp.ok || resp.body.length === 0) {
      return '';
    }
    try {
      const parsed = JSON.parse(resp.body) as ApiEnvelope<SessionDto>;
      if (parsed.result === undefined || parsed.result.id === undefined) {
        return '';
      }
      return parsed.result.id;
    } catch (_e) {
      return '';
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
    const resume = ResumeRepository.getInstance().getCached();
    const body: TurnBody = {
      sessionId: sessionId,
      userId: user !== null ? user.userId : '',
      turnId: turnId,
      seq: seq,
      questionText: questionText,
      forceLlm: forceLlm,
      resumePreview: ListenRepository.resumeText(resume),
      userDevice: DeviceProfile.loginDevice()
    };
    const resp = await HttpClient.postSse('/api/ai/listen/turn', JSON.stringify(body), onUpdate, abort);
    return resp.body;
  }

  private static resumeText(resume: ResumeProfile | null): string {
    if (resume === null) {
      return '';
    }
    if (resume.textContent.length > 0) {
      return resume.textContent;
    }
    return resume.textPreview;
  }
}
