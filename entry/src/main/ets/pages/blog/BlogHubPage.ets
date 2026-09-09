import { BlogPage } from './BlogPage';

@Entry
@Component
struct BlogHubPage {
  build() {
    Column() {
      BlogPage({ showNavBack: true })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
