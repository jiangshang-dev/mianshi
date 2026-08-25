/** 模拟面试岗位 / 经验目录。默认内置一份，后台配置拉取后会覆盖。 */
export interface RoleModuleHint {
  label: string;
  keywords: string[];
  always: boolean;
}

export interface InterviewRoleDef {
  role: string;
  title: string;
  aliases: string[];
  modules: RoleModuleHint[];
}

export interface InterviewLevelDef {
  name: string;
  aliases: string[];
  isDefault: boolean;
}

export class InterviewRoleCatalog {
  static roles: InterviewRoleDef[] = InterviewRoleCatalog.builtinRoles();
  static levels: InterviewLevelDef[] = InterviewRoleCatalog.builtinLevels();
  static difficulties: string[] = ['简单', '中等', '困难', '大厂'];
  static defaultDifficulty: string = '中等';

  static names(): string[] {
    const result: string[] = [];
    for (let i = 0; i < InterviewRoleCatalog.roles.length; i++) {
      result.push(InterviewRoleCatalog.roles[i].role);
    }
    return result;
  }

  static levelNames(): string[] {
    const result: string[] = [];
    for (let i = 0; i < InterviewRoleCatalog.levels.length; i++) {
      result.push(InterviewRoleCatalog.levels[i].name);
    }
    return result;
  }

  static find(role: string): InterviewRoleDef | null {
    for (let i = 0; i < InterviewRoleCatalog.roles.length; i++) {
      if (InterviewRoleCatalog.roles[i].role === role) {
        return InterviewRoleCatalog.roles[i];
      }
    }
    return null;
  }

  static interviewerTitle(role: string): string {
    const def = InterviewRoleCatalog.find(role);
    if (def !== null && def.title.length > 0) {
      return def.title;
    }
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
    const last = InterviewRoleCatalog.roles.length - 1;
    if (last < 0) {
      return 'Java 后端';
    }
    for (let i = 0; i < last; i++) {
      if (InterviewRoleCatalog.hitAliases(InterviewRoleCatalog.roles[i].aliases, text, lower)) {
        return InterviewRoleCatalog.roles[i].role;
      }
    }
    return InterviewRoleCatalog.roles[last].role;
  }

  static matchLevel(text: string): string {
    const lower = text.toLowerCase();
    for (let i = 0; i < InterviewRoleCatalog.levels.length; i++) {
      if (InterviewRoleCatalog.hitAliases(InterviewRoleCatalog.levels[i].aliases, text, lower)) {
        return InterviewRoleCatalog.levels[i].name;
      }
    }
    return InterviewRoleCatalog.defaultLevel();
  }

  static defaultRole(): string {
    if (InterviewRoleCatalog.roles.length === 0) {
      return 'Java 后端';
    }
    return InterviewRoleCatalog.roles[InterviewRoleCatalog.roles.length - 1].role;
  }

  static defaultLevel(): string {
    for (let i = 0; i < InterviewRoleCatalog.levels.length; i++) {
      if (InterviewRoleCatalog.levels[i].isDefault) {
        return InterviewRoleCatalog.levels[i].name;
      }
    }
    if (InterviewRoleCatalog.levels.length > 0) {
      return InterviewRoleCatalog.levels[0].name;
    }
    return '1～3 年';
  }

  static replaceRoles(next: InterviewRoleDef[]): void {
    if (next.length > 0) {
      InterviewRoleCatalog.roles = next;
    }
  }

  static replaceLevels(next: InterviewLevelDef[]): void {
    if (next.length > 0) {
      InterviewRoleCatalog.levels = next;
    }
  }

  static replaceDifficulties(next: string[], defaultName: string): void {
    if (next.length > 0) {
      InterviewRoleCatalog.difficulties = next;
    }
    if (defaultName.length > 0) {
      InterviewRoleCatalog.defaultDifficulty = defaultName;
    }
  }

  private static hitAliases(aliases: string[], text: string, lower: string): boolean {
    for (let i = 0; i < aliases.length; i++) {
      const alias = aliases[i];
      if (alias.length === 0) {
        continue;
      }
      if (lower.indexOf(alias.toLowerCase()) >= 0 || text.indexOf(alias) >= 0) {
        return true;
      }
    }
    return false;
  }

  private static builtinRoles(): InterviewRoleDef[] {
    return [
      {
        role: '测试开发',
        title: '资深测试开发面试官',
        aliases: ['测试开发', '自动化测试', 'selenium', 'junit'],
        modules: [
          { label: '接口与自动化测试', keywords: ['接口', '自动化'], always: false },
          { label: '质量保障体系', keywords: [], always: true }
        ]
      },
      {
        role: '前端',
        title: '资深前端面试官',
        aliases: ['前端', 'vue', 'react', 'typescript'],
        modules: [
          { label: 'JavaScript / TypeScript', keywords: ['javascript', 'typescript'], always: false },
          { label: 'Vue / React', keywords: ['vue', 'react'], always: false },
          { label: '工程化与性能', keywords: ['webpack', '性能'], always: false }
        ]
      },
      {
        role: 'AI 应用开发',
        title: '资深AI 应用开发面试官',
        aliases: ['rag', 'llm', '大模型', '智能体', 'langchain', 'AI 应用'],
        modules: [
          { label: 'RAG / 检索', keywords: ['rag', '向量'], always: false },
          { label: 'Prompt / Agent', keywords: ['agent', '提示词'], always: false }
        ]
      },
      {
        role: '高级 Java',
        title: '资深高级 Java面试官',
        aliases: ['架构师', '架构', '技术专家', '高级开发'],
        modules: [
          { label: '系统设计', keywords: ['架构', '高并发'], always: true },
          { label: 'Java 进阶', keywords: ['jvm', '并发'], always: false }
        ]
      },
      {
        role: 'Java 后端',
        title: '资深Java 后端面试官',
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
  }

  private static builtinLevels(): InterviewLevelDef[] {
    return [
      { name: '应届', aliases: ['应届', '实习', '校园'], isDefault: false },
      { name: '1～3 年', aliases: ['1～3', '1-3', '两年', '2年', '三年', '3年'], isDefault: true },
      { name: '3～5 年', aliases: ['3～5', '3-5', '四年', '4年'], isDefault: false },
      { name: '5 年以上', aliases: ['5 年', '五年', '6年', '十年', '8年'], isDefault: false }
    ];
  }
}
