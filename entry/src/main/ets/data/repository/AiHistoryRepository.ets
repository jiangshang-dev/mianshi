import { HttpClient } from '../../common/network/HttpClient';
import { LoginGate } from '../../common/utils/LoginGate';

export interface AiHistorySession {
  id: string;
  questionId: string;
  questionTitle: string;
  scene: string;
  createTime: string;
  updateTime: string;
}

export interface AiHistoryMessage {
  id: string;
  role: string;
  content: string;
  createTime: string;
}

interface SessionListResponse {
  code: number;
  result?: AiHistorySession[];
  data?: AiHistorySession[];
}

interface MessageListResponse {
  code: number;
  result?: AiHistoryMessage[];
  data?: AiHistoryMessage[];
}

export class AiHistoryRepository {
  private static instance: AiHistoryRepository | null = null;

  static getInstance(): AiHistoryRepository {
    if (!AiHistoryRepository.instance) {
      AiHistoryRepository.instance = new AiHistoryRepository();
    }
    return AiHistoryRepository.instance;
  }

  async listSessions(scene: string): Promise<AiHistorySession[]> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      return [];
    }
    const query = `userId=${encodeURIComponent(userId)}&scene=${encodeURIComponent(scene)}`;
    const resp = await HttpClient.get('/api/ai/sessions', query);
    if (!resp.ok) {
      return [];
    }
    try {
      const parsed = JSON.parse(resp.body) as SessionListResponse;
      const list = parsed.result ?? parsed.data;
      return list ? list : [];
    } catch (_e) {
      return [];
    }
  }

  async listMessages(sessionId: string): Promise<AiHistoryMessage[]> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0 || sessionId.length === 0) {
      return [];
    }
    const resp = await HttpClient.get(`/api/ai/sessions/${encodeURIComponent(sessionId)}/messages`,
      `userId=${encodeURIComponent(userId)}`);
    if (!resp.ok) {
      return [];
    }
    try {
      const parsed = JSON.parse(resp.body) as MessageListResponse;
      const list = parsed.result ?? parsed.data;
      return list ? list : [];
    } catch (_e) {
      return [];
    }
  }
}
