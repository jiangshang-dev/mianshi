import { common } from '@kit.AbilityKit';
import {
  Category,
  CategoryGroupSection,
  QuestionItem,
  QuestionPage,
  TodayStudyStats,
  AiStreamSnapshot
} from '../../common/models/Types';
import { RemoteApiDataSource } from './RemoteApiDataSource';
import { FavoriteRepository } from './FavoriteRepository';
import { SseAbort } from '../../common/network/HttpClient';

/** 统一题库仓库：分类和题目全部走远程 API，入库后由 App 拉取 */
export class QuestionRepository {
  private static instance: QuestionRepository | null = null;
  private remote: RemoteApiDataSource = new RemoteApiDataSource();
  private favRepo: FavoriteRepository = FavoriteRepository.getInstance();

  static getInstance(): QuestionRepository {
    if (!QuestionRepository.instance) {
      QuestionRepository.instance = new QuestionRepository();
    }
    return QuestionRepository.instance;
  }

  async init(_context: common.UIAbilityContext): Promise<void> {
  }

  async getCategories(_context: common.UIAbilityContext): Promise<Category[]> {
    return await this.remote.listCategories();
  }

  async getCategoryGroups(_context: common.UIAbilityContext): Promise<CategoryGroupSection[]> {
    return await this.remote.listCategoryGroups();
  }

  async listQuestions(_context: common.UIAbilityContext, categoryId: string,
    subCategoryId?: string): Promise<QuestionItem[]> {
    const id = (subCategoryId !== undefined && subCategoryId.length > 0) ?
      subCategoryId : categoryId;
    const list = await this.remote.listByCategory(id);
    return list.map((q: QuestionItem) => this.withLocalState(q));
  }

  async pageQuestions(categoryId: string, pageNo: number, pageSize: number = 30,
    difficulty: string = ''): Promise<QuestionPage> {
    const page = await this.remote.pageByCategory(categoryId, pageNo, pageSize, difficulty);
    const records = page.records.map((q: QuestionItem) => this.withLocalState(q));
    const out: QuestionPage = {
      records: records,
      total: page.total,
      pageNo: pageNo,
      pageSize: pageSize,
      finished: page.finished
    };
    return out;
  }

  async getDetail(_context: common.UIAbilityContext, id: string): Promise<QuestionItem | null> {
    const detail = await this.remote.getDetail(id);
    return detail ? this.withLocalState(detail) : null;
  }

  async search(_context: common.UIAbilityContext, keyword: string): Promise<QuestionItem[]> {
    const remoteItems = await this.remote.search(keyword);
    return remoteItems.map((q: QuestionItem) => this.withLocalState(q));
  }

  async getHot(_context: common.UIAbilityContext): Promise<QuestionItem[]> {
    const remote = await this.remote.getHotQuestions(8);
    return remote.map((q: QuestionItem) => this.withLocalState(q));
  }

  async askAiStream(question: QuestionItem, message: string, onUpdate: (snap: AiStreamSnapshot) => void,
    abort?: SseAbort, sessionId?: string): Promise<string> {
    return await this.remote.askAiStream(question.id, question.title, message, onUpdate, abort, sessionId);
  }

  async askAi(question: QuestionItem, message: string): Promise<string> {
    return await this.remote.askAi(question.id, question.title, message);
  }

  async syncFavorites(): Promise<void> {
    await this.favRepo.sync();
  }

  async toggleFavorite(id: string, title: string): Promise<boolean> {
    return await this.favRepo.toggle(id, title);
  }

  async getTodayStudyStats(): Promise<TodayStudyStats> {
    return await this.remote.getTodayStudy(this.currentUserId());
  }

  async recordQuestionView(questionId: string): Promise<void> {
    try {
      await this.remote.recordQuestionView(this.currentUserId(), questionId);
    } catch (_e) {
    }
  }

  private currentUserId(): string {
    const id = AppStorage.get('userId') as string;
    if (id !== undefined && id.length > 0) {
      return id;
    }
    return '';
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
      viewCount: q.viewCount,
      source: 'remote_api',
      content: q.content,
      interviewAnswer: q.interviewAnswer,
      knowledgePoints: q.knowledgePoints,
      bilibiliUrls: q.bilibiliUrls,
      mastery: q.mastery,
      favorited: this.favRepo.has(q.id)
    };
  }
}
