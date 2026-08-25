export type DataSourceType = 'local_md' | 'remote_api';

export interface SubCategory {
  id: string;
  name: string;
  parentId: string;
  path: string;
  source: DataSourceType;
  articleCount: number;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  order: number;
  group: string;
  source: DataSourceType;
  articleCount: number;
  children: SubCategory[];
}

export interface ArticleSummary {
  id: string;
  title: string;
  description: string;
  categoryId: string;
  subCategoryId: string;
  subCategoryName: string;
  tags: string[];
  path: string;
  source: DataSourceType;
  questionCount: number;
  sampleQuestions: string[];
  hot: boolean;
}

export interface QuestionItem {
  id: string;
  title: string;
  categoryId: string;
  categoryName: string;
  tags: string[];
  difficulty: string;
  hot: boolean;
  source: DataSourceType;
  mdPath?: string;
  content?: string;
  interviewAnswer?: string;
  knowledgePoints?: string[];
  mastery: number;
  favorited: boolean;
}

export interface DocCatalog {
  version: string;
  generatedAt: string;
  localSource: string;
  remoteApiBase: string;
  categories: Category[];
  articles: ArticleSummary[];
  stats: CatalogStats;
}

export interface CatalogStats {
  localArticleCount: number;
  localCategoryCount: number;
  remoteCategoryCount: number;
}

export interface AiChatMessage {
  role: 'user' | 'assistant';
  content: string;
  thinking: string;
  thinkingDone: boolean;
  thinkingOpen: boolean;
  phase: string;
}

export interface AiStreamSnapshot {
  thinking: string;
  markdown: string;
  phase: string;
  thinkingDone: boolean;
  sessionId: string;
}

export interface TodayStudyStats {
  questionCount: number;
  minutes: number;
  mastered: number;
  toReview: number;
}
