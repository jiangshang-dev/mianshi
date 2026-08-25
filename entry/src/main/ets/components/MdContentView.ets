import { MdBlockNode, MdBlocks, MdInlineSpan } from '../data/parser/MdParser';

@Component
struct MdInlineText {
  @Prop inlines: MdInlineSpan[] = [];
  @Prop textSize: number = 14;
  @Prop textColor: string = '#1F2937';
  @Prop heading: boolean = false;

  build() {
    Text() {
      ForEach(this.inlines, (s: MdInlineSpan, idx: number) => {
        Span(s.text)
          .fontSize(s.code ? this.textSize - 1 : this.textSize)
          .fontColor(s.code ? '#9A3412' : this.textColor)
          .fontWeight((this.heading || s.bold) ? FontWeight.Bold : FontWeight.Normal)
          .fontStyle(s.italic ? FontStyle.Italic : FontStyle.Normal)
          .backgroundColor(s.code ? '#FFEDD5' : Color.Transparent)
      }, (s: MdInlineSpan, idx: number) => `${idx}-${s.text}-${s.bold}-${s.code}-${s.italic}`)
    }
    .width('100%')
    .lineHeight(this.textSize + 8)
  }
}

@Component
export struct MdContentView {
  @Prop content: string = '';
  @Prop compact: boolean = false;

  build() {
    Column({ space: this.compact ? 6 : 8 }) {
      ForEach(MdBlocks.parse(this.content), (block: MdBlockNode, idx: number) => {
        if (block.kind === 'code') {
          Text(block.code.length > 0 ? block.code : ' ')
            .fontSize(this.compact ? 12 : 13)
            .fontColor('#F9FAFB')
            .fontFamily('monospace')
            .lineHeight(this.compact ? 18 : 20)
            .width('100%')
            .padding(this.compact ? 8 : 10)
            .backgroundColor('#1F2937')
            .borderRadius(8)
        } else if (block.kind === 'hr') {
          Divider().color('#E5E7EB').strokeWidth(1).margin({ top: 4, bottom: 4 })
        } else if (block.kind === 'li') {
          Row({ space: 6 }) {
            Text(block.bullet.length > 0 ? block.bullet : '•')
              .fontSize(this.compact ? 13 : 14)
              .fontColor('#4B5563')
              .width(20)
            MdInlineText({
              inlines: block.inlines,
              textSize: this.compact ? 13 : 14,
              textColor: '#111827'
            })
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        } else if (block.kind === 'quote') {
          Column() {
            MdInlineText({
              inlines: block.inlines,
              textSize: this.compact ? 13 : 14,
              textColor: '#4B5563'
            })
          }
          .width('100%')
          .padding({ left: 10, top: 4, bottom: 4, right: 6 })
          .border({ width: { left: 3 }, color: '#93C5FD' })
          .backgroundColor('#F8FAFC')
          .borderRadius(4)
        } else if (block.kind === 'h1') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 17 : 20,
            textColor: '#111827',
            heading: true
          })
        } else if (block.kind === 'h2') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 16 : 18,
            textColor: '#111827',
            heading: true
          })
        } else if (block.kind === 'h3') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 15 : 16,
            textColor: '#111827',
            heading: true
          })
        } else {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 14 : 15,
            textColor: '#1F2937'
          })
        }
      }, (block: MdBlockNode, idx: number) => `b-${idx}-${block.kind}-${block.bullet}-${block.code.length}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
