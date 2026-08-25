import { HomePage } from './home/HomePage';
import { BankPage } from './bank/BankPage';
import { InterviewPage } from './interview/InterviewPage';
import { StudyPage } from './study/StudyPage';
import { ProfilePage } from './profile/ProfilePage';

@Entry
@Component
struct Index {
  @State private currentIndex: number = 0;

  @Builder
  tabBuilder(title: string, targetIndex: number, icon: string) {
    Column({ space: 2 }) {
      Text(icon).fontSize(20)
      Text(title)
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
      .tabBar(this.tabBuilder('首页', 0, '🏠'))

      TabContent() {
        BankPage()
      }
      .tabBar(this.tabBuilder('题库', 1, '📚'))

      TabContent() {
        InterviewPage()
      }
      .tabBar(this.tabBuilder('AI面试', 2, '🤖'))

      TabContent() {
        StudyPage()
      }
      .tabBar(this.tabBuilder('学习', 3, '📈'))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.tabBuilder('我的', 4, '👤'))
    }
    .width('100%')
    .height('100%')
    .barHeight(58)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
