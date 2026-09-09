import { common } from '@kit.AbilityKit';
import { HomePage } from './home/HomePage';
import { BookPage } from './book/BookPage';
import { StudyPage } from './study/StudyPage';
import { InterviewPage } from './interview/InterviewPage';
import { ProfilePage } from './profile/ProfilePage';
import { AuthRepository } from '../data/repository/AuthRepository';
import { AppFeatureRepository } from '../data/repository/AppFeatureRepository';
import { MemberRepository } from '../data/repository/MemberRepository';
import { PointsRepository } from '../data/repository/PointsRepository';
import { I18n } from '../common/i18n/I18n';

@Entry
@Component
struct Index {
  @StorageLink('mainTabIndex') currentIndex: number = 0;
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('interviewAiEnabled') @Watch('onFeatureFlag') interviewAiEnabled: boolean = true;

  aboutToAppear(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    AuthRepository.getInstance().load(ctx).then(() => {
      this.refreshPoints();
    });
    AppFeatureRepository.getInstance().refresh();
    MemberRepository.getInstance().refreshStatus();
    this.normalizeIndex();
  }

  onPageShow(): void {
    AppFeatureRepository.getInstance().refresh();
    MemberRepository.getInstance().refreshStatus();
    this.refreshPoints();
  }

  private refreshPoints(): void {
    if (!AuthRepository.getInstance().isLoggedIn()) {
      return;
    }
    PointsRepository.getInstance().me().catch(() => {
    });
  }

  onFeatureFlag(): void {
    this.normalizeIndex();
  }

  private normalizeIndex(): void {
    if (!this.interviewAiEnabled && this.currentIndex === 3) {
      this.currentIndex = 0;
    }
  }

  private isTabOn(tabIndex: number): boolean {
    return this.currentIndex === tabIndex;
  }

  private openTab(tabIndex: number): void {
    if (!this.interviewAiEnabled && tabIndex === 3) {
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
          BookPage()
        }
        .tabBar('')

        TabContent() {
          StudyPage()
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
        if (!this.interviewAiEnabled && index === 3) {
          this.currentIndex = 0;
          return;
        }
        this.currentIndex = index;
      })

      Divider().color($r('app.color.divider'))

      Row() {
        this.navItem('tab_home', 0, '🏠')
        this.navItem('tab_book', 1, '📕')
        this.navItem('tab_study', 2, '📋')
        if (this.interviewAiEnabled) {
          this.navItem('tab_interview', 3, '🤖')
        }
        this.navItem('tab_profile', 4, '👤')
      }
      .width('100%')
      .height(58)
      .backgroundColor($r('app.color.card_bg'))
    }
    .width('100%')
    .height('100%')
  }
}
