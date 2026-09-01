import { mallNum, mallStr } from './MallTypes';

export interface CheckinDay {
  day?: number;
  points?: number;
  reached?: boolean;
}

export interface MemberBonus {
  code?: string;
  name?: string;
  bonusPoints?: number;
}

export interface PointsLedgerRow {
  id?: string;
  changeAmount?: number;
  balanceAfter?: number;
  bizType?: string;
  remark?: string;
  createTime?: string;
}

export interface PointsMe {
  points?: number;
  streak?: number;
  todayChecked?: boolean;
  cycleDay?: number;
  todayReward?: number;
  studyMinutes?: number;
  studyPointsToday?: number;
  studyBucketMinutes?: number;
  studyPointsPerBucket?: number;
  studyMaxBuckets?: number;
  week?: CheckinDay[];
  memberBonuses?: MemberBonus[];
  recent?: PointsLedgerRow[];
}

export interface CheckinResult {
  points?: number;
  awarded?: number;
  streak?: number;
  cycleDay?: number;
  already?: boolean;
}

export interface JeecgPointsMeResp {
  success?: boolean;
  message?: string;
  result?: PointsMe;
  code?: number;
}

export interface JeecgCheckinResp {
  success?: boolean;
  message?: string;
  result?: CheckinResult;
  code?: number;
}

export function emptyPointsMe(): PointsMe {
  const week: CheckinDay[] = [];
  const bonuses: MemberBonus[] = [];
  const recent: PointsLedgerRow[] = [];
  const me: PointsMe = {
    points: 0,
    streak: 0,
    todayChecked: false,
    cycleDay: 1,
    todayReward: 10,
    studyMinutes: 0,
    studyPointsToday: 0,
    studyBucketMinutes: 10,
    studyPointsPerBucket: 5,
    studyMaxBuckets: 6,
    week: week,
    memberBonuses: bonuses,
    recent: recent
  };
  return me;
}

export function copyCheckinDay(raw: CheckinDay): CheckinDay {
  const item: CheckinDay = {
    day: mallNum(raw.day),
    points: mallNum(raw.points),
    reached: raw.reached === true
  };
  return item;
}

export function copyMemberBonus(raw: MemberBonus): MemberBonus {
  const item: MemberBonus = {
    code: mallStr(raw.code),
    name: mallStr(raw.name),
    bonusPoints: mallNum(raw.bonusPoints)
  };
  return item;
}

export function copyLedgerRow(raw: PointsLedgerRow): PointsLedgerRow {
  const item: PointsLedgerRow = {
    id: mallStr(raw.id),
    changeAmount: mallNum(raw.changeAmount),
    balanceAfter: mallNum(raw.balanceAfter),
    bizType: mallStr(raw.bizType),
    remark: mallStr(raw.remark),
    createTime: mallStr(raw.createTime)
  };
  return item;
}

export function copyPointsMe(raw: PointsMe): PointsMe {
  const me = emptyPointsMe();
  me.points = mallNum(raw.points);
  me.streak = mallNum(raw.streak);
  me.todayChecked = raw.todayChecked === true;
  me.cycleDay = mallNum(raw.cycleDay, 1);
  me.todayReward = mallNum(raw.todayReward, 10);
  me.studyMinutes = mallNum(raw.studyMinutes);
  me.studyPointsToday = mallNum(raw.studyPointsToday);
  me.studyBucketMinutes = mallNum(raw.studyBucketMinutes, 10);
  me.studyPointsPerBucket = mallNum(raw.studyPointsPerBucket, 5);
  me.studyMaxBuckets = mallNum(raw.studyMaxBuckets, 6);
  const week: CheckinDay[] = [];
  if (raw.week !== undefined) {
    for (let i = 0; i < raw.week.length; i++) {
      try {
        week.push(copyCheckinDay(raw.week[i]));
      } catch (_e) {
      }
    }
  }
  me.week = week;
  const bonuses: MemberBonus[] = [];
  if (raw.memberBonuses !== undefined) {
    for (let i = 0; i < raw.memberBonuses.length; i++) {
      try {
        bonuses.push(copyMemberBonus(raw.memberBonuses[i]));
      } catch (_e) {
      }
    }
  }
  me.memberBonuses = bonuses;
  const recent: PointsLedgerRow[] = [];
  if (raw.recent !== undefined) {
    for (let i = 0; i < raw.recent.length; i++) {
      try {
        recent.push(copyLedgerRow(raw.recent[i]));
      } catch (_e) {
      }
    }
  }
  me.recent = recent;
  return me;
}

export function copyCheckinResult(raw: CheckinResult): CheckinResult {
  const item: CheckinResult = {
    points: mallNum(raw.points),
    awarded: mallNum(raw.awarded),
    streak: mallNum(raw.streak),
    cycleDay: mallNum(raw.cycleDay, 1),
    already: raw.already === true
  };
  return item;
}

export function pointsChangeText(amount?: number): string {
  const v = mallNum(amount);
  if (v > 0) {
    return `+${v}`;
  }
  return `${v}`;
}
