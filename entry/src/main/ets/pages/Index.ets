import { common } from '@kit.AbilityKit';
import { HomePage } from './home/HomePage';
import { BankPage } from './bank/BankPage';
import { InterviewPage } from './interview/InterviewPage';
import { StudyPage } from './study/StudyPage';
import { ProfilePage } from './profile/ProfilePage';
import { AuthRepository } from '../data/repository/AuthRepository';
import { I18n } from '../common/i18n/I18n';

@Entry
@Component
struct Index {
  @StorageLink('mainTabIndex') currentIndex: number = 0;
  @StorageLink('appLang') lang: string = I18n.HANS;

  aboutToAppear(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    AuthRepository.getInstance().load(ctx);
  }

  @Builder
  tabBuilder(titleKey: string, targetIndex: number, icon: string) {
    Column({ space: 2 }) {
      Text(icon).fontSize(20)
      Text(I18n.t(titleKey, this.lang))
        .fontSize(11)
        .fontColor(this.currentIndex === targetIndex ? '#2563EB' : '#9CA3AF')
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBuilder('tab_home', 0, '🏠'))

      TabContent() {
        BankPage()
      }
      .tabBar(this.tabBuilder('tab_bank', 1, '📚'))

      TabContent() {
        InterviewPage()
      }
      .tabBar(this.tabBuilder('tab_interview', 2, '🤖'))

      TabContent() {
        StudyPage()
      }
      .tabBar(this.tabBuilder('tab_study', 3, '📈'))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.tabBuilder('tab_profile', 4, '👤'))
    }
    .width('100%')
    .height('100%')
    .barHeight(58)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
