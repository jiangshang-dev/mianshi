/** 把听写草稿收成一道面试官问题。候选人照着念的句子丢掉。 */
export class QuestionSegmenter {
  private lastCommitted: string = '';
  private holdUntil: number = 0;

  hold(ms: number): void {
    this.holdUntil = Date.now() + ms;
  }

  clearHold(): void {
    this.holdUntil = 0;
  }

  /** 返回定稿文本；空字符串表示这一句不提交。 */
  tryCommit(raw: string, answerOnScreen: string, force: boolean): string {
    const cleaned = QuestionSegmenter.clean(raw);
    if (cleaned.length === 0) {
      return '';
    }
    if (!force) {
      if (Date.now() < this.holdUntil && QuestionSegmenter.overlap(cleaned, answerOnScreen) >= 0.45) {
        return '';
      }
      if (cleaned.length < 8) {
        return '';
      }
      if (QuestionSegmenter.overlap(cleaned, answerOnScreen) >= 0.6) {
        return '';
      }
      if (this.lastCommitted.length > 0 && QuestionSegmenter.overlap(cleaned, this.lastCommitted) >= 0.85) {
        return '';
      }
      if (!QuestionSegmenter.looksLikeQuestion(cleaned) && cleaned.length < 16) {
        return '';
      }
    }
    this.lastCommitted = cleaned;
    this.hold(2500);
    return cleaned;
  }

  private static clean(raw: string): string {
    let text = raw.trim();
    const fillers: string[] = ['嗯', '啊', '那个', '就是'];
    for (let i = 0; i < fillers.length; i++) {
      text = text.split(fillers[i]).join('');
    }
    text = text.split(' ').join('').split('\n').join('').split('\t').join('');
    return text.trim();
  }

  private static looksLikeQuestion(text: string): boolean {
    if (text.endsWith('？') || text.endsWith('?') || text.endsWith('吗') || text.endsWith('呢') || text.endsWith('吧')) {
      return true;
    }
    const cues: string[] = ['请你', '介绍一下', '说一下', '怎么理解', '手写', '对比', '为什么', '如何', '什么'];
    for (let i = 0; i < cues.length; i++) {
      if (text.indexOf(cues[i]) >= 0) {
        return true;
      }
    }
    return false;
  }

  private static overlap(a: string, b: string): number {
    if (a.length === 0 || b.length === 0) {
      return 0;
    }
    if (a.indexOf(b) >= 0 || b.indexOf(a) >= 0) {
      const shorter = a.length < b.length ? a.length : b.length;
      const longer = a.length > b.length ? a.length : b.length;
      return shorter / longer;
    }
    const window = a.length < 4 ? a.length : 4;
    if (window === 0) {
      return 0;
    }
    let total = 0;
    let hit = 0;
    for (let i = 0; i + window <= a.length; i += 2) {
      total++;
      if (b.indexOf(a.substring(i, i + window)) >= 0) {
        hit++;
      }
    }
    return total === 0 ? 0 : hit / total;
  }
}
