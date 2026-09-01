import { util } from '@kit.ArkTS';

export class JwsUtil {
  static decodePayload(data: string): string {
    const parts: string[] = data.split('.');
    if (parts.length < 2) {
      return '';
    }
    try {
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const helper = new util.Base64Helper();
      let payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const pad = payload.length % 4;
      if (pad === 1) {
        return '';
      }
      if (pad > 0) {
        payload += '===='.substring(pad);
      }
      return decoder.decodeToString(helper.decodeSync(payload));
    } catch (_e) {
      return '';
    }
  }
}
