import {
  InterviewConfig,
  InterviewMessage,
  InterviewReport
} from '../../common/models/InterviewTypes';

interface QuestionBankItem {
  question: string;
  topic: string;
  keywords: string[];
  followUp: string;
}

/** 本地模拟面试引擎：出题 / 追问 / 评分 */
export class InterviewEngine {
  private config: InterviewConfig;
  private questionIndex: number = 0;
  private answeredCount: number = 0;
  private totalScore: number = 0;
  private waitingFollowUp: boolean = false;
  private currentItem: QuestionBankItem | null = null;
  private finished: boolean = false;
  private questions: QuestionBankItem[] = [];

  constructor(config: InterviewConfig) {
    this.config = config;
    this.questions = this.buildQuestionBank();
  }

  isFinished(): boolean {
    return this.finished;
  }

  getOpening(): InterviewMessage {
    return this.makeMsg('interviewer',
      `你好，我是今天的 AI 面试官。我们面试的是「${this.config.role}」岗位，` +
        `你的经验是「${this.config.level}」，难度「${this.config.difficulty}」。\n\n` +
        '请先做一个 1 分钟左右的自我介绍，可以从技术栈、项目经历和优势说起。');
  }

  getFirstQuestion(): InterviewMessage {
    return this.nextQuestionMsg();
  }

  submitAnswer(answer: string): InterviewMessage[] {
    const text = answer.trim();
    if (text.length === 0) {
      return [this.makeMsg('system', '请先输入或说出你的回答。')];
    }
    if (this.finished) {
      return [this.makeMsg('system', '面试已结束，可查看报告。')];
    }

    const result: InterviewMessage[] = [];
    result.push(this.makeMsg('candidate', text));

    if (this.questionIndex === 0 && this.answeredCount === 0 && !this.waitingFollowUp) {
      // 自我介绍阶段
      const introScore = this.scoreIntro(text);
      this.totalScore += introScore;
      this.answeredCount++;
      result.push(this.makeMsg('interviewer',
        introScore >= 70 ?
          '自我介绍比较清晰。接下来进入技术问题环节。' :
          '自我介绍可以再突出项目亮点和技术深度。我们进入技术问题。'));
      result.push(this.nextQuestionMsg());
      return result;
    }

    if (this.waitingFollowUp && this.currentItem) {
      const followScore = this.scoreAnswer(text, this.currentItem.keywords);
      this.totalScore += followScore;
      this.answeredCount++;
      this.waitingFollowUp = false;
      result.push(this.makeMsg('interviewer', this.buildFeedback(followScore)));
      if (this.questionIndex >= this.questions.length) {
        this.finished = true;
        result.push(this.makeMsg('interviewer', this.buildClosing()));
        return result;
      }
      result.push(this.nextQuestionMsg());
      return result;
    }

    if (this.currentItem) {
      const score = this.scoreAnswer(text, this.currentItem.keywords);
      this.totalScore += score;
      this.answeredCount++;
      if (score < 75 && !this.waitingFollowUp) {
        this.waitingFollowUp = true;
        result.push(this.makeMsg('interviewer',
          `${this.buildFeedback(score)}\n\n追问：${this.currentItem.followUp}`));
        return result;
      }
      result.push(this.makeMsg('interviewer', this.buildFeedback(score)));
      if (this.questionIndex >= this.questions.length) {
        this.finished = true;
        result.push(this.makeMsg('interviewer', this.buildClosing()));
        return result;
      }
      result.push(this.nextQuestionMsg());
    }
    return result;
  }

  getReport(): InterviewReport {
    const avg = this.answeredCount > 0 ? Math.round(this.totalScore / this.answeredCount) : 60;
    const score = Math.min(100, Math.max(50, avg));
    return {
      score,
      accuracy: Math.min(100, score + 5),
      depth: Math.max(50, score - 8),
      expression: Math.min(100, score + 3),
      advantages: score >= 75 ?
        ['表达较流畅', '能覆盖关键知识点', '有项目结合意识'] :
        ['态度积极', '基础概念有涉及'],
      problems: score >= 75 ?
        ['部分追问可再深入', '可补充量化指标'] :
        ['技术细节不够完整', '建议结合项目举例', '追问环节可再展开'],
      suggestions: [
        '针对薄弱题回到题库专项练习',
        '用「结论 + 原理 + 例子」结构回答',
        '建议再做一次同岗位模拟面试'
      ]
    };
  }

  private nextQuestionMsg(): InterviewMessage {
    if (this.questionIndex >= this.questions.length) {
      this.finished = true;
      return this.makeMsg('interviewer', this.buildClosing());
    }
    this.currentItem = this.questions[this.questionIndex];
    this.questionIndex++;
    return this.makeMsg('interviewer',
      `第 ${this.questionIndex} 题（${this.currentItem.topic}）：\n${this.currentItem.question}`);
  }

  private buildClosing(): string {
    const report = this.getReport();
    return `本次模拟面试结束，综合得分 ${report.score} 分。\n\n` +
      `优势：${report.advantages.join('；')}\n` +
      `待提升：${report.problems.join('；')}\n\n` +
      '可返回题库继续针对性学习。';
  }

  private scoreIntro(text: string): number {
    let score = 55;
    if (text.length >= 40) {
      score += 10;
    }
    if (text.length >= 100) {
      score += 10;
    }
    const hints = ['项目', '负责', 'Java', 'Spring', '经验', '优化', '团队'];
    hints.forEach((h: string) => {
      if (text.includes(h)) {
        score += 5;
      }
    });
    return Math.min(95, score);
  }

  private scoreAnswer(text: string, keywords: string[]): number {
    let score = 50;
    if (text.length >= 30) {
      score += 10;
    }
    if (text.length >= 80) {
      score += 10;
    }
    let hit = 0;
    keywords.forEach((k: string) => {
      if (text.toLowerCase().includes(k.toLowerCase())) {
        hit++;
      }
    });
    score += hit * 8;
    if (this.config.difficulty === '大厂') {
      score -= 5;
    }
    return Math.min(98, Math.max(45, score));
  }

  private buildFeedback(score: number): string {
    if (score >= 85) {
      return '回答不错，关键点覆盖较完整，表达也比较清晰。';
    }
    if (score >= 70) {
      return '回答基本正确，可以再补充原理细节或项目案例。';
    }
    return '这个点还没有完全讲透，建议从定义、原理、使用场景三个层次组织答案。';
  }

  private buildQuestionBank(): QuestionBankItem[] {
    const role = this.config.role;
    const base: QuestionBankItem[] = [
      {
        question: 'HashMap 在 JDK 1.8 中的底层结构是什么？扩容机制了解吗？',
        topic: 'Java 集合',
        keywords: ['数组', '链表', '红黑树', '扩容', 'hash'],
        followUp: '为什么链表长度到 8 会树化？退化阈值为什么是 6？'
      },
      {
        question: 'JVM 内存结构有哪些？垃圾回收算法你熟悉哪些？',
        topic: 'JVM',
        keywords: ['堆', '栈', '方法区', 'G1', 'CMS', '标记', '回收'],
        followUp: 'G1 和 CMS 的区别是什么？什么场景选 G1？'
      },
      {
        question: 'Spring Boot 自动装配的原理是什么？',
        topic: 'Spring',
        keywords: ['EnableAutoConfiguration', 'spring.factories', '条件注解', 'starter'],
        followUp: '如果让你自定义一个 Starter，你会怎么设计？'
      },
      {
        question: 'Redis 为什么这么快？缓存穿透、击穿、雪崩怎么解决？',
        topic: 'Redis',
        keywords: ['内存', '单线程', 'IO多路复用', '布隆', '互斥锁', '过期'],
        followUp: '如果用分布式锁解决缓存击穿，需要注意什么？'
      },
      {
        question: 'MySQL 索引为什么用 B+ 树？什么情况下索引会失效？',
        topic: 'MySQL',
        keywords: ['B+树', '最左前缀', 'Explain', '回表', '覆盖索引'],
        followUp: '联合索引 (a,b,c)，where a=1 and c=3 能用到索引吗？'
      }
    ];

    if (role.includes('AI')) {
      base.push({
        question: 'RAG 的基本流程是什么？如何解决幻觉问题？',
        topic: 'AI / RAG',
        keywords: ['Embedding', '向量', '检索', '重排', 'Prompt', '知识库'],
        followUp: '如果检索结果不相关，你会怎么优化？'
      });
    }

    const count = this.config.difficulty === '大厂' ? 5 :
      this.config.difficulty === '困难' ? 4 : 3;
    return base.slice(0, count);
  }

  private makeMsg(role: 'interviewer' | 'candidate' | 'system', content: string): InterviewMessage {
    const now = new Date();
    const hh = now.getHours().toString().padStart(2, '0');
    const mm = now.getMinutes().toString().padStart(2, '0');
    return {
      id: `${Date.now()}-${Math.random()}`,
      role,
      content,
      time: `${hh}:${mm}`
    };
  }
}
