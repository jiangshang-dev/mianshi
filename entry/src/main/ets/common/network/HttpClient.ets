import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from '../constants/AppConfig';

const DOMAIN = 0xC0DE;

export interface HttpResult {
  ok: boolean;
  code: number;
  body: string;
  message: string;
}

export class HttpClient {
  static async get(path: string, query?: string): Promise<HttpResult> {
    let url = path.startsWith('http') ? path : `${AppConfig.REMOTE_API_BASE}${path}`;
    if (query !== undefined && query.length > 0) {
      url = `${url}?${query}`;
    }
    const client = http.createHttp();
    try {
      const resp = await client.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: AppConfig.REQUEST_TIMEOUT_MS,
        readTimeout: AppConfig.REQUEST_TIMEOUT_MS,
        expectDataType: http.HttpDataType.STRING,
        header: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
      });
      const body = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result);
      return {
        ok: resp.responseCode >= 200 && resp.responseCode < 300,
        code: resp.responseCode,
        body,
        message: ''
      };
    } catch (err) {
      hilog.warn(DOMAIN, 'HttpClient', 'GET failed %{public}s %{public}s', url, JSON.stringify(err));
      return { ok: false, code: -1, body: '', message: JSON.stringify(err) };
    } finally {
      client.destroy();
    }
  }

  static async postJson(path: string, body: string): Promise<HttpResult> {
    const url = path.startsWith('http') ? path : `${AppConfig.REMOTE_API_BASE}${path}`;
    const client = http.createHttp();
    try {
      const resp = await client.request(url, {
        method: http.RequestMethod.POST,
        connectTimeout: AppConfig.REQUEST_TIMEOUT_MS,
        readTimeout: AppConfig.REQUEST_TIMEOUT_MS,
        expectDataType: http.HttpDataType.STRING,
        header: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        extraData: body
      });
      const respBody = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result);
      return {
        ok: resp.responseCode >= 200 && resp.responseCode < 300,
        code: resp.responseCode,
        body: respBody,
        message: ''
      };
    } catch (err) {
      hilog.warn(DOMAIN, 'HttpClient', 'POST failed %{public}s %{public}s', url, JSON.stringify(err));
      return { ok: false, code: -1, body: '', message: JSON.stringify(err) };
    } finally {
      client.destroy();
    }
  }
}
