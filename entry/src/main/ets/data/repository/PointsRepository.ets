import { HttpClient } from '../../common/network/HttpClient';
import {
  CheckinResult,
  JeecgCheckinResp,
  JeecgPointsMeResp,
  PointsMe,
  copyCheckinResult,
  copyPointsMe,
  emptyPointsMe
} from '../../common/models/PointsTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';

export class PointsRepository {
  private static instance: PointsRepository | null = null;

  static getInstance(): PointsRepository {
    if (!PointsRepository.instance) {
      PointsRepository.instance = new PointsRepository();
    }
    return PointsRepository.instance;
  }

  async me(): Promise<PointsMe> {
    const resp = await HttpClient.get('/api/points/me', '');
    if (resp.body.length === 0) {
      throw new Error(this.parseMessage('', '积分加载失败'));
    }
    const parsed: JeecgPointsMeResp = JSON.parse(resp.body) as JeecgPointsMeResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '积分加载失败');
    if (parsed.result === undefined) {
      const empty = emptyPointsMe();
      this.persist(empty);
      return empty;
    }
    const me = copyPointsMe(parsed.result);
    this.persist(me);
    return me;
  }

  async checkin(): Promise<CheckinResult> {
    const resp = await HttpClient.postJson('/api/points/checkin', '{}');
    if (resp.body.length === 0) {
      throw new Error(this.parseMessage('', '签到失败'));
    }
    const parsed: JeecgCheckinResp = JSON.parse(resp.body) as JeecgCheckinResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '签到失败');
    if (parsed.result === undefined) {
      throw new Error('签到失败');
    }
    const result = copyCheckinResult(parsed.result);
    AppStorage.setOrCreate('userPoints', mallNum(result.points));
    AppStorage.setOrCreate('userTodayChecked', true);
    AppStorage.setOrCreate('userCheckinStreak', mallNum(result.streak));
    if (result.already !== true) {
      AppStorage.setOrCreate('userTodayReward', mallNum(result.awarded, 10));
    }
    return result;
  }

  private persist(me: PointsMe): void {
    AppStorage.setOrCreate('userPoints', mallNum(me.points));
    AppStorage.setOrCreate('userTodayChecked', me.todayChecked === true);
    AppStorage.setOrCreate('userCheckinStreak', mallNum(me.streak));
    AppStorage.setOrCreate('userTodayReward', mallNum(me.todayReward, 10));
  }

  private ensureOk(success: boolean | undefined, message: string | undefined, ok: boolean, fallback: string): void {
    if (success === false || !ok) {
      const text = mallStr(message);
      throw new Error(text.length > 0 ? text : fallback);
    }
  }

  private parseMessage(body: string, fallback: string): string {
    try {
      const parsed: JeecgCheckinResp = JSON.parse(body) as JeecgCheckinResp;
      const text = mallStr(parsed.message);
      if (text.length > 0) {
        return text;
      }
    } catch (_e) {
    }
    return fallback;
  }
}
