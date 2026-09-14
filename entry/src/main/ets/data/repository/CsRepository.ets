import { HttpClient } from '../../common/network/HttpClient';
import { CsMessage, CsSession, JeecgCsMessageResp, JeecgCsMessagesResp, JeecgCsSessionResp } from '../../common/models/CsTypes';

/** App 端客服：仅 HTTP 轮询（全量同步），避免 WebSocket 原生回调闪退 */
export class CsRepository {
  private static instance: CsRepository | null = null;
  private pollTimer: number = -1;
  private sessionId: string = '';
  private handler: ((list: CsMessage[]) => void) | null = null;
  private polling: boolean = false;

  static getInstance(): CsRepository {
    if (!CsRepository.instance) {
      CsRepository.instance = new CsRepository();
    }
    return CsRepository.instance;
  }

  async mine(): Promise<CsSession> {
    const resp = await HttpClient.postJson('/api/cs/session/mine', JSON.stringify({ clientSource: 'harmony' }));
    const parsed = this.parseSession(resp.body);
    if (!resp.ok || parsed === null) {
      throw new Error(this.msg(resp.body, '打开客服失败'));
    }
    return parsed;
  }

  async messages(sessionId: string): Promise<CsMessage[]> {
    const sid = `${sessionId}`;
    if (sid.length === 0) {
      return [];
    }
    const resp = await HttpClient.get(`/api/cs/session/${encodeURIComponent(sid)}/messages`, 'limit=100');
    const body = resp.body !== null && resp.body !== undefined ? `${resp.body}` : '';
    if (!resp.ok || body.length === 0) {
      return [];
    }
    try {
      const parsed: JeecgCsMessagesResp = JSON.parse(body) as JeecgCsMessagesResp;
      if (parsed.success === false) {
        return [];
      }
      return this.copyMessages(parsed.result);
    } catch (_e) {
      return [];
    }
  }

  async send(sessionId: string, content: string): Promise<CsMessage> {
    const resp = await HttpClient.postJson(`/api/cs/session/${encodeURIComponent(`${sessionId}`)}/messages`,
      JSON.stringify({ content: content }));
    const parsed = this.parseMessage(resp.body);
    if (!resp.ok || parsed === null) {
      throw new Error(this.msg(resp.body, '发送失败'));
    }
    return parsed;
  }

  /** 全量同步：每次把服务端列表交给页面替换，避免漏消息 */
  startPoll(sessionId: string, onSync: (list: CsMessage[]) => void): void {
    this.stopPoll();
    this.sessionId = `${sessionId}`;
    this.handler = onSync;
    this.scheduleNext(1800);
  }

  stopPoll(): void {
    if (this.pollTimer >= 0) {
      clearTimeout(this.pollTimer);
      this.pollTimer = -1;
    }
    this.handler = null;
    this.polling = false;
  }

  private scheduleNext(delayMs: number): void {
    if (this.handler === null) {
      return;
    }
    this.pollTimer = setTimeout(() => {
      void this.pollOnce();
    }, delayMs);
  }

  private async pollOnce(): Promise<void> {
    if (this.sessionId.length === 0 || this.handler === null || this.polling) {
      this.scheduleNext(2500);
      return;
    }
    this.polling = true;
    try {
      const list = await this.messages(this.sessionId);
      const cb = this.handler;
      if (cb !== null) {
        // 回到宏任务，确保可安全更新 @State
        setTimeout(() => {
          try {
            cb(list);
          } catch (_e) {
          }
        }, 0);
      }
    } catch (_e) {
    } finally {
      this.polling = false;
      this.scheduleNext(2500);
    }
  }

  private copyMessages(raw: CsMessage[] | null | undefined): CsMessage[] {
    const out: CsMessage[] = [];
    if (raw === undefined || raw === null) {
      return out;
    }
    for (let i = 0; i < raw.length; i++) {
      const item = this.copyMessage(raw[i]);
      if (item !== null) {
        out.push(item);
      }
    }
    return out;
  }

  private copyMessage(raw: CsMessage | null | undefined): CsMessage | null {
    if (raw === undefined || raw === null) {
      return null;
    }
    const id = raw.id !== undefined && raw.id !== null ? `${raw.id}` : '';
    if (id.length === 0) {
      return null;
    }
    const msg: CsMessage = {
      id: id,
      sessionId: raw.sessionId !== undefined && raw.sessionId !== null ? `${raw.sessionId}` : undefined,
      senderType: raw.senderType !== undefined && raw.senderType !== null ? `${raw.senderType}` : undefined,
      senderName: raw.senderName !== undefined && raw.senderName !== null ? `${raw.senderName}` : undefined,
      content: raw.content !== undefined && raw.content !== null ? `${raw.content}` : '',
      createTime: raw.createTime !== undefined && raw.createTime !== null ? `${raw.createTime}` : undefined
    };
    return msg;
  }

  private parseSession(body: string): CsSession | null {
    if (body === null || body === undefined || `${body}`.length === 0) {
      return null;
    }
    try {
      const parsed: JeecgCsSessionResp = JSON.parse(`${body}`) as JeecgCsSessionResp;
      if (parsed.result === undefined || parsed.result === null) {
        return null;
      }
      const raw = parsed.result;
      const id = raw.id !== undefined && raw.id !== null ? `${raw.id}` : '';
      if (id.length === 0) {
        return null;
      }
      const session: CsSession = {
        id: id,
        userId: raw.userId,
        status: raw.status,
        agentName: raw.agentName !== undefined && raw.agentName !== null ? `${raw.agentName}` : undefined,
        lastMsg: raw.lastMsg !== undefined && raw.lastMsg !== null ? `${raw.lastMsg}` : undefined,
        unreadUser: raw.unreadUser
      };
      return session;
    } catch (_e) {
      return null;
    }
  }

  private parseMessage(body: string): CsMessage | null {
    if (body === null || body === undefined || `${body}`.length === 0) {
      return null;
    }
    try {
      const parsed: JeecgCsMessageResp = JSON.parse(`${body}`) as JeecgCsMessageResp;
      return this.copyMessage(parsed.result);
    } catch (_e) {
      return null;
    }
  }

  private msg(body: string, fallback: string): string {
    if (body === null || body === undefined || `${body}`.length === 0) {
      return fallback;
    }
    try {
      const parsed = JSON.parse(`${body}`) as JeecgCsSessionResp;
      if (parsed.message !== undefined && parsed.message !== null && `${parsed.message}`.length > 0) {
        return `${parsed.message}`;
      }
    } catch (_e) {
    }
    return fallback;
  }
}
