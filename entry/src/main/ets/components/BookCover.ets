import { BookItem } from '../common/models/BookTypes';
import { mallStr } from '../common/models/MallTypes';
import { BookMedia } from '../common/utils/BookMedia';

@Component
export struct BookCover {
  @Prop item: BookItem = {};
  @Prop coverWidth: number = 72;
  @Prop coverHeight: number = 96;

  private src(): string {
    return BookMedia.resolve(mallStr(this.item.coverUrl));
  }

  build() {
    Stack() {
      Column()
        .width(this.coverWidth)
        .height(this.coverHeight)
        .borderRadius(8)
        .linearGradient({
          angle: 160,
          colors: [['#1E3A8A', 0], ['#2563EB', 1]]
        })
      if (this.src().length > 0) {
        Image(this.src())
          .width(this.coverWidth)
          .height(this.coverHeight)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      } else {
        Text(mallStr(this.item.title).length > 0 ? mallStr(this.item.title).substring(0, 1) : '书')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width(this.coverWidth)
    .height(this.coverHeight)
    .borderRadius(8)
    .clip(true)
    .shadow({ radius: 8, color: '#33000000', offsetY: 3 })
  }
}
