import { ResumeProfile } from '../../common/models/ResumeTypes';
import { InterviewRoleCatalog, InterviewRoleDef, RoleModuleHint } from './InterviewRoleCatalog';

/** 根据简历推断的本场面试设定 */
export interface ResumeInsight {
  role: string;
  level: string;
  interviewer: string;
  modules: string[];
  hasResumeText: boolean;
  hasResumeFile: boolean;
}

/** 从简历文件名/正文推断岗位、年限、考察模块与对应面试官 */
export class ResumeInsightBuilder {
  static from(profile: ResumeProfile | null): ResumeInsight {
    const fileName = profile !== null ? profile.fileName : '';
    const preview = ResumeInsightBuilder.bodyOf(profile);
    const blob = `${fileName}\n${preview}`;
    const hasFile = profile !== null && fileName.length > 0;
    const hasText = ResumeInsightBuilder.isParsedText(preview);
    const role = ResumeInsightBuilder.inferRole(blob);
    const level = ResumeInsightBuilder.inferLevel(blob);
    return {
      role: role,
      level: level,
      interviewer: InterviewRoleCatalog.interviewerTitle(role),
      modules: ResumeInsightBuilder.inferModules(blob, role),
      hasResumeText: hasText,
      hasResumeFile: hasFile
    };
  }

  static isParsedText(preview: string): boolean {
    if (preview.length < 20) {
      return false;
    }
    if (preview.indexOf('服务端将解析') >= 0) {
      return false;
    }
    if (preview.indexOf('已上传简历') === 0 && preview.length < 120) {
      return false;
    }
    return true;
  }

  static interviewerOf(role: string): string {
    return InterviewRoleCatalog.interviewerTitle(role);
  }

  private static inferRole(text: string): string {
    return InterviewRoleCatalog.matchRole(text);
  }

  private static inferLevel(text: string): string {
    if (text.indexOf('应届') >= 0 || text.indexOf('实习') >= 0 || text.indexOf('校园') >= 0) {
      return '应届';
    }
    if (text.indexOf('5 年') >= 0 || text.indexOf('五年') >= 0 || text.indexOf('6年') >= 0 ||
      text.indexOf('十年') >= 0 || text.indexOf('8年') >= 0) {
      return '5 年以上';
    }
    if (text.indexOf('3～5') >= 0 || text.indexOf('3-5') >= 0 || text.indexOf('四年') >= 0 ||
      text.indexOf('4年') >= 0) {
      return '3～5 年';
    }
    if (text.indexOf('1～3') >= 0 || text.indexOf('1-3') >= 0 || text.indexOf('两年') >= 0 ||
      text.indexOf('2年') >= 0 || text.indexOf('三年') >= 0 || text.indexOf('3年') >= 0) {
      return '1～3 年';
    }
    return '1～3 年';
  }

  static bodyOf(profile: ResumeProfile | null): string {
    if (profile === null) {
      return '';
    }
    if (profile.textContent && profile.textContent.length > 0) {
      return profile.textContent;
    }
    return profile.textPreview;
  }

  static modulesOf(profile: ResumeProfile | null, role: string): string[] {
    const fileName = profile !== null ? profile.fileName : '';
    const preview = ResumeInsightBuilder.bodyOf(profile);
    return ResumeInsightBuilder.inferModules(`${fileName}\n${preview}`, role);
  }

  private static inferModules(text: string, role: string): string[] {
    const lower = text.toLowerCase();
    const hit: string[] = [];
    const add = (label: string, ok: boolean): void => {
      if (ok && hit.indexOf(label) < 0) {
        hit.push(label);
      }
    };
    const def: InterviewRoleDef | null = InterviewRoleCatalog.find(role);
    const hints: RoleModuleHint[] = def !== null ? def.modules : [];
    for (let i = 0; i < hints.length; i++) {
      const hint = hints[i];
      let matched = hint.always;
      for (let k = 0; k < hint.keywords.length; k++) {
        const word = hint.keywords[k];
        if (lower.indexOf(word.toLowerCase()) >= 0 || text.indexOf(word) >= 0) {
          matched = true;
          break;
        }
      }
      add(hint.label, matched);
    }
    add('简历项目深挖', true);
    if (hit.length <= 1) {
      add('岗位核心技能', true);
      add('系统设计', true);
    }
    return hit.slice(0, 6);
  }
}
