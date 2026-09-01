import { ChinaPcaRaw } from './ChinaPcaRaw';

export class ChinaRegion {
  static provinces(): string[] {
    const result: string[] = [];
    let prev: string = '';
    const n: number = ChinaPcaRaw.count();
    for (let i = 0; i < n; i++) {
      const name: string = ChinaPcaRaw.province(i);
      if (name.length > 0 && name !== prev) {
        result.push(name);
        prev = name;
      }
    }
    return result;
  }

  static cities(province: string): string[] {
    const result: string[] = [];
    if (province.length === 0) {
      return result;
    }
    const n: number = ChinaPcaRaw.count();
    for (let i = 0; i < n; i++) {
      if (ChinaPcaRaw.province(i) === province) {
        result.push(ChinaPcaRaw.city(i));
      }
    }
    return result;
  }

  static districts(province: string, city: string): string[] {
    if (province.length === 0 || city.length === 0) {
      return [];
    }
    const n: number = ChinaPcaRaw.count();
    for (let i = 0; i < n; i++) {
      if (ChinaPcaRaw.province(i) === province && ChinaPcaRaw.city(i) === city) {
        return ChinaPcaRaw.districts(i);
      }
    }
    return [];
  }
}
