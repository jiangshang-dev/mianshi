import { AiStreamSnapshot } from '../../common/models/Types';
import { InterviewConfig, InterviewReport } from '../../common/models/InterviewTypes';
import { HttpClient, SseAbort } from '../../common/network/HttpClient';
import { AuthRepository } from './AuthRepository';

export interface InterviewTurnRequest {
  sessionId: string;
  action: string;
  message: string;
  config: InterviewConfig;
}

export interface InterviewParsedReply {
  spoken: string;
  display: string;
  report: InterviewReport | null;
  sessionId: string;
}

interface InterviewApiBody {
  sessionId: string;
  userId: string;
  role: string;
  level: string;
  difficulty: string;
  resumeId: string;
  resumeFileName: string;
  resumePreview: string;
  focus: string;
  interviewerTitle: string;
  action: string;
  message: string;
}

interface InterviewReportDto {
  score?: number;
  accuracy?: number;
  depth?: number;
  expression?: number;
  advantages?: string[] | string;
  problems?: string[] | string;
  suggestions?: string[] | string;
}

/** 模拟面试：独立 SSE 接口 /api/ai/interview */
export class InterviewRepository {
  private static instance: InterviewRepository | null = null;
  private auth: AuthRepository = AuthRepository.getInstance();

  static getInstance(): InterviewRepository {
    if (!InterviewRepository.instance) {
      InterviewRepository.instance = new InterviewRepository();
    }
    return InterviewRepository.instance;
  }

  async streamTurn(req: InterviewTurnRequest, onUpdate: (snap: AiStreamSnapshot) => void,
    abort?: SseAbort): Promise<InterviewParsedReply> {
    const user = this.auth.getCached();
    const body: InterviewApiBody = {
      sessionId: req.sessionId,
      userId: user !== null ? user.userId : '',
      role: req.config.role,
      level: req.config.level,
      difficulty: req.config.difficulty,
      resumeId: req.config.resumeId,
      resumeFileName: req.config.resumeFileName,
      resumePreview: req.config.resumePreview,
      focus: req.config.focus,
      interviewerTitle: req.config.interviewerTitle,
      action: req.action,
      message: req.message
    };
    let sessionId = req.sessionId;
    const wrapped = (snap: AiStreamSnapshot): void => {
      if (snap.sessionId.length > 0) {
        sessionId = snap.sessionId;
      }
      onUpdate(snap);
    };
    const resp = await HttpClient.postSse('/api/ai/interview', JSON.stringify(body), wrapped, abort);
    if (abort?.stopped) {
      return InterviewRepository.parseReply(resp.body, sessionId);
    }
    if (resp.body.length === 0) {
      const err = resp.message.length > 0 ? resp.message : 'AI 流式请求失败';
      onUpdate({
        thinking: '',
        markdown: err,
        phase: 'error',
        thinkingDone: false,
        sessionId: sessionId
      });
      return {
        spoken: err,
        display: err,
        report: null,
        sessionId: sessionId
      };
    }
    return InterviewRepository.parseReply(resp.body, sessionId);
  }

  static parseReply(markdown: string, sessionId: string): InterviewParsedReply {
    const startTag = '<<<REPORT>>>';
    const endTag = '<<<END>>>';
    const start = markdown.indexOf(startTag);
    if (start < 0) {
      const text = markdown.trim();
      return {
        spoken: text,
        display: text,
        report: null,
        sessionId: sessionId
      };
    }
    const jsonStart = start + startTag.length;
    const end = markdown.indexOf(endTag, jsonStart);
    const jsonPart = end >= 0 ? markdown.substring(jsonStart, end) : markdown.substring(jsonStart);
    const spoken = markdown.substring(0, start).trim();
    return {
      spoken: spoken,
      display: spoken,
      report: InterviewRepository.toReport(jsonPart),
      sessionId: sessionId
    };
  }

  static looksLikeError(text: string): boolean {
    if (text.length === 0) {
      return true;
    }
    return text.indexOf('AI 服务未配置') >= 0 ||
      text.indexOf('AI 生成失败') >= 0 ||
      text.indexOf('stream failed') >= 0 ||
      text.indexOf('AI 流式请求失败') >= 0 ||
      text.indexOf('message 不能为空') >= 0;
  }

  private static asLines(value: string[] | string | undefined): string[] {
    if (value === undefined) {
      return [];
    }
    if (typeof value === 'string') {
      return value.length > 0 ? [value] : [];
    }
    return value;
  }

  private static toReport(raw: string): InterviewReport | null {
    const text = raw.trim();
    if (text.length === 0) {
      return null;
    }
    try {
      const dto = JSON.parse(text) as InterviewReportDto;
      if (dto.score === undefined) {
        return null;
      }
      const score = dto.score as number;
      return {
        score: score,
        accuracy: dto.accuracy !== undefined ? dto.accuracy : score,
        depth: dto.depth !== undefined ? dto.depth : score,
        expression: dto.expression !== undefined ? dto.expression : score,
        advantages: InterviewRepository.asLines(dto.advantages),
        problems: InterviewRepository.asLines(dto.problems),
        suggestions: InterviewRepository.asLines(dto.suggestions)
      };
    } catch (_e) {
      return null;
    }
  }
}
