import { HttpClient } from '../../common/network/HttpClient';
import { JeecgMemberMeResp, JeecgMemberPlanListResp, MemberMe, MemberPlan, IapVerifyBody } from '../../common/models/MemberTypes';
import { MemberGate } from '../../common/utils/MemberGate';

export class MemberRepository {
  private static instance: MemberRepository | null = null;

  static getInstance(): MemberRepository {
    if (!MemberRepository.instance) {
      MemberRepository.instance = new MemberRepository();
    }
    return MemberRepository.instance;
  }

  async me(): Promise<MemberMe | null> {
    const resp = await HttpClient.get('/api/member/me', '');
    return this.parseMe(resp.body, resp.ok);
  }

  async refreshStatus(): Promise<void> {
    try {
      await this.me();
    } catch (_e) {
      MemberGate.clearMember();
    }
  }

  async plans(): Promise<MemberPlan[]> {
    const resp = await HttpClient.get('/api/member/plans', '');
    if (!resp.ok || resp.body.length === 0) {
      return [];
    }
    try {
      const parsed: JeecgMemberPlanListResp = JSON.parse(resp.body) as JeecgMemberPlanListResp;
      return parsed.result !== undefined ? parsed.result : [];
    } catch (_e) {
      return [];
    }
  }

  async verify(body: IapVerifyBody): Promise<MemberMe | null> {
    const resp = await HttpClient.postJson('/api/member/iap/verify', JSON.stringify(body), 20000);
    const me = this.parseMe(resp.body, resp.ok);
    if (me === null && !resp.ok) {
      throw new Error(this.parseMessage(resp.body, '验单失败'));
    }
    return me;
  }

  async restore(body: IapVerifyBody): Promise<MemberMe | null> {
    const resp = await HttpClient.postJson('/api/member/iap/restore', JSON.stringify(body), 20000);
    return this.parseMe(resp.body, resp.ok);
  }

  private parseMe(body: string, ok: boolean): MemberMe | null {
    if (body.length === 0) {
      return null;
    }
    try {
      const parsed: JeecgMemberMeResp = JSON.parse(body) as JeecgMemberMeResp;
      if (parsed.success === false) {
        throw new Error(parsed.message !== undefined ? parsed.message : '请求失败');
      }
      if (!ok) {
        throw new Error(parsed.message !== undefined ? parsed.message : '请求失败');
      }
      const result = parsed.result !== undefined ? parsed.result : null;
      if (result !== null) {
        result.expireTime = MemberGate.parseExpireMs(result.expireTime);
      }
      MemberGate.applyMe(result);
      return result;
    } catch (e) {
      if (e instanceof Error) {
        throw e;
      }
      return null;
    }
  }

  private parseMessage(body: string, fallback: string): string {
    try {
      const parsed: JeecgMemberMeResp = JSON.parse(body) as JeecgMemberMeResp;
      if (parsed.message !== undefined && parsed.message.length > 0) {
        return parsed.message;
      }
    } catch (_e) {
    }
    return fallback;
  }
}
