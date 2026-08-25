import { Category, SubCategory } from '../models/Types';

export class CategoryGroupUtil {
  static readonly SKILL: string = '技能';
  static readonly COMPANY: string = '公司';
  static readonly SPECIAL: string = '专项';
  static readonly ORDER: string[] = ['技能', '公司', '专项'];

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

  static sortGroupNames(groups: string[]): string[] {
    const extra: string[] = [];
    groups.forEach((g: string) => {
      if (!CategoryGroupUtil.ORDER.includes(g) && extra.indexOf(g) < 0) {
        extra.push(g);
      }
    });
    const ordered: string[] = [];
    CategoryGroupUtil.ORDER.forEach((g: string) => {
      if (groups.includes(g)) {
        ordered.push(g);
      }
    });
    return ordered.concat(extra);
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

  /** 公司题库展开成可点的公司条目；其他类型保留一级分类 */
  static browseItems(all: Category[], group: string): Category[] {
    const result: Category[] = [];
    CategoryGroupUtil.ofGroup(all, group).forEach((c: Category) => {
      if (group === CategoryGroupUtil.COMPANY && c.children.length > 0) {
        c.children.forEach((sub: SubCategory) => {
          result.push({
            id: sub.id,
            name: sub.name,
            icon: c.icon,
            order: c.order,
            group: group,
            source: c.source,
            articleCount: sub.articleCount,
            children: []
          });
        });
      } else {
        result.push(c);
      }
    });
    return result;
  }
}
