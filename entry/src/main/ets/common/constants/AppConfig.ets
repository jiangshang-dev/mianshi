export class AppConfig {
  static readonly APP_NAME: string = '码上 Offer';
  // static readonly REMOTE_API_BASE: string = 'https://www.fondia.top/jeecgboot';
  // static readonly REMOTE_API_BASE: string = 'https://www.mianshi-offer.cn/jeecgboot';
  static readonly REMOTE_API_BASE: string = 'http://192.168.3.27:8080/jeecg-boot';
  // static readonly REMOTE_API_BASE: string = 'http://192.168.2.1:8080/jeecg-boot';
  // static readonly REMOTE_API_BASE: string = 'http://192.168.1.78:8080/jeecg-boot';
  static readonly REMOTE_RESUME_UPLOAD_PATH: string = '/api/resume/upload';
  /** 分类 / 题库 / 热门 / 搜索只走后端 API */
  static readonly REMOTE_USE_MOCK_FALLBACK: boolean = false;
  static readonly REQUEST_TIMEOUT_MS: number = 8000;
  static readonly LOGIN_TIMEOUT_MS: number = 30000;
  static readonly UPLOAD_TIMEOUT_MS: number = 30000;
  static readonly AI_STREAM_TIMEOUT_MS: number = 60000;
}
