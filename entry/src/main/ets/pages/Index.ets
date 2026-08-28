import { common } from '@kit.AbilityKit';
import { HomePage } from './home/HomePage';
import { BankPage } from './bank/BankPage';
import { InterviewPage } from './interview/InterviewPage';
import { ProfilePage } from './profile/ProfilePage';
import { AuthRepository } from '../data/repository/AuthRepository';
import { AppFeatureRepository } from '../data/repository/AppFeatureRepository';
import { I18n } from '../common/i18n/I18n';

@Entry
@Component
struct Index {
  @StorageLink('mainTabIndex') currentIndex: number = 0;
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('interviewAiEnabled') @Watch('onInterviewFlag') interviewAiEnabled: boolean = true;

  aboutToAppear(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    AuthRepository.getInstance().load(ctx);
    AppFeatureRepository.getInstance().refresh();
    this.normalizeIndex();
  }

  onInterviewFlag(): void {
    this.normalizeIndex();
  }

  private normalizeIndex(): void {
    if (!this.interviewAiEnabled && this.currentIndex === 2) {
      this.currentIndex = 0;
    }
  }

  private isTabOn(tabIndex: number): boolean {
    return this.currentIndex === tabIndex;
  }

  private openTab(tabIndex: number): void {
    if (!this.interviewAiEnabled && tabIndex === 2) {
      return;
    }
    this.currentIndex = tabIndex;
  }

  @Builder
  navItem(titleKey: string, tabIndex: number, icon: string) {
    Column({ space: 2 }) {
      Text(icon).fontSize(20)
      Text(I18n.t(titleKey, this.lang))
        .fontSize(11)
        .fontColor(this.isTabOn(tabIndex) ? $r('app.color.accent') : $r('app.color.tab_inactive'))
        .fontWeight(this.isTabOn(tabIndex) ? FontWeight.Medium : FontWeight.Regular)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.openTab(tabIndex);
    })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          HomePage()
        }
        .tabBar('')

        TabContent() {
          BankPage()
        }
        .tabBar('')

        TabContent() {
          InterviewPage()
        }
        .tabBar('')

        TabContent() {
          ProfilePage()
        }
        .tabBar('')
      }
      .layoutWeight(1)
      .width('100%')
      .barHeight(0)
      .onChange((index: number) => {
        if (!this.interviewAiEnabled && index === 2) {
          this.currentIndex = 0;
          return;
        }
        this.currentIndex = index;
      })

      Divider().color($r('app.color.divider'))

      Row() {
        this.navItem('tab_home', 0, '🏠')
        this.navItem('tab_bank', 1, '📚')
        if (this.interviewAiEnabled) {
          this.navItem('tab_interview', 2, '🤖')
        }
        this.navItem('tab_profile', 3, '👤')
      }
      .width('100%')
      .height(58)
      .backgroundColor($r('app.color.card_bg'))
    }
    .width('100%')
    .height('100%')
  }
}
