import { QuestionItem } from '../common/models/Types';

@Component
export struct QuestionListItem {
  @Prop item: QuestionItem = {
    id: '',
    title: '',
    categoryId: '',
    categoryName: '',
    tags: [],
    difficulty: '',
    hot: false,
    source: 'local_md',
    mastery: 0,
    favorited: false
  };
  onItemClick: (item: QuestionItem) => void = () => {};

  build() {
    Row() {
      Column({ space: 8 }) {
        Row({ space: 6 }) {
          if (this.item.hot) {
            Text('高频')
              .fontSize(10)
              .fontColor('#B45309')
              .backgroundColor('#FEF3C7')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
          }
          Text(this.item.source === 'local_md' ? '本地MD' : '远程API')
            .fontSize(10)
            .fontColor(this.item.source === 'local_md' ? '#047857' : '#1D4ED8')
            .backgroundColor(this.item.source === 'local_md' ? '#D1FAE5' : '#DBEAFE')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
          Text(this.item.difficulty)
            .fontSize(10)
            .fontColor('#6B7280')
        }

        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(this.item.categoryName)
            .fontSize(12)
            .fontColor('#6B7280')
          if (this.item.tags.length > 0) {
            Text(this.item.tags.slice(0, 2).join(' · '))
              .fontSize(12)
              .fontColor('#9CA3AF')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor('#D1D5DB')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => this.onItemClick(this.item))
  }
}
