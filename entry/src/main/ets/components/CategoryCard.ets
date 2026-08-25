import { Category } from '../common/models/Types';
import { CategoryIcon } from './CategoryIcon';
import { I18n } from '../common/i18n/I18n';

@Component
export struct CategoryCard {
  @StorageLink('appLang') lang: string = I18n.HANS;
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
      CategoryIcon({ icon: this.category.icon, iconSize: 28 })
      Text(this.category.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
        .maxLines(1)
      Text(I18n.tf('q_count', `${this.category.articleCount}`, this.lang))
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
