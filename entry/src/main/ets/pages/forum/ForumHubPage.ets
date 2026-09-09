import { ForumPage } from './ForumPage';

@Entry
@Component
struct ForumHubPage {
  build() {
    Column() {
      ForumPage({ showNavBack: true })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
