export class AppConfig {
  static readonly APP_NAME: string = '码上 Offer';
  static readonly CATALOG_RAW_PATH: string = 'DocCatalog.json';
  static readonly DOCS_RAW_PREFIX: string = 'docs/';
  static readonly REMOTE_API_BASE: string = 'https://api.example.com/code-offer';
  static readonly REMOTE_RESUME_UPLOAD_PATH: string = '/api/resume/upload';
  static readonly REMOTE_USE_MOCK_FALLBACK: boolean = true;
  static readonly REQUEST_TIMEOUT_MS: number = 8000;
}
