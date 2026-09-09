import { AppConfig } from '../constants/AppConfig';

export class BookMedia {
  static resolve(path: string): string {
    if (path.length === 0) {
      return '';
    }
    if (path.indexOf('http://') === 0 || path.indexOf('https://') === 0) {
      return path;
    }
    let value = path;
    if (value.indexOf('/') === 0) {
      if (value.indexOf('/sys/') === 0 || value.indexOf('/user/') === 0 || value.indexOf('/jeecg-boot/') === 0) {
        return `${AppConfig.REMOTE_API_BASE}${value}`;
      }
      value = value.substring(1);
    }
    return `${AppConfig.REMOTE_API_BASE}/sys/common/static/${value}`;
  }
}
