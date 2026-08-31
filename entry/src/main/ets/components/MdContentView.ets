import { AppConfig } from '../common/constants/AppConfig';
import { I18n } from '../common/i18n/I18n';
import { MdBlockNode, MdBlocks, MdInlineSpan, MdTableCell, MdTableRow } from '../data/parser/MdParser';

@Component
struct MdInlineText {
  @Prop inlines: MdInlineSpan[] = [];
  @Prop textSize: number = 14;
  @Prop muted: boolean = false;
  @Prop heading: boolean = false;

  build() {
    Text() {
      ForEach(this.inlines, (s: MdInlineSpan, idx: number) => {
        Span(s.text)
          .fontSize(s.code ? this.textSize - 1 : this.textSize)
          .fontColor(s.code ? '#9A3412' : (this.muted ? $r('app.color.text_secondary') : $r('app.color.text_primary')))
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
struct MdImageBlock {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop src: string = '';
  @State private failed: boolean = false;
  @State private previewOpen: boolean = false;
  @State private zoomScale: number = 1;
  @State private offsetX: number = 0;
  @State private offsetY: number = 0;
  private pinchStart: number = 1;
  private panStartX: number = 0;
  private panStartY: number = 0;

  private resolved(): string {
    const src = this.src.trim();
    if (src.indexOf('http://') === 0 || src.indexOf('https://') === 0 || src.indexOf('data:') === 0) {
      return src;
    }
    let path = src;
    if (path.indexOf('/') === 0) {
      path = path.substring(1);
    }
    return `${AppConfig.REMOTE_API_BASE}/${path}`;
  }

  private clampScale(value: number): number {
    if (value < 1) {
      return 1;
    }
    if (value > 4) {
      return 4;
    }
    return value;
  }

  private openPreview(): void {
    this.zoomScale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.pinchStart = 1;
    this.previewOpen = true;
  }

  private closePreview(): void {
    this.previewOpen = false;
    this.zoomScale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
  }

  @Builder
  PreviewCover() {
    Stack() {
      Image(this.resolved())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .scale({ x: this.zoomScale, y: this.zoomScale })
        .translate({ x: this.offsetX, y: this.offsetY })
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            TapGesture({ count: 2 })
              .onAction(() => {
                if (this.zoomScale > 1.2) {
                  this.zoomScale = 1;
                  this.offsetX = 0;
                  this.offsetY = 0;
                } else {
                  this.zoomScale = 2.4;
                }
              }),
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                this.pinchStart = this.zoomScale;
              })
              .onActionUpdate((event: GestureEvent) => {
                this.zoomScale = this.clampScale(this.pinchStart * event.scale);
              }),
            PanGesture({ fingers: 1 })
              .onActionStart(() => {
                this.panStartX = this.offsetX;
                this.panStartY = this.offsetY;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (this.zoomScale <= 1.05) {
                  return;
                }
                this.offsetX = this.panStartX + event.offsetX;
                this.offsetY = this.panStartY + event.offsetY;
              })
          )
        )
      Row() {
        Text(I18n.t('image_preview_close', this.lang))
          .fontSize(15)
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 14, top: 10, bottom: 10 })
          .onClick(() => {
            this.closePreview();
          })
        Blank()
        Text(I18n.t('image_preview_hint', this.lang))
          .fontSize(12)
          .fontColor('#D1D5DB')
          .padding({ right: 16, top: 10, bottom: 10 })
      }
      .width('100%')
      .padding({ top: 36 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  build() {
    Column({ space: 4 }) {
      if (this.failed) {
        Text(I18n.t('image_load_fail', this.lang))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      } else {
        Image(this.resolved())
          .width('100%')
          .constraintSize({ minHeight: 96, maxHeight: 420 })
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .onError(() => {
            this.failed = true;
          })
          .onClick(() => {
            this.openPreview();
          })
      }
    }
    .width('100%')
    .bindContentCover(this.previewOpen, this.PreviewCover(), {
      modalTransition: ModalTransition.ALPHA,
      backgroundColor: Color.Black,
      onDisappear: () => {
        this.closePreview();
      }
    })
  }
}

@Component
struct MdTableBlock {
  @Prop rows: MdTableRow[] = [];
  @Prop compact: boolean = false;
  private scroller: Scroller = new Scroller();

  private colWidth(): number {
    const n = this.rows.length > 0 ? this.rows[0].cells.length : 1;
    if (n <= 2) {
      return 148;
    }
    if (n === 3) {
      return 112;
    }
    return 96;
  }

  private tableWidth(): number {
    const n = this.rows.length > 0 ? this.rows[0].cells.length : 1;
    return this.colWidth() * Math.max(1, n);
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        ForEach(this.rows, (row: MdTableRow, r: number) => {
          Row() {
            ForEach(row.cells, (cell: MdTableCell, c: number) => {
              Column() {
                MdInlineText({
                  inlines: cell.inlines,
                  textSize: this.compact ? 12 : 13,
                  heading: r === 0
                })
              }
              .width(this.colWidth())
              .padding(this.compact ? 6 : 8)
              .justifyContent(FlexAlign.Start)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(r === 0 ? $r('app.color.preview_bg') : Color.Transparent)
              .border({
                width: { right: 1, bottom: 1 },
                color: $r('app.color.divider')
              })
            }, (cell: MdTableCell, c: number) => `c-${r}-${c}`)
          }
          .alignItems(VerticalAlign.Top)
        }, (row: MdTableRow, r: number) => `r-${r}-${row.cells.length}`)
      }
      .width(this.tableWidth())
      .border({ width: { left: 1, top: 1 }, color: $r('app.color.divider') })
      .borderRadius(8)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Auto)
    .width('100%')
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
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
          Divider().color($r('app.color.divider')).strokeWidth(1).margin({ top: 4, bottom: 4 })
        } else if (block.kind === 'img') {
          MdImageBlock({ src: block.src })
        } else if (block.kind === 'table') {
          MdTableBlock({ rows: block.rows, compact: this.compact })
        } else if (block.kind === 'li') {
          Row({ space: 6 }) {
            Text(block.bullet.length > 0 ? block.bullet : '•')
              .fontSize(this.compact ? 13 : 14)
              .fontColor($r('app.color.text_secondary'))
              .width(20)
            MdInlineText({
              inlines: block.inlines,
              textSize: this.compact ? 13 : 14
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
              muted: true
            })
          }
          .width('100%')
          .padding({ left: 10, top: 4, bottom: 4, right: 6 })
          .border({ width: { left: 3 }, color: '#93C5FD' })
          .backgroundColor($r('app.color.preview_bg'))
          .borderRadius(4)
        } else if (block.kind === 'h1') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 17 : 20,
            heading: true
          })
        } else if (block.kind === 'h2') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 16 : 18,
            heading: true
          })
        } else if (block.kind === 'h3') {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 15 : 16,
            heading: true
          })
        } else {
          MdInlineText({
            inlines: block.inlines,
            textSize: this.compact ? 14 : 15
          })
        }
      }, (block: MdBlockNode, idx: number) => `b-${idx}-${block.kind}-${block.bullet}-${block.src}-${block.rows.length}-${block.code.length}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
