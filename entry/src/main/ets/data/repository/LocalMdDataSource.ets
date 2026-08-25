import { common } from '@kit.AbilityKit';
import { AppConfig } from '../../common/constants/AppConfig';
import { ArticleSummary, Category, DocCatalog, QuestionItem } from '../../common/models/Types';
import { RawFileUtil } from '../../common/utils/RawFileUtil';
import { MdParser } from '../parser/MdParser';

/** 本地 Markdown 数据源 */
export class LocalMdDataSource {
  private catalog: DocCatalog | null = null;

  async loadCatalog(context: common.UIAbilityContext): Promise<DocCatalog> {
    if (this.catalog) {
      return this.catalog;
    }
    const text = await RawFileUtil.readText(context, AppConfig.CATALOG_RAW_PATH);
    this.catalog = JSON.parse(text) as DocCatalog;
    return this.catalog;
  }

  async getAllCategories(context: common.UIAbilityContext): Promise<Category[]> {
    const catalog = await this.loadCatalog(context);
    return catalog.categories;
  }

  async getArticlesByCategory(context: common.UIAbilityContext, categoryId: string,
    subCategoryId?: string): Promise<ArticleSummary[]> {
    const catalog = await this.loadCatalog(context);
    return catalog.articles.filter((a: ArticleSummary) => {
      if (subCategoryId) {
        return a.subCategoryId === subCategoryId;
      }
      return a.categoryId === categoryId || a.subCategoryId === categoryId;
    });
  }

  async searchArticles(context: common.UIAbilityContext, keyword: string): Promise<ArticleSummary[]> {
    const catalog = await this.loadCatalog(context);
    const key = keyword.trim().toLowerCase();
    if (key.length === 0) {
      return [];
    }
    return catalog.articles.filter((a: ArticleSummary) => {
      return a.title.toLowerCase().includes(key) ||
        a.description.toLowerCase().includes(key) ||
        a.tags.some((t: string) => t.toLowerCase().includes(key)) ||
        a.sampleQuestions.some((q: string) => q.toLowerCase().includes(key));
    });
  }

  async getHotArticles(context: common.UIAbilityContext, limit: number = 10): Promise<ArticleSummary[]> {
    const catalog = await this.loadCatalog(context);
    return catalog.articles.filter((a: ArticleSummary) => a.hot).slice(0, limit);
  }

  async readMarkdown(context: common.UIAbilityContext, relativePath: string): Promise<string> {
    const path = relativePath.startsWith('docs/') ? relativePath :
      `${AppConfig.DOCS_RAW_PREFIX}${relativePath}`;
    return await RawFileUtil.readText(context, path);
  }

  async loadArticleAsQuestion(context: common.UIAbilityContext,
    article: ArticleSummary): Promise<QuestionItem> {
    const raw = await this.readMarkdown(context, article.path);
    const parsed = MdParser.parse(raw);
    const item: QuestionItem = {
      id: article.id,
      title: article.title.length > 0 ? article.title : parsed.frontMatter.title,
      categoryId: article.categoryId,
      categoryName: article.subCategoryName,
      tags: article.tags.length > 0 ? article.tags : parsed.frontMatter.tags,
      difficulty: article.hot ? '高频' : '专题',
      hot: article.hot,
      source: 'local_md',
      mdPath: article.path,
      content: parsed.body,
      mastery: 0,
      favorited: false
    };
    return item;
  }

  async loadInlineQuestions(context: common.UIAbilityContext,
    article: ArticleSummary): Promise<QuestionItem[]> {
    const raw = await this.readMarkdown(context, article.path);
    const parsed = MdParser.parse(raw);
    const sections = MdParser.splitSections(parsed.body);
    const result: QuestionItem[] = [];
    for (let i = 0; i < sections.length; i++) {
      const sec = sections[i];
      if (sec.level !== 3 || sec.title.length < 4 || sec.content.length < 20) {
        continue;
      }
      const q: QuestionItem = {
        id: `${article.id}#${i}`,
        title: sec.title,
        categoryId: article.categoryId,
        categoryName: article.subCategoryName,
        tags: article.tags,
        difficulty: article.hot ? '高频' : '专题',
        hot: article.hot,
        source: 'local_md',
        mdPath: article.path,
        content: sec.content,
        mastery: 0,
        favorited: false
      };
      result.push(q);
    }
    return result;
  }
}
