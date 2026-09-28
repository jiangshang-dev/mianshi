import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from '../../common/constants/AppConfig';
import { ResumeProfile } from '../../common/models/ResumeTypes';
import { HttpClient } from '../../common/network/HttpClient';

const DOMAIN = 0xC0DE;
const PREF_NAME = 'resume_profile';
const PREF_KEY = 'resume_meta';
const RESUME_DIR = 'resume';
const PREVIEW_MAX_LEN = 2000;

interface CopyResult {
  ok: boolean;
  size: number;
  buffer: ArrayBuffer;
  error: string;
}

interface ResumeSaveBody {
  userId: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
  textPreview: string;
  textContent: string;
}

interface ResumeApiVo {
  id?: string;
  fileName?: string;
  fileUrl?: string;
  fileSize?: number;
  mimeType?: string;
  textPreview?: string;
  textContent?: string;
  parseStatus?: string;
}

interface ResumeApiWrap {
  success?: boolean;
  message?: string;
  result?: ResumeApiVo;
  data?: ResumeApiVo;
}

export class ResumeRepository {
  private static instance: ResumeRepository | null = null;
  private cached: ResumeProfile | null = null;
  private picking: boolean = false;
  private lastPickError: string = '';

  static getInstance(): ResumeRepository {
    if (!ResumeRepository.instance) {
      ResumeRepository.instance = new ResumeRepository();
    }
    return ResumeRepository.instance;
  }

  hasResume(): boolean {
    return this.cached !== null;
  }

  getCached(): ResumeProfile | null {
    return this.cached;
  }

  async load(context: common.UIAbilityContext): Promise<ResumeProfile | null> {
    if (this.picking && this.cached) {
      return this.cached;
    }
    if (this.currentUserId().length === 0) {
      this.cached = null;
      this.publish(null);
      return null;
    }
    const local = await this.loadLocal(context);
    const remote = await this.fetchRemote();
    if (this.cached && this.cached.filePath.length > 0 && this.cached.syncStatus === 'local') {
      return this.cached;
    }
    if (remote && ResumeRepository.remoteWins(remote, local)) {
      this.cached = remote;
      await this.persist(context, remote);
      this.publish(remote);
      return remote;
    }
    if (local) {
      this.cached = local;
      this.publish(local);
      if (local.syncStatus !== 'uploaded' || local.fileUrl.length === 0) {
        await this.pushRemote(context, local);
      }
      return this.cached;
    }
    this.cached = null;
    this.publish(null);
    return null;
  }

  private async loadLocal(context: common.UIAbilityContext): Promise<ResumeProfile | null> {
    if (this.cached) {
      return this.cached;
    }
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      const raw = await pref.get(PREF_KEY, '') as string;
      if (raw.length === 0) {
        return null;
      }
      const profile = JSON.parse(raw) as ResumeProfile;
      if (!profile.textContent) {
        profile.textContent = profile.textPreview ?? '';
      }
      if (!profile.fileUrl) {
        profile.fileUrl = '';
      }
      if (!profile.parseStatus) {
        profile.parseStatus = ResumeRepository.isParsed(profile.textContent) ? 'done' : 'pending';
      }
      try {
        if (profile.filePath && profile.filePath.length > 0) {
          fileIo.accessSync(profile.filePath);
        }
        this.cached = profile;
        return profile;
      } catch (err) {
        return profile;
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'load failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  consumePickError(): string {
    const msg = this.lastPickError;
    this.lastPickError = '';
    return msg;
  }

  async pickAndSave(context: common.UIAbilityContext): Promise<ResumeProfile | null> {
    this.picking = true;
    this.lastPickError = '';
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      // API 10+ 必须用「描述|后缀,后缀」，写成 ['.pdf'] 会选完无法确认
      options.fileSuffixFilters = ['简历文档|.pdf,.doc,.docx,.txt,.md'];
      const uris = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        return null;
      }
      return await this.saveFromUri(context, uris[0]);
    } catch (err) {
      this.lastPickError = ResumeRepository.describeError('保存失败', err);
      hilog.warn(DOMAIN, 'ResumeRepository', 'pickAndSave failed %{public}s', JSON.stringify(err));
      return null;
    } finally {
      this.picking = false;
    }
  }

  async saveFromUri(context: common.UIAbilityContext, uri: string): Promise<ResumeProfile | null> {
    const displayName = this.extractFileName(uri);
    const dir = `${context.filesDir}/${RESUME_DIR}`;
    try {
      fileIo.mkdirSync(dir, true);
    } catch (_e) {
    }
    const destPath = `${dir}/resume_${Date.now()}${this.fileExt(displayName)}`;
    const copied = this.copyPickerFile(uri, destPath);
    if (!copied.ok) {
      this.lastPickError = copied.error;
      return null;
    }

    const textFull = await this.extractTextFull(displayName, copied.buffer);
    const profile: ResumeProfile = {
      fileName: displayName,
      filePath: destPath,
      fileUrl: '',
      fileSize: copied.size,
      mimeType: this.guessMime(displayName),
      uploadedAt: new Date().toISOString(),
      textPreview: this.trimPreview(textFull),
      textContent: textFull,
      resumeId: '',
      parseStatus: ResumeRepository.isParsed(textFull) ? 'done' : 'pending',
      syncStatus: 'local'
    };
    await this.persist(context, profile);
    this.cached = profile;
    this.publish(profile);
    const hint = await this.pushRemote(context, profile);
    if (hint.length > 0) {
      this.lastPickError = hint;
    }
    return profile;
  }

  private copyPickerFile(uri: string, destPath: string): CopyResult {
    try {
      const srcFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      try {
        const stat = fileIo.statSync(srcFile.fd);
        if (stat.size <= 0) {
          return { ok: false, size: 0, buffer: new ArrayBuffer(0), error: '文件是空的' };
        }
        if (stat.size > 15 * 1024 * 1024) {
          return { ok: false, size: 0, buffer: new ArrayBuffer(0), error: '文件过大，请小于 15MB' };
        }
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(srcFile.fd, buffer);
        const destFile = fileIo.openSync(destPath,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(destFile.fd, buffer);
        } finally {
          fileIo.closeSync(destFile);
        }
        return { ok: true, size: stat.size, buffer: buffer, error: '' };
      } finally {
        fileIo.closeSync(srcFile);
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'copyPickerFile failed %{public}s uri=%{public}s',
        JSON.stringify(err), uri);
      return {
        ok: false,
        size: 0,
        buffer: new ArrayBuffer(0),
        error: ResumeRepository.describeError('无法读取所选文件', err)
      };
    }
  }

  private static describeError(prefix: string, err: Object): string {
    const raw = JSON.stringify(err);
    if (raw.indexOf('13900002') >= 0) {
      return `${prefix}：找不到文件`;
    }
    if (raw.indexOf('13900012') >= 0) {
      return `${prefix}：没有文件权限`;
    }
    if (raw.indexOf('13900020') >= 0) {
      return `${prefix}：文件参数无效`;
    }
    if (raw.length > 0 && raw !== '{}') {
      return `${prefix}：${raw.substring(0, 80)}`;
    }
    return `${prefix}，请换一份文件再试`;
  }

  private fileExt(fileName: string): string {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.docx')) {
      return '.docx';
    }
    if (lower.endsWith('.doc')) {
      return '.doc';
    }
    if (lower.endsWith('.pdf')) {
      return '.pdf';
    }
    if (lower.endsWith('.md')) {
      return '.md';
    }
    if (lower.endsWith('.txt')) {
      return '.txt';
    }
    return '.pdf';
  }

  async clear(context: common.UIAbilityContext): Promise<void> {
    await this.clearLocalSession(context);
    this.deleteRemote();
  }

  /** 退出登录只清本机，不删云端简历 */
  async clearLocalSession(context: common.UIAbilityContext): Promise<void> {
    if (this.cached && this.cached.filePath.length > 0) {
      try {
        fileIo.accessSync(this.cached.filePath);
        fileIo.unlinkSync(this.cached.filePath);
      } catch (err) {
        hilog.warn(DOMAIN, 'ResumeRepository', 'unlink failed %{public}s', JSON.stringify(err));
      }
    }
    await this.clearMeta(context);
    this.cached = null;
    this.publish(null);
  }

  formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    }
    if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  formatUploadTime(iso: string): string {
    if (iso.length < 10) {
      return iso;
    }
    return iso.substring(0, 10).replace(/-/g, '.');
  }

  private async persist(context: common.UIAbilityContext, profile: ResumeProfile): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.put(PREF_KEY, JSON.stringify(profile));
    await pref.flush();
  }

  private publish(profile: ResumeProfile | null): void {
    AppStorage.setOrCreate('globalResumeFileName', profile !== null ? profile.fileName : '');
  }

  private currentUserId(): string {
    const id = AppStorage.get('userId') as string;
    if (id !== undefined && id.length > 0) {
      return id;
    }
    return '';
  }

  private async fetchRemote(): Promise<ResumeProfile | null> {
    const userId = this.currentUserId();
    if (userId.length === 0) {
      return null;
    }
    const resp = await HttpClient.get('/api/resume/current', `userId=${encodeURIComponent(userId)}`);
    if (!resp.ok || resp.body.length === 0) {
      return null;
    }
    try {
      const parsed = JSON.parse(resp.body) as ResumeApiWrap;
      const vo = parsed.result ?? parsed.data;
      if (!vo || !vo.fileName) {
        return null;
      }
      const text = vo.textContent ?? '';
      const parsedText = ResumeRepository.isParsed(text);
      const preview = parsedText ? this.trimPreview(text) :
        (vo.textPreview !== undefined && vo.textPreview.length > 0 ? vo.textPreview : '');
      return {
        fileName: vo.fileName,
        filePath: '',
        fileUrl: vo.fileUrl ?? '',
        fileSize: vo.fileSize ?? 0,
        mimeType: vo.mimeType ?? '',
        uploadedAt: new Date().toISOString(),
        textPreview: preview,
        textContent: parsedText ? text : '',
        resumeId: vo.id ?? '',
        parseStatus: vo.parseStatus ?? (parsedText ? 'done' : 'pending'),
        syncStatus: 'uploaded'
      };
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'fetchRemote failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  private async pushRemote(context: common.UIAbilityContext, profile: ResumeProfile): Promise<string> {
    const userId = this.currentUserId();
    if (userId.length === 0) {
      return '请先登录后再上传简历';
    }
    if (profile.filePath.length === 0) {
      return '简历文件读取失败，请重新选择';
    }
    try {
      fileIo.accessSync(profile.filePath);
    } catch (_e) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'local file missing, skip upload');
      return '简历文件读取失败，请重新选择';
    }
    const resp = await HttpClient.postMultipart(AppConfig.REMOTE_RESUME_UPLOAD_PATH, [
      { name: 'userId', data: userId },
      {
        name: 'file',
        filePath: profile.filePath,
        fileName: profile.fileName,
        mimeType: profile.mimeType
      }
    ], AppConfig.UPLOAD_TIMEOUT_MS);
    if (!resp.ok) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'upload failed %{public}s %{public}s', `${resp.code}`, resp.body);
      return ResumeRepository.uploadFailMessage(resp.body);
    }
    try {
      const parsed = JSON.parse(resp.body) as ResumeApiWrap;
      if (parsed.success === false) {
        hilog.warn(DOMAIN, 'ResumeRepository', 'upload rejected %{public}s', parsed.message ?? '');
        return parsed.message !== undefined && parsed.message.length > 0 ? parsed.message : '简历上传失败，请稍后再试';
      }
      const vo = parsed.result ?? parsed.data;
      if (!vo) {
        return '简历上传失败，请稍后再试';
      }
      if (vo.id) {
        profile.resumeId = vo.id;
      }
      if (vo.fileUrl) {
        profile.fileUrl = vo.fileUrl;
      }
      const text = vo.textContent ?? '';
      if (ResumeRepository.isParsed(text)) {
        profile.textContent = text;
        profile.textPreview = this.trimPreview(text);
        profile.parseStatus = vo.parseStatus ?? 'done';
        profile.syncStatus = 'uploaded';
        await this.persist(context, profile);
        this.cached = profile;
        this.publish(profile);
        return '';
      }
      const hint = parsed.message !== undefined && parsed.message.length > 0 ?
        parsed.message : '没有解析出简历正文。请上传可选中文字的 PDF 或 Word，扫描件暂不支持。';
      profile.textContent = '';
      profile.textPreview = vo.textPreview !== undefined && vo.textPreview.length > 0 ? vo.textPreview : hint;
      profile.parseStatus = vo.parseStatus ?? 'failed';
      profile.syncStatus = 'uploaded';
      await this.persist(context, profile);
      this.cached = profile;
      this.publish(profile);
      return hint;
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'upload parse failed %{public}s', JSON.stringify(err));
      return '简历上传失败，请稍后再试';
    }
  }

  private static uploadFailMessage(body: string): string {
    try {
      const parsed = JSON.parse(body) as ResumeApiWrap;
      if (parsed.message !== undefined && parsed.message.length > 0 && parsed.message.length < 80) {
        return parsed.message;
      }
    } catch (_e) {
    }
    return '简历上传失败，请稍后再试';
  }

  private static isParsed(text: string): boolean {
    if (text.length < 20) {
      return false;
    }
    if (text.indexOf('服务端将解析') >= 0 || text.indexOf('没有解析出简历正文') >= 0) {
      return false;
    }
    if (text.indexOf('未能抽出正文') >= 0 || text.indexOf('未能解析出正文') >= 0 || text.indexOf('扫描件') >= 0) {
      return false;
    }
    return true;
  }

  private async deleteRemote(): Promise<void> {
    const userId = this.currentUserId();
    if (userId.length === 0) {
      return;
    }
    const body: ResumeSaveBody = {
      userId: userId,
      fileName: '',
      fileSize: 0,
      mimeType: '',
      textPreview: '',
      textContent: ''
    };
    await HttpClient.postJson('/api/resume/clear', JSON.stringify(body));
  }

  private static remoteWins(remote: ResumeProfile, local: ResumeProfile | null): boolean {
    const remoteLen = remote.textContent.length;
    if (remoteLen < 20 || remote.textContent.indexOf('服务端将解析') >= 0) {
      return local === null;
    }
    if (local === null) {
      return true;
    }
    return remoteLen > local.textContent.length;
  }

  private async extractTextFull(fileName: string, buffer: ArrayBuffer): Promise<string> {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.txt') || lower.endsWith('.md')) {
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const text = decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });
      const normalized = text.replace(/\r\n/g, '\n').trim();
      if (normalized.length > 12000) {
        return `${normalized.substring(0, 12000)}…`;
      }
      return normalized;
    }
    return `已上传简历「${fileName}」，服务端将解析 PDF/Word 内容并用于个性化面试。`;
  }

  private async clearMeta(context: common.UIAbilityContext): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.delete(PREF_KEY);
    await pref.flush();
  }

  private extractFileName(uri: string): string {
    let raw = uri;
    const queryAt = raw.indexOf('?');
    if (queryAt >= 0) {
      raw = raw.substring(0, queryAt);
    }
    const parts = raw.split('/');
    let last = parts[parts.length - 1];
    try {
      last = decodeURIComponent(last);
    } catch (_e) {
    }
    last = last.replace(/[\\/:*?"<>|]/g, '_');
    if (last.length > 0) {
      return last;
    }
    return `resume_${Date.now()}.pdf`;
  }

  private guessMime(fileName: string): string {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.md')) {
      return 'text/markdown';
    }
    return 'text/plain';
  }

  private async extractTextPreview(filePath: string, fileName: string, buffer: ArrayBuffer): Promise<string> {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.txt') || lower.endsWith('.md')) {
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const text = decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });
      return this.trimPreview(text);
    }
    return `已上传简历「${fileName}」，服务端将解析 PDF/Word 内容并用于个性化面试。`;
  }

  private trimPreview(text: string): string {
    const normalized = text.replace(/\r\n/g, '\n').trim();
    if (normalized.length <= PREVIEW_MAX_LEN) {
      return normalized;
    }
    return `${normalized.substring(0, PREVIEW_MAX_LEN)}…`;
  }
}
