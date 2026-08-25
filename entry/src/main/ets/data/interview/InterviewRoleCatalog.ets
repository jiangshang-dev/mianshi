/** 模拟面试岗位目录：加新岗位只改这里，面试官名称自动生成。 */
export interface RoleModuleHint {
  label: string;
  keywords: string[];
  always: boolean;
}

export interface InterviewRoleDef {
  role: string;
  aliases: string[];
  modules: RoleModuleHint[];
}

export class InterviewRoleCatalog {
  static readonly ROLES: InterviewRoleDef[] = [
    {
      role: '测试开发',
      aliases: ['测试开发', '自动化测试', 'selenium', 'junit'],
      modules: [
        { label: '接口与自动化测试', keywords: ['接口', '自动化'], always: false },
        { label: '质量保障体系', keywords: [], always: true }
      ]
    },
    {
      role: '前端',
      aliases: ['前端', 'vue', 'react', 'typescript'],
      modules: [
        { label: 'JavaScript / TypeScript', keywords: ['javascript', 'typescript'], always: false },
        { label: 'Vue / React', keywords: ['vue', 'react'], always: false },
        { label: '工程化与性能', keywords: ['webpack', '性能'], always: false }
      ]
    },
    {
      role: 'AI 应用开发',
      aliases: ['rag', 'llm', '大模型', '智能体', 'langchain', 'AI 应用'],
      modules: [
        { label: 'RAG / 检索', keywords: ['rag', '向量'], always: false },
        { label: 'Prompt / Agent', keywords: ['agent', '提示词'], always: false }
      ]
    },
    {
      role: '高级 Java',
      aliases: ['架构师', '架构', '技术专家', '高级开发'],
      modules: [
        { label: '系统设计', keywords: ['架构', '高并发'], always: true },
        { label: 'Java 进阶', keywords: ['jvm', '并发'], always: false }
      ]
    },
    {
      role: 'Java 后端',
      aliases: ['java', 'spring', '后端', 'mybatis'],
      modules: [
        { label: 'Java 集合与并发', keywords: ['hashmap', '集合', '并发'], always: false },
        { label: 'JVM', keywords: ['jvm', '垃圾回收', 'gc'], always: false },
        { label: 'Spring', keywords: ['spring', '自动装配'], always: false },
        { label: 'MySQL', keywords: ['mysql', '索引'], always: false },
        { label: 'Redis', keywords: ['redis', '缓存'], always: false },
        { label: '消息队列', keywords: ['kafka', 'rocketmq', '消息队列'], always: false }
      ]
    }
  ];

  static names(): string[] {
    const result: string[] = [];
    for (let i = 0; i < InterviewRoleCatalog.ROLES.length; i++) {
      result.push(InterviewRoleCatalog.ROLES[i].role);
    }
    return result;
  }

  static find(role: string): InterviewRoleDef | null {
    for (let i = 0; i < InterviewRoleCatalog.ROLES.length; i++) {
      if (InterviewRoleCatalog.ROLES[i].role === role) {
        return InterviewRoleCatalog.ROLES[i];
      }
    }
    return null;
  }

  /** 任何岗位都生成「资深{岗位}面试官」，无需再写映射。 */
  static interviewerTitle(role: string): string {
    const trimmed = role.trim();
    if (trimmed.length === 0) {
      return '资深面试官';
    }
    if (trimmed.endsWith('面试官')) {
      return trimmed;
    }
    return `资深${trimmed}面试官`;
  }

  static matchRole(text: string): string {
    const lower = text.toLowerCase();
    const last = InterviewRoleCatalog.ROLES.length - 1;
    for (let i = 0; i < last; i++) {
      if (InterviewRoleCatalog.hit(InterviewRoleCatalog.ROLES[i], text, lower)) {
        return InterviewRoleCatalog.ROLES[i].role;
      }
    }
    return InterviewRoleCatalog.ROLES[last].role;
  }

  private static hit(def: InterviewRoleDef, text: string, lower: string): boolean {
    for (let i = 0; i < def.aliases.length; i++) {
      const alias = def.aliases[i];
      if (lower.indexOf(alias.toLowerCase()) >= 0 || text.indexOf(alias) >= 0) {
        return true;
      }
    }
    return false;
  }
}
