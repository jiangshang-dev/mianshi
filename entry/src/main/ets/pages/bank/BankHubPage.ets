import { BankPage } from './BankPage';

@Entry
@Component
struct BankHubPage {
  build() {
    Column() {
      BankPage({ showNavBack: true })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
