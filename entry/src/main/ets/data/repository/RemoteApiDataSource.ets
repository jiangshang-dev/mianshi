import { AppConfig } from '../../common/constants/AppConfig';
import { Category, QuestionItem, SubCategory, AiStreamSnapshot, TodayStudyStats } from '../../common/models/Types';
import { HttpClient, SseAbort } from '../../common/network/HttpClient';

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
  result?: RemoteQuestionDto[];
  data?: RemoteQuestionDto[];
}

interface RemoteDetailResponse {
  code: number;
  result?: RemoteQuestionDto;
  data?: RemoteQuestionDto;
}

interface AiChatRequest {
  questionId: string;
  title: string;
  message: string;
  userId?: string;
  sessionId?: string;
}

interface AiChatData {
  reply?: string;
}

interface AiChatResponse {
  result?: AiChatData;
  data?: AiChatData;
}

interface RemoteSubCategoryDto {
  id: string;
  name: string;
  parentId: string;
  path?: string;
  articleCount?: number;
}

interface RemoteCategoryDto {
  id: string;
  name: string;
  icon?: string;
  order?: number;
  group?: string;
  parentId?: string;
  articleCount?: number;
  children?: RemoteSubCategoryDto[];
}

interface RemoteCategoryListResponse {
  code: number;
  result?: RemoteCategoryDto[];
  data?: RemoteCategoryDto[];
}

interface RemoteHotResponse {
  code: number;
  result?: RemoteQuestionDto[];
  data?: RemoteQuestionDto[];
}

interface RemoteTodayStudyDto {
  questionCount?: number;
  minutes?: number;
  mastered?: number;
  toReview?: number;
}

interface RemoteTodayStudyResponse {
  code: number;
  result?: RemoteTodayStudyDto;
  data?: RemoteTodayStudyDto;
}

/** 远程 API 题库；仅当 REMOTE_USE_MOCK_FALLBACK 开启时才降级 Mock */
export class RemoteApiDataSource {
  async listCategories(): Promise<Category[]> {
    const resp = await HttpClient.get('/api/categories', '');
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteCategoryListResponse;
        const list = parsed.result ?? parsed.data;
        if (list) {
          return list.map((d: RemoteCategoryDto) => this.toCategory(d));
        }
      } catch (_e) {
      }
    }
    if (AppConfig.REMOTE_USE_MOCK_FALLBACK) {
      return this.mockCategories();
    }
    return [];
  }

  async getHotQuestions(limit: number = 8): Promise<QuestionItem[]> {
    const query = `limit=${limit}`;
    const resp = await HttpClient.get('/api/questions/hot', query);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteHotResponse;
        const list = parsed.result ?? parsed.data;
        if (list) {
          return list.map((d: RemoteQuestionDto) => this.toQuestion(d));
        }
      } catch (_e) {
      }
    }
    if (AppConfig.REMOTE_USE_MOCK_FALLBACK) {
      const all = this.mockList('api.hot.java100');
      const redis = this.mockList('api.hot.redis50');
      const merged: QuestionItem[] = [];
      all.forEach((q: QuestionItem) => merged.push(q));
      redis.forEach((q: QuestionItem) => merged.push(q));
      return merged.slice(0, limit);
    }
    return [];
  }

  async getTodayStudy(userId: string): Promise<TodayStudyStats> {
    const empty: TodayStudyStats = {
      questionCount: 0,
      minutes: 0,
      mastered: 0,
      toReview: 0
    };
    if (userId.length === 0) {
      return empty;
    }
    const resp = await HttpClient.get('/api/study/today', `userId=${encodeURIComponent(userId)}`);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteTodayStudyResponse;
        const d = parsed.result ?? parsed.data;
        if (d) {
          return {
            questionCount: d.questionCount ?? 0,
            minutes: d.minutes ?? 0,
            mastered: d.mastered ?? 0,
            toReview: d.toReview ?? 0
          };
        }
      } catch (_e) {
      }
    }
    return empty;
  }

  async recordQuestionView(userId: string, questionId: string): Promise<TodayStudyStats | null> {
    if (userId.length === 0 || questionId.length === 0) {
      return null;
    }
    const resp = await HttpClient.postJson('/api/study/view', JSON.stringify({
      userId: userId,
      questionId: questionId
    }));
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteTodayStudyResponse;
        const d = parsed.result ?? parsed.data;
        if (d) {
          return {
            questionCount: d.questionCount ?? 0,
            minutes: d.minutes ?? 0,
            mastered: d.mastered ?? 0,
            toReview: d.toReview ?? 0
          };
        }
      } catch (_e) {
      }
    }
    return null;
  }

  async listByCategory(categoryId: string): Promise<QuestionItem[]> {
    const query = `categoryId=${encodeURIComponent(categoryId)}`;
    const resp = await HttpClient.get('/api/questions', query);
    if (resp.ok) {
      try {
        const parsed = JSON.parse(resp.body) as RemoteListResponse;
        const list = parsed.result ?? parsed.data;
        if (list) {
          return list.map((d: RemoteQuestionDto) => this.toQuestion(d));
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
        const item = parsed.result ?? parsed.data;
        if (item) {
          return this.toQuestion(item);
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
        const list = parsed.result ?? parsed.data;
        if (list) {
          return list.map((d: RemoteQuestionDto) => this.toQuestion(d));
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

  async askAiStream(questionId: string, title: string, userMessage: string,
    onUpdate: (snap: AiStreamSnapshot) => void, abort?: SseAbort, sessionId?: string): Promise<string> {
    const uid = AppStorage.get('userId') as string;
    const req: AiChatRequest = {
      questionId: questionId,
      title: title,
      message: userMessage,
      userId: uid !== undefined ? uid : '',
      sessionId: sessionId !== undefined ? sessionId : ''
    };
    const resp = await HttpClient.postSse('/api/ai/chat', JSON.stringify(req), onUpdate, abort);
    if (abort?.stopped) {
      return resp.body;
    }
    if (resp.body.length > 0) {
      return resp.body;
    }
    const err = resp.message.length > 0 ? resp.message : 'AI 流式请求失败';
    onUpdate({ thinking: '', markdown: err, phase: 'error', thinkingDone: false, sessionId: '' });
    return err;
  }

  async askAi(questionId: string, title: string, userMessage: string): Promise<string> {
    const uid = AppStorage.get('userId') as string;
    const req: AiChatRequest = {
      questionId: questionId,
      title: title,
      message: userMessage,
      userId: uid !== undefined ? uid : ''
    };
    const resp = await HttpClient.postJson('/api/ai/chat', JSON.stringify(req));
    if (resp.ok) {
      const streamed = this.parseSseReply(resp.body);
      if (streamed) {
        return streamed;
      }
      try {
        const parsed = JSON.parse(resp.body) as AiChatResponse;
        const payload = parsed.result ?? parsed.data;
        if (payload && payload.reply) {
          return payload.reply;
        }
      } catch (_e) {
      }
    }
    return `（离线演示）关于「${title}」：\n\n你问的是「${userMessage}」。\n\n` +
      '后端 AI 接入后，会结合当前题目上下文给出解释、举例和面试回答建议。';
  }

  private parseSseReply(body: string): string {
    if (!body || body.indexOf('data:') < 0) {
      return '';
    }
    const lines = body.split('\n');
    let lastReply = '';
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.indexOf('data:') !== 0) {
        continue;
      }
      const json = line.substring(5).trim();
      try {
        const chunk = JSON.parse(json) as Record<string, string | boolean>;
        if (chunk.markdown && ('done' === chunk.type || chunk.done)) {
          lastReply = `${chunk.markdown}`;
        } else if (chunk.reply) {
          lastReply = `${chunk.reply}`;
        }
      } catch (_e) {
      }
    }
    return lastReply;
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

  private toCategory(d: RemoteCategoryDto): Category {
    const children: SubCategory[] = [];
    if (d.children) {
      d.children.forEach((child: RemoteSubCategoryDto) => {
        children.push({
          id: child.id,
          name: child.name,
          parentId: child.parentId,
          path: child.path ?? '',
          source: 'remote_api',
          articleCount: child.articleCount ?? 0
        });
      });
    }
    return {
      id: d.id,
      name: d.name,
      icon: d.icon ?? '📘',
      order: d.order ?? 0,
      group: d.group ?? '技能',
      source: 'remote_api',
      articleCount: d.articleCount ?? 0,
      children
    };
  }

  private mockCategories(): Category[] {
    const mkSub = (id: string, name: string, parentId: string, count: number): SubCategory => ({
      id, name, parentId, path: id, source: 'remote_api', articleCount: count
    });
    return [
      {
        id: 'java', name: 'Java', icon: '☕', order: 1, group: '技能', source: 'remote_api',
        articleCount: 73,
        children: [
          mkSub('java.basis', '基础', 'java', 14),
          mkSub('java.collection', 'Java 集合', 'java', 12),
          mkSub('java.concurrent', 'Java 并发', 'java', 16),
          mkSub('java.jvm', 'JVM', 'java', 10)
        ]
      },
      {
        id: 'database', name: '数据库', icon: '🗄️', order: 2, group: '技能', source: 'remote_api',
        articleCount: 41,
        children: [
          mkSub('database.mysql', 'MySQL', 'database', 16),
          mkSub('database.redis', 'Redis', 'database', 13),
          mkSub('database.sql', 'SQL', 'database', 6)
        ]
      },
      {
        id: 'cs-basics', name: '计算机基础', icon: '💻', order: 3, group: '技能', source: 'remote_api',
        articleCount: 63,
        children: [mkSub('cs-basics.os', '操作系统', 'cs-basics', 20)]
      },
      {
        id: 'system-design', name: '系统设计', icon: '🏗️', order: 4, group: '技能', source: 'remote_api',
        articleCount: 31,
        children: [mkSub('system-design.arch', '架构设计', 'system-design', 15)]
      },
      {
        id: 'distributed', name: '分布式', icon: '🌐', order: 5, group: '技能', source: 'remote_api',
        articleCount: 24,
        children: [mkSub('distributed.lock', '分布式锁', 'distributed', 8)]
      },
      {
        id: 'high-performance', name: '高性能', icon: '⚡', order: 6, group: '技能', source: 'remote_api',
        articleCount: 13,
        children: []
      },
      {
        id: 'high-availability', name: '高可用', icon: '🛡️', order: 7, group: '技能', source: 'remote_api',
        articleCount: 8,
        children: []
      },
      {
        id: 'ai', name: 'AI / LLM', icon: '🤖', order: 8, group: '技能', source: 'remote_api',
        articleCount: 33,
        children: [mkSub('ai.agent', 'Agent', 'ai', 12), mkSub('ai.rag', 'RAG', 'ai', 10)]
      },
      {
        id: 'api.company', name: '公司题库', icon: '🏢', order: 9, group: '公司', source: 'remote_api',
        articleCount: 16,
        children: [
          mkSub('api.company.alibaba', '阿里巴巴', 'api.company', 4),
          mkSub('api.company.bytedance', '字节跳动', 'api.company', 4),
          mkSub('api.company.tencent', '腾讯', 'api.company', 4),
          mkSub('api.company.meituan', '美团', 'api.company', 4)
        ]
      },
      {
        id: 'api.hot', name: '高频精选', icon: '🔥', order: 10, group: '专项', source: 'remote_api',
        articleCount: 7,
        children: [
          mkSub('api.hot.java100', 'Java 高频 100 题', 'api.hot', 4),
          mkSub('api.hot.redis50', 'Redis 高频 50 题', 'api.hot', 3)
        ]
      }
    ];
  }

  private mockList(categoryId: string): QuestionItem[] {
    const company = categoryId.includes('alibaba') ? '阿里' :
      categoryId.includes('bytedance') ? '字节' :
        categoryId.includes('tencent') ? '腾讯' :
          categoryId.includes('meituan') ? '美团' : '大厂';

    if (categoryId.includes('redis') || categoryId.includes('hot.redis') || categoryId.includes('database.redis')) {
      return [
        this.mockQ('api-redis-1', 'Redis 为什么这么快？', 'Redis', ['Redis', '高频'],
          '纯内存、单线程事件循环 + IO 多路复用、高效数据结构、RESP 协议。',
          '我觉得 Redis 快主要有四点：内存、单线程、数据结构优化、协议简单。', categoryId),
        this.mockQ('api-redis-2', '缓存穿透、击穿、雪崩怎么解决？', 'Redis', ['缓存', '高频'],
          '穿透：空值/布隆；击穿：互斥锁/逻辑过期；雪崩：过期打散/多级缓存/限流。',
          '先区分三个概念，再分别讲方案和项目落地。', categoryId),
        this.mockQ('api-redis-3', 'Redisson 分布式锁与看门狗', 'Redis', ['分布式锁'],
          '看门狗在持锁线程存活时续期，避免业务未完成锁过期。',
          'SET NX PX + Lua 释放，以及 Redisson 看门狗续期。', categoryId)
      ];
    }

    if (categoryId.includes('ai') || categoryId.includes('agent') || categoryId.includes('rag')) {
      return [
        this.mockQ('api-ai-1', 'RAG 的基本流程是什么？', 'AI / RAG', ['RAG', '高频'],
          '文档切分 → Embedding → 向量检索 → 重排 → Prompt 注入 → LLM 生成。',
          '从知识库构建、检索增强到生成回答完整讲一遍。', categoryId),
        this.mockQ('api-ai-2', 'AI Agent 的核心概念有哪些？', 'AI Agent', ['Agent', '高频'],
          'Agent Loop、Plan-and-Execute、Tool Use、A2A 协作等。',
          '结合一个你熟悉的 Agent 框架说明执行循环。', categoryId)
      ];
    }

    if (categoryId.includes('mysql') || categoryId.includes('database')) {
      return [
        this.mockQ('api-db-1', 'MySQL 索引为什么用 B+ 树？', 'MySQL', ['MySQL', '索引'],
          'B+ 树适合磁盘 IO、范围查询、叶子节点链表。',
          '对比 B 树和 Hash，说明 InnoDB 选型原因。', categoryId),
        this.mockQ('api-db-2', '什么情况下索引会失效？', 'MySQL', ['MySQL', '索引'],
          '违反最左前缀、对列运算、隐式转换、like 左模糊等。',
          '结合 Explain 举例说明。', categoryId)
      ];
    }

    if (categoryId.startsWith('java') || categoryId === 'java') {
      return [
        this.mockQ('api-java-1', 'HashMap 在 JDK 1.8 中的底层结构？', 'Java', ['集合', '高频'],
          'JDK1.8 后：数组 + 链表 + 红黑树；树化阈值 8，退化 6；扩容 2 倍。',
          'HashMap 在 1.8 后是数组加链表或红黑树，顺着 put、hash、扩容讲。', categoryId),
        this.mockQ('api-java-2', 'JVM 内存结构有哪些？', 'JVM', ['JVM'],
          '堆、栈、方法区/元空间、程序计数器、本地方法栈。',
          '先讲运行时数据区，再讲 GC 发生在哪些区域。', categoryId),
        this.mockQ('api-java-3', 'synchronized 和 ReentrantLock 区别？', 'Java 并发', ['并发'],
          'synchronized JVM 内置；ReentrantLock 可中断、公平锁、Condition。',
          '从使用方式、底层实现、适用场景对比。', categoryId)
      ];
    }

    if (categoryId.includes('alibaba') || categoryId.includes('bytedance') ||
      categoryId.includes('tencent') || categoryId.includes('meituan') || categoryId.includes('api.company')) {
      return [
        this.mockQ('api-java-1', `${company}常考：HashMap 底层结构`, 'Java', ['集合', '高频'],
          'JDK1.8 后：数组 + 链表 + 红黑树；树化阈值 8，退化 6；扩容 2 倍。',
          'HashMap 在 1.8 后是数组加链表或红黑树，顺着 put、hash、扩容讲。', categoryId),
        this.mockQ('api-java-2', `${company}常考：JVM 垃圾回收`, 'JVM', ['JVM'],
          '分代回收；Serial/Parallel/CMS/G1/ZGC；关注 STW 与吞吐/延迟权衡。',
          '先讲分代假设，再对比吞吐优先和低延迟收集器。', categoryId),
        this.mockQ('api-java-3', `${company}常考：Spring Boot 自动装配`, 'Spring', ['Spring Boot'],
          '@EnableAutoConfiguration + spring.factories / AutoConfiguration.imports 条件装配。',
          '核心是条件注解决定是否装配，结合 starter 例子说明。', categoryId),
        this.mockQ('api-java-4', `${company}常考：MySQL 索引失效`, 'MySQL', ['MySQL', '高频'],
          '违反最左前缀、对索引列运算、隐式转换、like 左模糊、优化器放弃索引等。',
          '先讲 B+Tree，再举失效 case，并用 Explain 验证。', categoryId)
      ];
    }

    return [
      this.mockQ('api-java-1', 'HashMap 在 JDK 1.8 中的底层结构？', 'Java', ['集合', '高频'],
        'JDK1.8 后：数组 + 链表 + 红黑树；树化阈值 8，退化 6；扩容 2 倍。',
        'HashMap 在 1.8 后是数组加链表或红黑树，顺着 put、hash、扩容讲。', categoryId),
      this.mockQ('api-java-2', 'JVM 内存结构有哪些？', 'JVM', ['JVM'],
        '堆、栈、方法区/元空间、程序计数器、本地方法栈。',
        '先讲运行时数据区，再讲 GC 发生在哪些区域。', categoryId),
      this.mockQ('api-java-3', 'Spring Boot 自动装配原理？', 'Spring', ['Spring Boot'],
        '@EnableAutoConfiguration + 条件注解 + starter 自动配置。',
        '核心是条件注解决定是否装配。', categoryId)
    ];
  }

  private mockQ(id: string, title: string, categoryName: string, tags: string[],
    answer: string, interview: string, categoryId: string): QuestionItem {
    return {
      id,
      title,
      categoryId,
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
