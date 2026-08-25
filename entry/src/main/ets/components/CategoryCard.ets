import { Category } from '../common/models/Types';

@Component
export struct CategoryCard {
  @Prop category: Category = {
    id: '',
    name: '',
    icon: '📘',
    order: 0,
    group: '',
    source: 'local_md',
    articleCount: 0,
    children: []
  };
  onCardClick: (category: Category) => void = () => {};

  build() {
    Column({ space: 8 }) {
      Text(this.category.icon)
        .fontSize(28)
      Text(this.category.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
        .maxLines(1)
      Text(this.category.source === 'local_md' ?
        `${this.category.articleCount} 篇` : 'API')
        .fontSize(11)
        .fontColor('#6B7280')
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(Color.White)
    .borderRadius(14)
    .onClick(() => this.onCardClick(this.category))
  }
}
