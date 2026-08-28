export type CommentReloadFn = () => void;

export class CommentUi {
  static readonly COMPOSE = 'commentComposeOpen';
  static readonly DETAIL = 'commentDetailOpen';
  static readonly REPLY_ID = 'commentReplyToId';
  static readonly REPLY_NAME = 'commentReplyToName';
  static readonly DETAIL_ID = 'commentDetailId';
  static readonly QID = 'commentQuestionId';
  static readonly RELOAD = 'commentReloadTick';
  static readonly SHEET = 'commentSheetOpen';
  static readonly FEATURE = 'commentFeatureEnabled';
  private static reloadFns: CommentReloadFn[] = [];

  static init(): void {
    CommentUi.setBool(CommentUi.COMPOSE, false);
    CommentUi.setBool(CommentUi.DETAIL, false);
    CommentUi.setStr(CommentUi.REPLY_ID, '');
    CommentUi.setStr(CommentUi.REPLY_NAME, '');
    CommentUi.setStr(CommentUi.DETAIL_ID, '');
    CommentUi.setStr(CommentUi.QID, '');
    CommentUi.setNum(CommentUi.RELOAD, 0);
    CommentUi.setBool(CommentUi.SHEET, false);
  }

  static setStr(key: string, value: string): void {
    AppStorage.setOrCreate(key, value);
    AppStorage.set(key, value);
  }

  static setBool(key: string, value: boolean): void {
    AppStorage.setOrCreate(key, value);
    AppStorage.set(key, value);
  }

  static setNum(key: string, value: number): void {
    AppStorage.setOrCreate(key, value);
    AppStorage.set(key, value);
  }

  static setQuestionId(id: string): void {
    CommentUi.setStr(CommentUi.QID, id);
  }

  static openCompose(replyId: string, replyName: string): void {
    CommentUi.setStr(CommentUi.REPLY_ID, replyId);
    CommentUi.setStr(CommentUi.REPLY_NAME, replyName);
    CommentUi.setBool(CommentUi.COMPOSE, true);
    CommentUi.setBool(CommentUi.SHEET, true);
  }

  static closeCompose(): void {
    CommentUi.setBool(CommentUi.COMPOSE, false);
    CommentUi.setStr(CommentUi.REPLY_ID, '');
    CommentUi.setStr(CommentUi.REPLY_NAME, '');
    const detailOn = AppStorage.get(CommentUi.DETAIL) as boolean;
    CommentUi.setBool(CommentUi.SHEET, detailOn === true);
  }

  static openDetail(id: string): void {
    CommentUi.setStr(CommentUi.DETAIL_ID, id);
    CommentUi.setBool(CommentUi.DETAIL, true);
    CommentUi.setBool(CommentUi.COMPOSE, false);
    CommentUi.setBool(CommentUi.SHEET, true);
  }

  static closeDetail(): void {
    CommentUi.setBool(CommentUi.DETAIL, false);
    CommentUi.setStr(CommentUi.DETAIL_ID, '');
    CommentUi.setBool(CommentUi.COMPOSE, false);
    CommentUi.setBool(CommentUi.SHEET, false);
  }

  static addReloadListener(fn: CommentReloadFn): void {
    CommentUi.reloadFns.push(fn);
  }

  static removeReloadListener(fn: CommentReloadFn): void {
    const next: CommentReloadFn[] = [];
    for (let i = 0; i < CommentUi.reloadFns.length; i++) {
      if (CommentUi.reloadFns[i] !== fn) {
        next.push(CommentUi.reloadFns[i]);
      }
    }
    CommentUi.reloadFns = next;
  }

  static bumpReload(): void {
    CommentUi.setNum(CommentUi.RELOAD, Date.now());
    const fns = CommentUi.reloadFns;
    for (let i = 0; i < fns.length; i++) {
      fns[i]();
    }
  }

  static shortTime(raw: string, month: string, day: string, today: string): string {
    if (raw.length < 10) {
      return raw;
    }
    const y = Number.parseInt(raw.substring(0, 4), 10);
    const m = Number.parseInt(raw.substring(5, 7), 10);
    const d = Number.parseInt(raw.substring(8, 10), 10);
    const now = new Date();
    if (y === now.getFullYear() && m === now.getMonth() + 1 && d === now.getDate()) {
      return raw.length >= 16 ? raw.substring(11, 16) : today;
    }
    if (y === now.getFullYear()) {
      return `${m}${month}${d}${day}`;
    }
    return raw.substring(0, 10);
  }
}
