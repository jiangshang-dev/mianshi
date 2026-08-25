import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xC0DE;

export class RawFileUtil {
  static async readText(context: common.UIAbilityContext, relativePath: string): Promise<string> {
    try {
      const buffer: Uint8Array = await context.resourceManager.getRawFileContent(relativePath);
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      return decoder.decodeWithStream(buffer, { stream: false });
    } catch (err) {
      hilog.error(DOMAIN, 'RawFileUtil', 'readText failed path=%{public}s err=%{public}s',
        relativePath, JSON.stringify(err));
      throw new Error(`readText failed: ${relativePath}`);
    }
  }
}
