import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { I18n } from '../common/i18n/I18n';
import { LangManager } from '../common/i18n/LangManager';
import { ThemeManager } from '../common/theme/ThemeManager';
import { SettingsFlags } from '../common/settings/SettingsFlags';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('isLoggedIn', false);
    AppStorage.setOrCreate('userDisplayName', '');
    AppStorage.setOrCreate('userAvatarUrl', '');
    AppStorage.setOrCreate('userToken', '');
    AppStorage.setOrCreate('userId', '');
    AppStorage.setOrCreate('mainTabIndex', 0);
    AppStorage.setOrCreate('globalResumeFileName', '');
    AppStorage.setOrCreate(I18n.KEY, I18n.HANS);
    AppStorage.setOrCreate(ThemeManager.KEY, ThemeManager.SYSTEM);
    AppStorage.setOrCreate('colorMode', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    AppStorage.setOrCreate(SettingsFlags.NOTIFY, true);
    AppStorage.setOrCreate(SettingsFlags.REMIND, false);
    AppStorage.setOrCreate('commentSheetOpen', false);
    AppStorage.setOrCreate('commentComposeOpen', false);
    AppStorage.setOrCreate('commentDetailOpen', false);
    AppStorage.setOrCreate('commentReplyToId', '');
    AppStorage.setOrCreate('commentReplyToName', '');
    AppStorage.setOrCreate('commentDetailId', '');
    AppStorage.setOrCreate('commentQuestionId', '');
    AppStorage.setOrCreate('commentReloadTick', 0);
    AppStorage.setOrCreate('commentFeatureEnabled', true);
    AppStorage.setOrCreate('questionAiEnabled', true);
    AppStorage.setOrCreate('interviewAiEnabled', true);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    Promise.all([
      LangManager.load(this.context),
      ThemeManager.load(this.context),
      SettingsFlags.load(this.context)
    ]).then(() => {
      this.loadIndex(windowStage);
    }).catch(() => {
      this.loadIndex(windowStage);
    });
  }

  onConfigurationUpdated(newConfig: Configuration): void {
    AppStorage.setOrCreate('colorMode', newConfig.colorMode);
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  private loadIndex(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
