import { AppConfig } from '../../common/constants/AppConfig';
import { QuestionItem } from '../../common/models/Types';
import { HttpClient } from '../../common/network/HttpClient';

interface RemoteQuestionDto {
  id: string;
  title: string;
  categoryId: string;
  categoryName: string;
  tags: string[];
  difficulty: string;
  hot: boolean;
  answer: string;
  interviewAnswer?: string;
  knowledgePoints?: string[];
}

interface RemoteListResponse {
  code: number;
  data: RemoteQuestionDto[];
}

interface RemoteDetailResponse {
  code: number;
  data: RemoteQuestionDto;
}

interface AiChatRequest {
  questionId: string;
  title: string;
  message: string;
}

interface AiChatData {
  reply?: string;
}

interface AiChatResponse {
  data?: AiChatData;
}

/** 远程 API 题库；失败时按配置降级 Mock */
export class RemoteApiDataSource {
  async listByCategory(categoryId: string): Promise<QuestionItem[]> {
    const query = `categoryId=${encodeURIComponent(categoryId)}`;
    const resp = await HttpClient.get('/api/questions', query);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteListResponse;
        if (parsed.data && parsed.data.length > 0) {
          return parsed.data.map((d: RemoteQuestionDto) => this.toQuestion(d));
        }
      } catch (_e) {
      }
    }
    if (AppConfig.REMOTE_USE_MOCK_FALLBACK) {
      return this.mockList(categoryId);
    }
    return [];
  }

  async getDetail(questionId: string): Promise<QuestionItem | null> {
    const resp = await HttpClient.get(`/api/questions/${questionId}`);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteDetailResponse;
        if (parsed.data) {
          return this.toQuestion(parsed.data);
        }
      } catch (_e) {
      }
    }
    if (AppConfig.REMOTE_USE_MOCK_FALLBACK) {
      const all = this.mockList('api.hot.java100');
      const found = all.find((q: QuestionItem) => q.id === questionId);
      return found !== undefined ? found : all[0];
    }
    return null;
  }

  async search(keyword: string): Promise<QuestionItem[]> {
    const query = `q=${encodeURIComponent(keyword)}`;
    const resp = await HttpClient.get('/api/questions/search', query);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteListResponse;
        if (parsed.data) {
          return parsed.data.map((d: RemoteQuestionDto) => this.toQuestion(d));
        }
      } catch (_e) {
      }
    }
    if (AppConfig.REMOTE_USE_MOCK_FALLBACK) {
      const key = keyword.toLowerCase();
      return this.mockList('api.hot.java100').filter((q: QuestionItem) =>
        q.title.toLowerCase().includes(key) ||
          q.tags.some((t: string) => t.toLowerCase().includes(key)));
    }
    return [];
  }

  async askAi(questionId: string, title: string, userMessage: string): Promise<string> {
    const req: AiChatRequest = {
      questionId: questionId,
      title: title,
      message: userMessage
    };
    const resp = await HttpClient.postJson('/api/ai/chat', JSON.stringify(req));
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as AiChatResponse;
        if (parsed.data && parsed.data.reply) {
          return parsed.data.reply;
        }
      } catch (_e) {
      }
    }
    return `（离线演示）关于「${title}」：\n\n你问的是「${userMessage}」。\n\n` +
      '后端 AI 接入后，会结合当前题目上下文给出解释、举例和面试回答建议。';
  }

  private toQuestion(d: RemoteQuestionDto): QuestionItem {
    return {
      id: d.id,
      title: d.title,
      categoryId: d.categoryId,
      categoryName: d.categoryName,
      tags: d.tags ?? [],
      difficulty: d.difficulty || '中级',
      hot: d.hot,
      source: 'remote_api',
      content: d.answer,
      interviewAnswer: d.interviewAnswer,
      knowledgePoints: d.knowledgePoints,
      mastery: 0,
      favorited: false
    };
  }

  private mockList(categoryId: string): QuestionItem[] {
    const company = categoryId.includes('alibaba') ? '阿里' :
      categoryId.includes('bytedance') ? '字节' :
        categoryId.includes('tencent') ? '腾讯' :
          categoryId.includes('meituan') ? '美团' : '大厂';

    if (categoryId.includes('redis') || categoryId.includes('hot.redis')) {
      return [
        this.mockQ('api-redis-1', 'Redis 为什么这么快？', 'Redis', ['Redis', '高频'],
          '纯内存、单线程事件循环 + IO 多路复用、高效数据结构、RESP 协议。',
          '我觉得 Redis 快主要有四点：内存、单线程、数据结构优化、协议简单。'),
        this.mockQ('api-redis-2', '缓存穿透、击穿、雪崩怎么解决？', 'Redis', ['缓存', '高频'],
          '穿透：空值/布隆；击穿：互斥锁/逻辑过期；雪崩：过期打散/多级缓存/限流。',
          '先区分三个概念，再分别讲方案和项目落地。'),
        this.mockQ('api-redis-3', 'Redisson 分布式锁与看门狗', 'Redis', ['分布式锁'],
          '看门狗在持锁线程存活时续期，避免业务未完成锁过期。',
          'SET NX PX + Lua 释放，以及 Redisson 看门狗续期。')
      ];
    }

    return [
      this.mockQ('api-java-1', `${company}常考：HashMap 底层结构`, 'Java', ['集合', '高频'],
        'JDK1.8 后：数组 + 链表 + 红黑树；树化阈值 8，退化 6；扩容 2 倍。',
        'HashMap 在 1.8 后是数组加链表或红黑树，顺着 put、hash、扩容讲。'),
      this.mockQ('api-java-2', `${company}常考：JVM 垃圾回收`, 'JVM', ['JVM'],
        '分代回收；Serial/Parallel/CMS/G1/ZGC；关注 STW 与吞吐/延迟权衡。',
        '先讲分代假设，再对比吞吐优先和低延迟收集器。'),
      this.mockQ('api-java-3', `${company}常考：Spring Boot 自动装配`, 'Spring', ['Spring Boot'],
        '@EnableAutoConfiguration + spring.factories / AutoConfiguration.imports 条件装配。',
        '核心是条件注解决定是否装配，结合 starter 例子说明。'),
      this.mockQ('api-java-4', `${company}常考：MySQL 索引失效`, 'MySQL', ['MySQL', '高频'],
        '违反最左前缀、对索引列运算、隐式转换、like 左模糊、优化器放弃索引等。',
        '先讲 B+Tree，再举失效 case，并用 Explain 验证。')
    ];
  }

  private mockQ(id: string, title: string, categoryName: string, tags: string[],
    answer: string, interview: string): QuestionItem {
    return {
      id,
      title,
      categoryId: 'api.hot',
      categoryName,
      tags,
      difficulty: '高频',
      hot: true,
      source: 'remote_api',
      content: answer,
      interviewAnswer: interview,
      knowledgePoints: tags,
      mastery: 0,
      favorited: false
    };
  }
}
