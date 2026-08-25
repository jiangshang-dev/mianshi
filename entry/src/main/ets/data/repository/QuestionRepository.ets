import { common } from '@kit.AbilityKit';
import { AppConfig } from '../../common/constants/AppConfig';
import {
  ArticleSummary,
  Category,
  DocCatalog,
  QuestionItem,
  TodayStudyStats,
  AiStreamSnapshot
} from '../../common/models/Types';
import { LocalMdDataSource } from './LocalMdDataSource';
import { RemoteApiDataSource } from './RemoteApiDataSource';
import { SseAbort } from '../../common/network/HttpClient';

/** 统一题库仓库：按 source 路由本地 MD / 远程 API */
export class QuestionRepository {
  private static instance: QuestionRepository | null = null;
  private local: LocalMdDataSource = new LocalMdDataSource();
  private remote: RemoteApiDataSource = new RemoteApiDataSource();
  private favorites: Set<string> = new Set();

  static getInstance(): QuestionRepository {
    if (!QuestionRepository.instance) {
      QuestionRepository.instance = new QuestionRepository();
    }
    return QuestionRepository.instance;
  }

  async init(context: common.UIAbilityContext): Promise<DocCatalog> {
    if (AppConfig.PREFER_REMOTE_API) {
      return {
        version: 'remote',
        generatedAt: '',
        localSource: '',
        remoteApiBase: AppConfig.REMOTE_API_BASE,
        categories: [],
        articles: [],
        stats: { localArticleCount: 0, localCategoryCount: 0, remoteCategoryCount: 0 }
      };
    }
    return await this.local.loadCatalog(context);
  }

  async getCategories(context: common.UIAbilityContext): Promise<Category[]> {
    if (AppConfig.PREFER_REMOTE_API) {
      return await this.remote.listCategories();
    }
    return await this.local.getAllCategories(context);
  }

  shouldUseRemote(categoryId: string, subCategoryId?: string): boolean {
    if (AppConfig.PREFER_REMOTE_API) {
      return true;
    }
    if (subCategoryId !== undefined && this.isRemoteCategory(subCategoryId)) {
      return true;
    }
    return this.isRemoteCategory(categoryId);
  }

  isRemoteCategory(categoryId: string): boolean {
    if (AppConfig.PREFER_REMOTE_API) {
      return true;
    }
    if (categoryId.startsWith('api.')) {
      return true;
    }
    return this.isDigitId(categoryId);
  }

  private isDigitId(id: string): boolean {
    if (id.length === 0) {
      return false;
    }
    for (let i = 0; i < id.length; i++) {
      const code = id.charCodeAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }

  async listQuestions(context: common.UIAbilityContext, categoryId: string,
    subCategoryId?: string): Promise<QuestionItem[]> {
    const useRemote = this.shouldUseRemote(categoryId, subCategoryId);
    if (useRemote) {
      const id = (subCategoryId !== undefined && subCategoryId.length > 0) ?
        subCategoryId : categoryId;
      const list = await this.remote.listByCategory(id);
      return list.map((q: QuestionItem) => this.withLocalState(q));
    }
    const articles = await this.local.getArticlesByCategory(context, categoryId, subCategoryId);
    return articles.map((a: ArticleSummary) => this.articleToListItem(a));
  }

  async getDetail(context: common.UIAbilityContext, id: string): Promise<QuestionItem | null> {
    if (AppConfig.PREFER_REMOTE_API || id.startsWith('api-') || id.startsWith('api.')) {
      const detail = await this.remote.getDetail(id);
      return detail ? this.withLocalState(detail) : null;
    }
    const catalog = await this.local.loadCatalog(context);
    let article = catalog.articles.find((a: ArticleSummary) => a.id === id);
    if (!article) {
      const path = id.startsWith('md:') ? id.substring(3) : id;
      article = catalog.articles.find((a: ArticleSummary) => a.path === path);
    }
    if (!article) {
      return null;
    }
    const q = await this.local.loadArticleAsQuestion(context, article);
    return this.withLocalState(q);
  }

  async getInlineQuestions(context: common.UIAbilityContext, articleId: string): Promise<QuestionItem[]> {
    const catalog = await this.local.loadCatalog(context);
    const article = catalog.articles.find((a: ArticleSummary) => a.id === articleId);
    if (!article) {
      return [];
    }
    const list = await this.local.loadInlineQuestions(context, article);
    return list.map((q: QuestionItem) => this.withLocalState(q));
  }

  async search(context: common.UIAbilityContext, keyword: string): Promise<QuestionItem[]> {
    if (AppConfig.PREFER_REMOTE_API) {
      const remoteItems = await this.remote.search(keyword);
      return remoteItems.map((q: QuestionItem) => this.withLocalState(q));
    }
    const localArticles = await this.local.searchArticles(context, keyword);
    const localItems = localArticles.slice(0, 30).map((a: ArticleSummary) => this.articleToListItem(a));
    const remoteItems = await this.remote.search(keyword);
    const merged: QuestionItem[] = [];
    localItems.forEach((item: QuestionItem) => merged.push(item));
    remoteItems.forEach((q: QuestionItem) => merged.push(this.withLocalState(q)));
    return merged;
  }

  async getHot(context: common.UIAbilityContext): Promise<QuestionItem[]> {
    if (AppConfig.PREFER_REMOTE_API) {
      const remote = await this.remote.getHotQuestions(8);
      return remote.map((q: QuestionItem) => this.withLocalState(q));
    }
    const local = await this.local.getHotArticles(context, 8);
    const remote = await this.remote.listByCategory('api.hot.java100');
    const localItems = local.map((a: ArticleSummary) => this.articleToListItem(a));
    const remoteItems = remote.slice(0, 4).map((q: QuestionItem) => this.withLocalState(q));
    const merged: QuestionItem[] = [];
    localItems.forEach((item: QuestionItem) => merged.push(item));
    remoteItems.forEach((item: QuestionItem) => merged.push(item));
    return merged;
  }

  async askAiStream(question: QuestionItem, message: string, onUpdate: (snap: AiStreamSnapshot) => void,
    abort?: SseAbort): Promise<string> {
    return await this.remote.askAiStream(question.id, question.title, message, onUpdate, abort);
  }

  async askAi(question: QuestionItem, message: string): Promise<string> {
    return await this.remote.askAi(question.id, question.title, message);
  }

  toggleFavorite(id: string): boolean {
    if (this.favorites.has(id)) {
      this.favorites.delete(id);
      return false;
    }
    this.favorites.add(id);
    return true;
  }

  getTodayStudyStats(): TodayStudyStats {
    return { questionCount: 23, minutes: 42, mastered: 18, toReview: 5 };
  }

  private articleToListItem(a: ArticleSummary): QuestionItem {
    return this.withLocalState({
      id: a.id,
      title: a.title,
      categoryId: a.categoryId,
      categoryName: a.subCategoryName,
      tags: a.tags,
      difficulty: a.hot ? '高频' : '专题',
      hot: a.hot,
      source: 'local_md',
      mdPath: a.path,
      content: a.description,
      mastery: 0,
      favorited: false
    });
  }

  private withLocalState(q: QuestionItem): QuestionItem {
    return {
      id: q.id,
      title: q.title,
      categoryId: q.categoryId,
      categoryName: q.categoryName,
      tags: q.tags,
      difficulty: q.difficulty,
      hot: q.hot,
      source: q.source,
      mdPath: q.mdPath,
      content: q.content,
      interviewAnswer: q.interviewAnswer,
      knowledgePoints: q.knowledgePoints,
      mastery: q.mastery,
      favorited: this.favorites.has(q.id)
    };
  }
}
