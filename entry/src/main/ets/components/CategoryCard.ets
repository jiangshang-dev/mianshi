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
    source: 'remote_api',
    articleCount: 0,
    children: []
  };
  onCardClick: (category: Category) => void = () => {};

  private nameFontSize(): number {
    const len = this.category.name.length;
    if (len <= 8) {
      return 14;
    }
    if (len <= 10) {
      return 12;
    }
    return 11;
  }

  build() {
    Column({ space: 8 }) {
      CategoryIcon({ icon: this.category.icon, iconSize: 28 })
      Text(this.category.name)
        .fontSize(this.nameFontSize())
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .wordBreak(WordBreak.BREAK_ALL)
        .width('100%')
      Text(I18n.tf('q_count', `${this.category.articleCount}`, this.lang))
        .fontSize(11)
        .fontColor($r('app.color.text_muted'))
    }
    .width('100%')
    .padding({ left: 6, right: 6, top: 16, bottom: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => this.onCardClick(this.category))
  }
}
