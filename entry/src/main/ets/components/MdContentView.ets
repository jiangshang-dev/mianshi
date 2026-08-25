import { MdParser } from '../data/parser/MdParser';

@Component
export struct MdContentView {
  @Prop content: string = '';
  @Prop maxHeight: number = 0;

  build() {
    Scroll() {
      Text(MdParser.toPlainReadable(this.content))
        .fontSize(15)
        .fontColor('#1F2937')
        .lineHeight(24)
        .width('100%')
    }
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .constraintSize(this.maxHeight > 0 ? { maxHeight: this.maxHeight } : {})
  }
}
