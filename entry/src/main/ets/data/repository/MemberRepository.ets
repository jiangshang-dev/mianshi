import { HttpClient } from '../../common/network/HttpClient';
import { JeecgMemberMeResp, JeecgMemberPlanListResp, MemberMe, MemberPlan, IapVerifyBody,
  AppPayPrepare, JeecgAppPayResp, AppPayOrderStatus, JeecgAppPayOrderResp } from '../../common/models/MemberTypes';
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

  async createAppOrder(planId: string, channel: string): Promise<AppPayPrepare> {
    const resp = await HttpClient.postJson('/api/member/app/order',
      JSON.stringify({ planId: planId, channel: channel }), 20000);
    return this.parsePrepare(resp.body, resp.ok);
  }

  async syncAppOrder(orderId: string): Promise<AppPayOrderStatus | null> {
    const resp = await HttpClient.postJson(`/api/member/app/order/${orderId}/sync`, '{}', 20000);
    if (resp.body.length === 0) {
      return null;
    }
    const parsed: JeecgAppPayOrderResp = JSON.parse(resp.body) as JeecgAppPayOrderResp;
    if (parsed.success === false || !resp.ok) {
      throw new Error(parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '确认支付失败');
    }
    return parsed.result !== undefined ? parsed.result : null;
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

  private parsePrepare(body: string, ok: boolean): AppPayPrepare {
    if (body.length === 0) {
      throw new Error('下单失败');
    }
    const parsed: JeecgAppPayResp = JSON.parse(body) as JeecgAppPayResp;
    if (parsed.success === false || !ok || parsed.result === undefined) {
      throw new Error(parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '下单失败');
    }
    return parsed.result;
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
