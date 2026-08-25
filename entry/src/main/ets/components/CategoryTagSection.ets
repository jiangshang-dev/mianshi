import { Category } from '../common/models/Types';

@Component
export struct CategoryTagSection {
  @Prop title: string = '';
  @Prop items: Category[] = [];
  @Prop textColor: string = '#9A3412';
  @Prop chipColor: string = '#FFEDD5';
  onTagClick: (cat: Category) => void = () => {};

  build() {
    if (this.items.length === 0) {
      Column()
        .width(0)
        .height(0)
    } else {
      Column({ space: 8 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.items, (c: Category) => {
            Text(c.name)
              .fontSize(13)
              .fontColor(this.textColor)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
              .backgroundColor(this.chipColor)
              .borderRadius(16)
              .onClick(() => this.onTagClick(c))
          }, (c: Category) => c.id)
        }
        .width('100%')
      }
      .width('100%')
    }
  }
}
