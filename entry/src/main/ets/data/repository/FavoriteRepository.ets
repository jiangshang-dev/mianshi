import { HttpClient } from '../../common/network/HttpClient';
import { LoginGate } from '../../common/utils/LoginGate';

export interface FavoriteItem {
  id: string;
  questionId: string;
  questionTitle: string;
  createTime: string;
}

interface FavoriteToggleRequest {
  userId: string;
  questionId: string;
  questionTitle: string;
}

interface FavoriteTogglePayload {
  favorited?: boolean;
}

interface FavoriteListResponse {
  code: number;
  result?: FavoriteItem[];
  data?: FavoriteItem[];
}

interface FavoriteToggleResponse {
  code: number;
  result?: FavoriteTogglePayload;
  data?: FavoriteTogglePayload;
}

export class FavoriteRepository {
  private static instance: FavoriteRepository | null = null;
  private ids: Set<string> = new Set<string>();

  static getInstance(): FavoriteRepository {
    if (!FavoriteRepository.instance) {
      FavoriteRepository.instance = new FavoriteRepository();
    }
    return FavoriteRepository.instance;
  }

  has(questionId: string): boolean {
    return this.ids.has(questionId);
  }

  async sync(): Promise<void> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      this.ids = new Set<string>();
      return;
    }
    const list = await this.list();
    const next: Set<string> = new Set<string>();
    list.forEach((item: FavoriteItem) => {
      next.add(item.questionId);
    });
    this.ids = next;
  }

  async list(): Promise<FavoriteItem[]> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      return [];
    }
    const resp = await HttpClient.get('/api/favorites', `userId=${encodeURIComponent(userId)}`);
    if (!resp.ok) {
      return [];
    }
    try {
      const parsed = JSON.parse(resp.body) as FavoriteListResponse;
      const list = parsed.result ?? parsed.data;
      return list ? list : [];
    } catch (_e) {
      return [];
    }
  }

  async toggle(questionId: string, questionTitle: string): Promise<boolean> {
    const userId = LoginGate.currentUserId();
    if (userId.length === 0) {
      return this.ids.has(questionId);
    }
    const body: FavoriteToggleRequest = {
      userId: userId,
      questionId: questionId,
      questionTitle: questionTitle
    };
    const resp = await HttpClient.postJson('/api/favorites/toggle', JSON.stringify(body));
    if (!resp.ok) {
      return this.ids.has(questionId);
    }
    try {
      const parsed = JSON.parse(resp.body) as FavoriteToggleResponse;
      const payload = parsed.result ?? parsed.data;
      const favorited = payload !== undefined ? (payload.favorited ?? false) : false;
      if (favorited) {
        this.ids.add(questionId);
      } else {
        this.ids.delete(questionId);
      }
      return favorited;
    } catch (_e) {
      return this.ids.has(questionId);
    }
  }
}
