import { AbilityConstant, bundleManager, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, window } from '@kit.ArkUI';
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
    AppStorage.setOrCreate('forumListTick', 0);
    AppStorage.setOrCreate('blogCommentTick', 0);
    AppStorage.setOrCreate('commentFeatureEnabled', true);
    AppStorage.setOrCreate('questionAiEnabled', true);
    AppStorage.setOrCreate('interviewAiEnabled', true);
    AppStorage.setOrCreate('memberEnabled', true);
    AppStorage.setOrCreate('blogEnabled', true);
    AppStorage.setOrCreate('forumEnabled', true);
    AppStorage.setOrCreate('isMember', false);
    AppStorage.setOrCreate('isLifetimeMember', false);
    AppStorage.setOrCreate('memberPlanName', '');
    AppStorage.setOrCreate('memberExpireTime', 0);
    AppStorage.setOrCreate('userPoints', 0);
    AppStorage.setOrCreate('userTodayChecked', false);
    AppStorage.setOrCreate('userCheckinStreak', 0);
    AppStorage.setOrCreate('userTodayReward', 10);
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

  private logAlipayFingerprint(): void {
    const flags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
    bundleManager.getBundleInfoForSelf(flags).then((info: bundleManager.BundleInfo) => {
      const raw = info.signatureInfo.fingerprint;
      const normalized = raw.replace(/:/g, '').toLowerCase();
      console.info('alipay_sign=' + normalized);
      hilog.info(DOMAIN, 'alipay', 'bundleName=%{public}s', info.name);
      hilog.info(DOMAIN, 'alipay', 'fingerprint=%{public}s', raw);
      hilog.info(DOMAIN, 'alipay', 'alipay_sign=%{public}s', normalized);
      promptAction.showToast({ message: '应用签名 ' + normalized, duration: 5000 });
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, 'alipay', 'fingerprint failed code=%{public}d msg=%{public}s',
        err.code, err.message);
    });
  }

  private loadIndex(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      this.logAlipayFingerprint();
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
