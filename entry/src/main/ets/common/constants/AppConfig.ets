export class AppConfig {
  static readonly APP_NAME: string = '码上 Offer';
  static readonly CATALOG_RAW_PATH: string = 'DocCatalog.json';
  static readonly DOCS_RAW_PREFIX: string = 'docs/';
  static readonly REMOTE_API_BASE: string = 'https://www.fondia.top/jeecgboot';
  // static readonly REMOTE_API_BASE: string = 'http://192.168.1.170:8080/jeecg-boot';
  static readonly REMOTE_RESUME_UPLOAD_PATH: string = '/api/resume/upload';
  /** 分类 / 题库 / 热门 / 搜索走后端 API，不再回落本地 MD 或 Mock */
  static readonly PREFER_REMOTE_API: boolean = true;
  static readonly REMOTE_USE_MOCK_FALLBACK: boolean = false;
  static readonly REQUEST_TIMEOUT_MS: number = 8000;
  static readonly LOGIN_TIMEOUT_MS: number = 30000;
  static readonly UPLOAD_TIMEOUT_MS: number = 30000;
  static readonly AI_STREAM_TIMEOUT_MS: number = 60000;
}
