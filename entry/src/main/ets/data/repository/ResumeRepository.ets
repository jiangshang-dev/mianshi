import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ResumeProfile } from '../../common/models/ResumeTypes';

const DOMAIN = 0xC0DE;
const PREF_NAME = 'resume_profile';
const PREF_KEY = 'resume_meta';
const RESUME_DIR = 'resume';
const PREVIEW_MAX_LEN = 2000;

export class ResumeRepository {
  private static instance: ResumeRepository | null = null;
  private cached: ResumeProfile | null = null;

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
      try {
        fileIo.accessSync(profile.filePath);
        this.cached = profile;
        return profile;
      } catch (err) {
        await this.clearMeta(context);
        return null;
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'load failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  async pickAndSave(context: common.UIAbilityContext): Promise<ResumeProfile | null> {
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.pdf', '.doc', '.docx', '.txt', '.md'];
      const uris = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        return null;
      }
      return await this.saveFromUri(context, uris[0]);
    } catch (err) {
      hilog.warn(DOMAIN, 'ResumeRepository', 'pickAndSave failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  async saveFromUri(context: common.UIAbilityContext, uri: string): Promise<ResumeProfile | null> {
    const fileName = this.extractFileName(uri);
    const dir = `${context.filesDir}/${RESUME_DIR}`;
    fileIo.mkdirSync(dir, true);
    const destPath = `${dir}/${fileName}`;

    const srcFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat = fileIo.statSync(srcFile.fd);
    const buffer = new ArrayBuffer(stat.size);
    fileIo.readSync(srcFile.fd, buffer);
    fileIo.closeSync(srcFile);

    const destFile = fileIo.openSync(destPath,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(destFile.fd, buffer);
    fileIo.closeSync(destFile);

    const textPreview = await this.extractTextPreview(destPath, fileName, buffer);
    const profile: ResumeProfile = {
      fileName,
      filePath: destPath,
      fileSize: stat.size,
      mimeType: this.guessMime(fileName),
      uploadedAt: new Date().toISOString(),
      textPreview,
      resumeId: '',
      syncStatus: 'local'
    };
    await this.persist(context, profile);
    this.cached = profile;
    return profile;
  }

  async clear(context: common.UIAbilityContext): Promise<void> {
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

  private async clearMeta(context: common.UIAbilityContext): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.delete(PREF_KEY);
    await pref.flush();
  }

  private extractFileName(uri: string): string {
    const parts = uri.split('/');
    const last = parts[parts.length - 1];
    if (last.length > 0) {
      return decodeURIComponent(last);
    }
    return `resume_${Date.now()}.txt`;
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
