import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from '../constants/AppConfig';
import { AiStreamSnapshot } from '../models/Types';
import { DeviceProfile } from '../utils/DeviceProfile';
import { SseParser } from './SseParser';

const DOMAIN = 0xC0DE;

export interface HttpResult {
  ok: boolean;
  code: number;
  body: string;
  message: string;
}

export class SseAbort {
  stopped: boolean = false;
  private client: http.HttpRequest | null = null;

  bind(client: http.HttpRequest): void {
    this.client = client;
    if (this.stopped) {
      this.kill();
    }
  }

  abort(): void {
    this.stopped = true;
    this.kill();
  }

  private kill(): void {
    const current = this.client;
    this.client = null;
    if (current) {
      try {
        current.destroy();
      } catch (_e) {
      }
    }
  }
}

interface HttpJsonHeader {
  'Content-Type': string;
  'Accept': string;
  'Cache-Control': string;
  'Pragma': string;
  'Authorization': string;
  'X-Login-Device': string;
}

interface HttpSseHeader {
  'Content-Type': string;
  'Accept': string;
  'Cache-Control': string;
  'Authorization': string;
  'X-Login-Device': string;
}

interface HttpMultipartHeader {
  'Content-Type': string;
  'Accept': string;
  'Authorization': string;
  'X-Login-Device': string;
}

export interface MultipartPart {
  name: string;
  data?: string;
  filePath?: string;
  fileName?: string;
  mimeType?: string;
}

export class HttpClient {
  private static authValue(): string {
    const token = AppStorage.get('userToken') as string;
    if (token !== undefined && token.length > 0) {
      return `Bearer ${token}`;
    }
    return '';
  }

  private static jsonHeaders(): HttpJsonHeader {
    const header: HttpJsonHeader = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'Authorization': HttpClient.authValue(),
      'X-Login-Device': DeviceProfile.loginDevice()
    };
    return header;
  }

  private static sseHeaders(): HttpSseHeader {
    const header: HttpSseHeader = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Authorization': HttpClient.authValue(),
      'X-Login-Device': DeviceProfile.loginDevice()
    };
    return header;
  }

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
        usingCache: false,
        header: HttpClient.jsonHeaders()
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

  static async postMultipart(path: string, parts: MultipartPart[], timeoutMs?: number): Promise<HttpResult> {
    const url = path.startsWith('http') ? path : `${AppConfig.REMOTE_API_BASE}${path}`;
    const timeout = timeoutMs !== undefined ? timeoutMs : AppConfig.UPLOAD_TIMEOUT_MS;
    const header: HttpMultipartHeader = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'application/json',
      'Authorization': HttpClient.authValue(),
      'X-Login-Device': DeviceProfile.loginDevice()
    };
    const formList: Array<http.MultiFormData> = [];
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      if (part.filePath !== undefined && part.filePath.length > 0) {
        const item: http.MultiFormData = {
          name: part.name,
          contentType: part.mimeType !== undefined && part.mimeType.length > 0 ?
            part.mimeType : 'application/octet-stream',
          remoteFileName: part.fileName !== undefined && part.fileName.length > 0 ? part.fileName : 'file',
          filePath: part.filePath
        };
        formList.push(item);
      } else {
        const item: http.MultiFormData = {
          name: part.name,
          contentType: 'text/plain',
          data: part.data !== undefined ? part.data : ''
        };
        formList.push(item);
      }
    }
    const client = http.createHttp();
    try {
      const resp = await client.request(url, {
        method: http.RequestMethod.POST,
        connectTimeout: timeout,
        readTimeout: timeout,
        expectDataType: http.HttpDataType.STRING,
        header: header,
        multiFormDataList: formList
      });
      const respBody = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result);
      return {
        ok: resp.responseCode >= 200 && resp.responseCode < 300,
        code: resp.responseCode,
        body: respBody,
        message: ''
      };
    } catch (err) {
      hilog.warn(DOMAIN, 'HttpClient', 'UPLOAD failed %{public}s %{public}s', url, JSON.stringify(err));
      return { ok: false, code: -1, body: '', message: JSON.stringify(err) };
    } finally {
      client.destroy();
    }
  }

  static async postJson(path: string, body: string, timeoutMs?: number): Promise<HttpResult> {
    const url = path.startsWith('http') ? path : `${AppConfig.REMOTE_API_BASE}${path}`;
    const timeout = timeoutMs !== undefined ? timeoutMs : AppConfig.REQUEST_TIMEOUT_MS;
    const client = http.createHttp();
    try {
      const resp = await client.request(url, {
        method: http.RequestMethod.POST,
        connectTimeout: timeout,
        readTimeout: timeout,
        expectDataType: http.HttpDataType.STRING,
        header: HttpClient.jsonHeaders(),
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

  static async postSse(path: string, body: string, onUpdate: (snap: AiStreamSnapshot) => void,
    abort?: SseAbort): Promise<HttpResult> {
    const url = path.startsWith('http') ? path : `${AppConfig.REMOTE_API_BASE}${path}`;
    const client = http.createHttp();
    const decoder = util.TextDecoder.create('utf-8');
    const parser = new SseParser();
    const gate = abort ?? new SseAbort();
    gate.bind(client);
    try {
      const markdown = await new Promise<string>((resolve) => {
        let settled = false;
        const finish = (ok: boolean, err?: string) => {
          if (settled) {
            return;
          }
          settled = true;
          const text = parser.finish(onUpdate);
          if (ok || gate.stopped) {
            resolve(text);
          } else {
            resolve(text.length > 0 ? text : (err ?? 'stream failed'));
          }
        };
        client.on('headersReceive', (_header: Object) => {
          hilog.info(DOMAIN, 'HttpClient', 'SSE headers %{public}s', JSON.stringify(_header));
        });
        client.on('dataReceive', (data: ArrayBuffer) => {
          if (gate.stopped) {
            return;
          }
          try {
            const bytes = new Uint8Array(data);
            const piece = decoder.decodeWithStream(bytes, { stream: true });
            if (piece && piece.length > 0) {
              parser.feed(piece, onUpdate);
            }
          } catch (err) {
            hilog.warn(DOMAIN, 'HttpClient', 'SSE decode %{public}s', JSON.stringify(err));
          }
        });
        client.on('dataEnd', () => {
          try {
            const tail = decoder.decodeWithStream(new Uint8Array(), { stream: false });
            if (tail && tail.length > 0) {
              parser.feed(tail, onUpdate);
            }
          } catch (_e) {
          }
          finish(true);
        });
        client.requestInStream(url, {
          method: http.RequestMethod.POST,
          connectTimeout: AppConfig.REQUEST_TIMEOUT_MS,
          readTimeout: AppConfig.AI_STREAM_TIMEOUT_MS,
          header: HttpClient.sseHeaders(),
          extraData: body
        }).then((code: number) => {
          if (code < 200 || code >= 300) {
            finish(false, `HTTP ${code}`);
          }
        }).catch((err: Error) => {
          finish(gate.stopped, JSON.stringify(err));
        });
      });
      return { ok: !gate.stopped, code: 200, body: markdown, message: gate.stopped ? 'stopped' : '' };
    } catch (err) {
      hilog.warn(DOMAIN, 'HttpClient', 'SSE failed %{public}s %{public}s', url, JSON.stringify(err));
      return { ok: false, code: -1, body: parser.current(), message: JSON.stringify(err) };
    } finally {
      try {
        client.off('headersReceive');
        client.off('dataReceive');
        client.off('dataEnd');
      } catch (_e) {
      }
      if (!gate.stopped) {
        try {
          client.destroy();
        } catch (_e) {
        }
      }
    }
  }
}
