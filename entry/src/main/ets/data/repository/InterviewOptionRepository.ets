import { HttpClient } from '../../common/network/HttpClient';
import { InterviewLevelDef, InterviewRoleCatalog, InterviewRoleDef, RoleModuleHint } from '../interview/InterviewRoleCatalog';

export interface InterviewOptionBundle {
  roles: string[];
  levels: string[];
  difficulties: string[];
  defaultRole: string;
  defaultLevel: string;
  defaultDifficulty: string;
}

interface RemoteOptionItem {
  name?: string;
  interviewerTitle?: string;
  aliases?: string;
  focusModules?: string;
  isDefault?: number;
}

interface RemoteOptionsVo {
  roles?: RemoteOptionItem[];
  levels?: RemoteOptionItem[];
  difficulties?: RemoteOptionItem[];
}

interface RemoteWrap {
  success?: boolean;
  result?: RemoteOptionsVo;
  data?: RemoteOptionsVo;
}

export class InterviewOptionRepository {
  private static instance: InterviewOptionRepository | null = null;
  private cached: InterviewOptionBundle | null = null;

  static getInstance(): InterviewOptionRepository {
    if (!InterviewOptionRepository.instance) {
      InterviewOptionRepository.instance = new InterviewOptionRepository();
    }
    return InterviewOptionRepository.instance;
  }

  fallback(): InterviewOptionBundle {
    return {
      roles: InterviewRoleCatalog.names(),
      levels: InterviewRoleCatalog.levelNames(),
      difficulties: InterviewRoleCatalog.difficulties,
      defaultRole: InterviewRoleCatalog.defaultRole(),
      defaultLevel: InterviewRoleCatalog.defaultLevel(),
      defaultDifficulty: InterviewRoleCatalog.defaultDifficulty
    };
  }

  async load(): Promise<InterviewOptionBundle> {
    const remote = await this.fetchRemote();
    if (remote && remote.roles.length > 0) {
      this.cached = remote;
      return remote;
    }
    if (this.cached && this.cached.roles.length > 0) {
      return this.cached;
    }
    return this.fallback();
  }

  private async fetchRemote(): Promise<InterviewOptionBundle | null> {
    const resp = await HttpClient.get('/api/interview/options', '');
    if (!resp.ok || resp.body.length === 0) {
      return null;
    }
    try {
      const parsed = JSON.parse(resp.body) as RemoteWrap;
      const vo = parsed.result ?? parsed.data;
      if (!vo) {
        return null;
      }
      const roleDefs = InterviewOptionRepository.toRoleDefs(vo.roles);
      const levelDefs = InterviewOptionRepository.toLevelDefs(vo.levels);
      const diffs = InterviewOptionRepository.toNames(vo.difficulties);
      if (roleDefs.length > 0) {
        InterviewRoleCatalog.replaceRoles(roleDefs);
      }
      if (levelDefs.length > 0) {
        InterviewRoleCatalog.replaceLevels(levelDefs);
      }
      const defaultDiff = InterviewOptionRepository.pickDefaultName(vo.difficulties, InterviewRoleCatalog.defaultDifficulty);
      InterviewRoleCatalog.replaceDifficulties(diffs, defaultDiff);
      return {
        roles: InterviewRoleCatalog.names(),
        levels: InterviewRoleCatalog.levelNames(),
        difficulties: InterviewRoleCatalog.difficulties,
        defaultRole: InterviewOptionRepository.pickDefaultName(vo.roles, InterviewRoleCatalog.defaultRole()),
        defaultLevel: InterviewOptionRepository.pickDefaultName(vo.levels, InterviewRoleCatalog.defaultLevel()),
        defaultDifficulty: InterviewRoleCatalog.defaultDifficulty
      };
    } catch (_e) {
      return null;
    }
  }

  private static toRoleDefs(items?: RemoteOptionItem[]): InterviewRoleDef[] {
    const result: InterviewRoleDef[] = [];
    if (!items) {
      return result;
    }
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (!item || !item.name) {
        continue;
      }
      result.push({
        role: item.name,
        title: item.interviewerTitle ?? '',
        aliases: InterviewOptionRepository.splitCsv(item.aliases, item.name),
        modules: InterviewOptionRepository.toModules(item.focusModules)
      });
    }
    return result;
  }

  private static toLevelDefs(items?: RemoteOptionItem[]): InterviewLevelDef[] {
    const result: InterviewLevelDef[] = [];
    if (!items) {
      return result;
    }
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (!item || !item.name) {
        continue;
      }
      result.push({
        name: item.name,
        aliases: InterviewOptionRepository.splitCsv(item.aliases, item.name),
        isDefault: item.isDefault === 1
      });
    }
    return result;
  }

  private static toNames(items?: RemoteOptionItem[]): string[] {
    const result: string[] = [];
    if (!items) {
      return result;
    }
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (item && item.name) {
        result.push(item.name);
      }
    }
    return result;
  }

  private static pickDefaultName(items: RemoteOptionItem[] | undefined, fallback: string): string {
    if (!items) {
      return fallback;
    }
    for (let i = 0; i < items.length; i++) {
      if (items[i].isDefault === 1 && items[i].name) {
        return items[i].name as string;
      }
    }
    if (items.length > 0 && items[0].name) {
      return items[0].name;
    }
    return fallback;
  }

  private static splitCsv(raw: string | undefined, selfName: string): string[] {
    const result: string[] = [selfName];
    if (!raw) {
      return result;
    }
    const parts = raw.replace(/，/g, ',').split(',');
    for (let i = 0; i < parts.length; i++) {
      const word = parts[i].trim();
      if (word.length > 0 && result.indexOf(word) < 0) {
        result.push(word);
      }
    }
    return result;
  }

  private static toModules(raw: string | undefined): RoleModuleHint[] {
    const result: RoleModuleHint[] = [];
    if (!raw) {
      return result;
    }
    const parts = raw.replace(/，/g, ',').replace(/、/g, ',').split(',');
    for (let i = 0; i < parts.length; i++) {
      const label = parts[i].trim();
      if (label.length > 0) {
        result.push({ label: label, keywords: [label], always: true });
      }
    }
    return result;
  }
}
