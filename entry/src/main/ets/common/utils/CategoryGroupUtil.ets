import { Category } from '../models/Types';
import { CategoryGroupSection } from '../models/Types';

export class CategoryGroupUtil {
  static readonly SKILL: string = '技能';
  static readonly COMPANY: string = '公司';
  static readonly SPECIAL: string = '专项';

  static normalize(group: string): string {
    if (group === '技术方向') {
      return CategoryGroupUtil.SKILL;
    }
    if (group === '大厂真题') {
      return CategoryGroupUtil.COMPANY;
    }
    if (group === '高频精选') {
      return CategoryGroupUtil.SPECIAL;
    }
    return group.length > 0 ? group : CategoryGroupUtil.SKILL;
  }

  static ofGroup(all: Category[], group: string): Category[] {
    const result: Category[] = [];
    all.forEach((c: Category) => {
      if (CategoryGroupUtil.normalize(c.group) === group) {
        result.push(c);
      }
    });
    return result;
  }

  static browseItems(all: Category[], group: string): Category[] {
    return CategoryGroupUtil.ofGroup(all, group);
  }

  static fromFlat(all: Category[]): CategoryGroupSection[] {
    const seeds: CategoryGroupSection[] = [
      { name: '技能', title: '热门技能', bgColor: '#FFEDD5', textColor: '#9A3412', orderNum: 10, items: [] },
      { name: '公司', title: '公司题库', bgColor: '#DBEAFE', textColor: '#1E40AF', orderNum: 20, items: [] },
      { name: '专项', title: '专项', bgColor: '#DCFCE7', textColor: '#166534', orderNum: 30, items: [] }
    ];
    const used: string[] = [];
    const out: CategoryGroupSection[] = [];
    seeds.forEach((row: CategoryGroupSection) => {
      const items = CategoryGroupUtil.browseItems(all, row.name);
      used.push(row.name);
      if (items.length > 0) {
        out.push({
          name: row.name,
          title: row.title,
          bgColor: row.bgColor,
          textColor: row.textColor,
          orderNum: row.orderNum,
          items
        });
      }
    });
    all.forEach((c: Category) => {
      const g = CategoryGroupUtil.normalize(c.group);
      if (g.length > 0 && used.indexOf(g) < 0) {
        used.push(g);
        out.push({
          name: g,
          title: g,
          bgColor: '#F3F4F6',
          textColor: '#374151',
          orderNum: 90,
          items: CategoryGroupUtil.browseItems(all, g)
        });
      }
    });
    return out;
  }
}
