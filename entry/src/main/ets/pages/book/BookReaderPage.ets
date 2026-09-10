import { common } from '@kit.AbilityKit';
import { componentSnapshot, router } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { pdfService, PdfView, pdfViewManager } from '@kit.PDFKit';
import { I18n } from '../../common/i18n/I18n';
import { BookItem, BookTocItem } from '../../common/models/BookTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BookCache } from '../../common/utils/BookCache';
import { BookMedia } from '../../common/utils/BookMedia';
import { BookOutline } from '../../common/utils/BookOutline';
import { AuthRepository } from '../../data/repository/AuthRepository';
import { BookRepository } from '../../data/repository/BookRepository';

interface BookReaderParams {
  id?: string;
}

@Entry
@Component
struct BookReaderPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private ready: boolean = false;
  @State private title: string = '';
  @State private pageIndex: number = 0;
  @State private pageCount: number = 0;
  @State private hint: string = '';
  @State private zoomScale: number = 1;
  @State private tocOpen: boolean = false;
  @State private toc: BookTocItem[] = [];
  @State private flipOn: boolean = false;
  @State private flipAngle: number = 0;
  @State private flipNext: boolean = true;
  @State private flipMap: image.PixelMap | undefined = undefined;
  @State private viewW: number = 360;
  private bookId: string = '';
  private fitZoom: number = 1;
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();
  private repo: BookRepository = BookRepository.getInstance();
  private lastSaved: number = -1;
  private flipBusy: boolean = false;
  private flipDragging: boolean = false;
  private flipTarget: number = -1;
  private flipCaptured: boolean = false;
  private flipToken: number = 0;
  private flipApplied: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as BookReaderParams;
    this.bookId = params !== undefined && params.id !== undefined ? params.id : '';
    this.openBook();
  }

  aboutToDisappear(): void {
    this.persist(true);
    this.clearFlip(true);
    try {
      this.controller.releaseDocument();
    } catch (_e) {
    }
  }

  private async openBook(): Promise<void> {
    if (this.bookId.length === 0) {
      this.loading = false;
      this.hint = I18n.t('book_open_fail', this.lang);
      return;
    }
    this.loading = true;
    this.hint = I18n.t('book_opening', this.lang);
    let local = '';
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const detail: BookItem = await this.repo.detail(this.bookId);
      this.title = mallStr(detail.title);
      const fileUrl = BookMedia.resolve(mallStr(detail.fileUrl));
      if (fileUrl.length === 0) {
        throw new Error('empty');
      }
      local = await BookCache.ensureFile(ctx, this.bookId, fileUrl);
      const saved = await BookCache.loadProgress(ctx, this.bookId);
      let start = mallNum(detail.lastPage, -1);
      if (start < 0) {
        start = saved.pageIndex;
      }
      if (start < 0) {
        start = 0;
      }
      this.controller.registerPageCountChangedListener((count: number) => {
        this.pageCount = count;
        if (this.toc.length === 0 && count > 0) {
          this.toc = this.fallbackToc();
        }
      });
      this.controller.registerPageChangedListener((index: number) => {
        if (index >= 0 && !this.flipBusy) {
          this.pageIndex = index;
          this.persist(false);
        }
      });
      this.controller.registerScaleChangedListener((zoom: number) => {
        if (!this.isValidZoom(zoom)) {
          return;
        }
        if (!this.isValidZoom(this.fitZoom)) {
          this.fitZoom = zoom;
        }
        this.zoomScale = zoom;
      });
      const result = await this.controller.loadDocument(local);
      if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
        throw new Error('parse');
      }
      this.controller.setPageLayout(pdfService.PageLayout.LAYOUT_SINGLE);
      this.controller.setPageContinuous(false);
      this.controller.setPageFit(pdfService.PageFit.FIT_PAGE);
      if (start > 0) {
        this.controller.goToPage(start);
        this.pageIndex = start;
      }
      try {
        const count = this.controller.getPageCount();
        if (count > 0) {
          this.pageCount = count;
        }
        const index = this.controller.getPageIndex();
        if (index >= 0) {
          this.pageIndex = index;
        }
      } catch (_e) {
      }
      this.fitZoom = 1;
      this.zoomScale = 1;
      this.lastSaved = this.pageIndex;
      this.ready = true;
      if (this.toc.length === 0) {
        this.toc = this.fallbackToc();
      }
      this.loadTocLater(ctx, local);
    } catch (_e) {
      this.ready = false;
      this.hint = I18n.t('book_open_fail', this.lang);
    } finally {
      this.loading = false;
    }
  }

  private loadTocLater(ctx: common.UIAbilityContext, local: string): void {
    const bookId = this.bookId;
    setTimeout(() => {
      if (this.bookId !== bookId) {
        return;
      }
      const copyPath = `${ctx.cacheDir}/book_ol_${bookId}`;
      BookCache.removeFile(copyPath);
      if (!BookCache.copyFile(local, copyPath)) {
        return;
      }
      try {
        const items = BookOutline.load(copyPath, (pageNo: number) => {
          return I18n.tf('book_page_n', `${pageNo}`, this.lang);
        });
        if (items.length > 0) {
          this.toc = items;
        }
      } catch (_e) {
      }
      BookCache.removeFile(copyPath);
    }, 400);
  }

  private fallbackToc(): BookTocItem[] {
    const items: BookTocItem[] = [];
    for (let i = 0; i < this.pageCount; i++) {
      const item: BookTocItem = {
        title: I18n.tf('book_page_n', `${i + 1}`, this.lang),
        pageIndex: i,
        level: 0
      };
      items.push(item);
    }
    return items;
  }

  private pageLabel(): string {
    if (this.pageCount <= 0) {
      return `${this.pageIndex + 1}`;
    }
    return `${this.pageIndex + 1} / ${this.pageCount}`;
  }

  private canSwipePage(): boolean {
    return this.ready && !this.flipBusy && this.safeZoom() <= this.safeFit() * 1.12;
  }

  private capturePage(): image.PixelMap | undefined {
    try {
      return componentSnapshot.getSync('book_pdf_view');
    } catch (_e) {
      return undefined;
    }
  }

  private releaseFlipMap(): void {
    const map = this.flipMap;
    this.flipMap = undefined;
    if (map !== undefined) {
      try {
        map.release();
      } catch (_e) {
      }
    }
  }

  private clearFlip(_force: boolean = false): void {
    this.flipToken += 1;
    this.flipOn = false;
    this.flipAngle = 0;
    this.flipBusy = false;
    this.flipDragging = false;
    this.flipCaptured = false;
    this.flipTarget = -1;
    this.flipApplied = false;
    // 先卸遮罩再释放位图，避免 Image 持有已释放 PixelMap 导致白屏
    setTimeout(() => {
      this.releaseFlipMap();
    }, 32);
  }

  private refreshPdf(index: number): void {
    if (index < 0) {
      return;
    }
    if (this.pageCount > 0 && index >= this.pageCount) {
      return;
    }
    try {
      this.controller.goToPage(index);
      this.controller.setPageFit(pdfService.PageFit.FIT_PAGE);
    } catch (_e) {
    }
    this.pageIndex = index;
    this.persist(false);
  }

  private beginFlip(next: boolean): boolean {
    if (this.flipBusy && !this.flipDragging) {
      return false;
    }
    const target = next ? this.pageIndex + 1 : this.pageIndex - 1;
    if (target < 0) {
      return false;
    }
    if (this.pageCount > 0 && target >= this.pageCount) {
      return false;
    }
    if (!this.flipCaptured) {
      const shot = this.capturePage();
      if (shot === undefined) {
        return false;
      }
      this.releaseFlipMap();
      this.flipMap = shot;
      this.flipCaptured = true;
    }
    this.flipNext = next;
    this.flipTarget = target;
    this.flipApplied = false;
    this.flipOn = true;
    this.flipBusy = true;
    return true;
  }

  private applyFlipDrag(offsetX: number): void {
    if (!this.canSwipePage() && !this.flipDragging) {
      return;
    }
    const goingNext = offsetX < 0;
    const dist = Math.abs(offsetX);
    if (!this.flipDragging) {
      if (dist < 12) {
        return;
      }
      if (!this.beginFlip(goingNext)) {
        return;
      }
      this.flipDragging = true;
    }
    const span = Math.max(this.viewW * 0.62, 180);
    const progress = Math.min(dist / span, 1);
    // 最大约 70°，避免纸面完全立起盖住底层 PDF
    const angle = progress * 70;
    this.flipAngle = this.flipNext ? -angle : angle;
  }

  private finishFlipDrag(offsetX: number, velocityX: number): void {
    if (!this.flipDragging || !this.flipOn) {
      this.flipDragging = false;
      if (Math.abs(offsetX) >= 48 && this.canSwipePage()) {
        if (offsetX < 0) {
          this.flipToNeighbor(true);
        } else {
          this.flipToNeighbor(false);
        }
      }
      return;
    }
    const span = Math.max(this.viewW * 0.62, 180);
    const progress = Math.min(Math.abs(offsetX) / span, 1);
    const fast = Math.abs(velocityX) > 820;
    const commit = progress >= 0.22 || (fast && progress >= 0.08);
    if (commit && this.flipTarget >= 0) {
      this.commitFlip();
    } else {
      this.cancelFlip();
    }
  }

  private commitFlip(): void {
    const target = this.flipTarget;
    const token = ++this.flipToken;
    const endAngle = this.flipNext ? -78 : 78;
    this.flipDragging = false;
    // 先切到目标页，卷起过程中露出真实内容；只切一次，避免 PdfView 白屏
    if (!this.flipApplied) {
      this.flipApplied = true;
      this.refreshPdf(target);
    }
    animateTo({
      duration: 260,
      curve: Curve.EaseOut,
      onFinish: () => {
        if (token !== this.flipToken) {
          return;
        }
        this.finishCommit(target, token);
      }
    }, () => {
      this.flipAngle = endAngle;
    });
    // animateTo onFinish 偶发不触发，兜底清遮罩
    setTimeout(() => {
      if (token !== this.flipToken) {
        return;
      }
      this.finishCommit(target, token);
    }, 360);
  }

  private finishCommit(target: number, token: number): void {
    if (token !== this.flipToken) {
      return;
    }
    this.flipToken += 1;
    this.flipOn = false;
    this.flipAngle = 0;
    this.flipBusy = false;
    this.flipDragging = false;
    this.flipCaptured = false;
    this.flipTarget = -1;
    this.flipApplied = false;
    this.refreshPdf(target);
    setTimeout(() => {
      this.releaseFlipMap();
    }, 32);
  }

  private cancelFlip(): void {
    const token = ++this.flipToken;
    animateTo({
      duration: 200,
      curve: Curve.EaseOut,
      onFinish: () => {
        if (token !== this.flipToken) {
          return;
        }
        this.clearFlip();
      }
    }, () => {
      this.flipAngle = 0;
    });
    setTimeout(() => {
      if (token !== this.flipToken) {
        return;
      }
      this.clearFlip();
    }, 280);
  }

  private flipToNeighbor(next: boolean): void {
    if (!this.beginFlip(next)) {
      if (next) {
        this.refreshPdf(this.pageIndex + 1);
      } else {
        this.refreshPdf(this.pageIndex - 1);
      }
      return;
    }
    this.flipDragging = false;
    this.flipAngle = this.flipNext ? -6 : 6;
    this.commitFlip();
  }

  private applyPage(index: number): void {
    this.refreshPdf(index);
  }

  private prevPage(): void {
    if (!this.ready || this.pageIndex <= 0) {
      return;
    }
    this.flipToNeighbor(false);
  }

  private nextPage(): void {
    if (!this.ready) {
      return;
    }
    if (this.pageCount > 0 && this.pageIndex >= this.pageCount - 1) {
      return;
    }
    this.flipToNeighbor(true);
  }

  private goPage(index: number): void {
    if (index < 0) {
      return;
    }
    if (this.pageCount > 0 && index >= this.pageCount) {
      return;
    }
    if (index === this.pageIndex + 1) {
      this.flipToNeighbor(true);
      return;
    }
    if (index === this.pageIndex - 1) {
      this.flipToNeighbor(false);
      return;
    }
    this.applyPage(index);
  }

  private isValidZoom(value: number): boolean {
    return value === value && value > 0.05 && value < 20;
  }

  private safeZoom(): number {
    return this.isValidZoom(this.zoomScale) ? this.zoomScale : 1;
  }

  private safeFit(): number {
    return this.isValidZoom(this.fitZoom) ? this.fitZoom : 1;
  }

  private clampZoom(value: number): number {
    if (!this.isValidZoom(value)) {
      return 1;
    }
    if (value < 0.5) {
      return 0.5;
    }
    if (value > 4) {
      return 4;
    }
    return Math.round(value * 100) / 100;
  }

  private applyZoom(value: number): void {
    if (!this.ready) {
      return;
    }
    const next = this.clampZoom(value);
    try {
      this.controller.setPageZoom(next);
      this.zoomScale = next;
    } catch (_e) {
    }
  }

  private zoomOut(): void {
    this.applyZoom(this.safeZoom() - 0.25);
  }

  private zoomIn(): void {
    this.applyZoom(this.safeZoom() + 0.25);
  }

  private toggleZoom(): void {
    if (!this.ready) {
      return;
    }
    if (this.safeZoom() > this.safeFit() * 1.2) {
      try {
        this.controller.setPageFit(pdfService.PageFit.FIT_PAGE);
        this.zoomScale = this.safeFit();
      } catch (_e) {
        this.applyZoom(this.safeFit());
      }
    } else {
      this.applyZoom(this.safeFit() * 2);
    }
  }

  private zoomText(): string {
    const pct = Math.round(this.safeZoom() * 100 / this.safeFit());
    if (pct !== pct || pct <= 0) {
      return '100%';
    }
    return `${pct}%`;
  }

  private openToc(): void {
    if (!this.ready) {
      return;
    }
    this.tocOpen = true;
  }

  private jumpToc(item: BookTocItem): void {
    this.tocOpen = false;
    this.goPage(item.pageIndex);
  }

  private flipShadow(): number {
    const a = Math.abs(this.flipAngle);
    return Math.min(0.55, a / 90 * 0.55);
  }

  private flipCurl(): number {
    const a = Math.abs(this.flipAngle);
    return Math.min(28, 6 + a * 0.22);
  }

  private persist(force: boolean): void {
    if (!this.ready || this.bookId.length === 0) {
      return;
    }
    if (!force && this.lastSaved === this.pageIndex) {
      return;
    }
    this.lastSaved = this.pageIndex;
    const count = this.pageCount;
    const index = this.pageIndex;
    const id = this.bookId;
    const ctx = getContext(this) as common.UIAbilityContext;
    BookCache.saveProgress(ctx, id, index, count).then(() => {
      if (AuthRepository.getInstance().isLoggedIn()) {
        this.repo.saveProgress(id, index, count).catch(() => {
        });
      }
    });
  }

  @Builder
  private FlipOverlay() {
    if (this.flipOn && this.flipMap !== undefined) {
      Stack() {
        Image(this.flipMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
          .rotate({
            x: 0,
            y: 1,
            z: 0,
            angle: this.flipAngle,
            centerX: this.flipNext ? '0%' : '100%',
            centerY: '50%',
            perspective: 1200
          })
          .shadow({
            radius: this.flipCurl(),
            color: '#55000000',
            offsetX: this.flipNext ? -10 : 10,
            offsetY: 0
          })

        // 仅卷边阴影，不再铺整页纸背（纸背会把底层 PDF 盖成白屏）
        Row() {
          if (this.flipNext) {
            Blank()
            Column()
              .width(36)
              .height('100%')
              .linearGradient({
                angle: 180,
                colors: [['#88000000', 0], ['#22000000', 0.4], ['#00000000', 1]]
              })
              .opacity(this.flipShadow())
          } else {
            Column()
              .width(36)
              .height('100%')
              .linearGradient({
                angle: 0,
                colors: [['#88000000', 0], ['#22000000', 0.4], ['#00000000', 1]]
              })
              .opacity(this.flipShadow())
            Blank()
          }
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
        .rotate({
          x: 0,
          y: 1,
          z: 0,
          angle: this.flipAngle,
          centerX: this.flipNext ? '0%' : '100%',
          centerY: '50%',
          perspective: 1200
        })
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
    }
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Row() {
            Text('‹')
              .fontSize(28)
              .fontColor($r('app.color.text_primary'))
              .padding({ right: 8 })
              .onClick(() => router.back())
            Text(this.title.length > 0 ? this.title : I18n.t('tab_book', this.lang))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(I18n.t('book_toc', this.lang))
              .fontSize(14)
              .fontColor('#2563EB')
              .padding({ left: 10, right: 4, top: 4, bottom: 4 })
              .onClick(() => this.openToc())
          }
          .width('100%')
          .height(44)
          .padding({ left: 12, right: 12 })
          Row() {
            Text('−')
              .fontSize(20)
              .fontColor($r('app.color.text_primary'))
              .width(32)
              .height(28)
              .textAlign(TextAlign.Center)
              .onClick(() => this.zoomOut())
            Text(this.zoomText())
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
              .onClick(() => this.toggleZoom())
            Text('+')
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .width(32)
              .height(28)
              .textAlign(TextAlign.Center)
              .onClick(() => this.zoomIn())
            Blank()
            Text(this.pageLabel())
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
          }
          .width('100%')
          .height(32)
          .padding({ left: 8, right: 16 })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')

        Stack() {
          if (this.ready) {
            PdfView({
              controller: this.controller,
              pageLayout: pdfService.PageLayout.LAYOUT_SINGLE,
              isContinuous: false,
              showScroll: false,
              pageFit: pdfService.PageFit.FIT_PAGE
            })
              .id('book_pdf_view')
              .width('100%')
              .height('100%')
          }
          this.FlipOverlay()
          if (this.loading || !this.ready) {
            Column({ space: 10 }) {
              if (this.loading) {
                LoadingProgress().width(40).height(40).color('#2563EB')
              }
              Text(this.hint.length > 0 ? this.hint : I18n.t('book_opening', this.lang))
                .fontSize(13)
                .fontColor($r('app.color.text_muted'))
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor($r('app.color.page_bg'))
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F8FAFC')
        .clip(true)
        .onAreaChange((_o: Area, n: Area) => {
          const w = Number(n.width);
          if (w > 0) {
            this.viewW = w;
          }
        })
        .parallelGesture(
          GestureGroup(GestureMode.Exclusive,
            PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 8 })
              .onActionUpdate((event: GestureEvent) => {
                this.applyFlipDrag(event.offsetX);
              })
              .onActionEnd((event: GestureEvent) => {
                this.finishFlipDrag(event.offsetX, event.velocityX);
              })
              .onActionCancel(() => {
                if (this.flipDragging) {
                  this.cancelFlip();
                }
              }),
            TapGesture({ count: 2 })
              .onAction(() => {
                this.toggleZoom();
              })
          )
        )
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      if (this.tocOpen) {
        Row() {
          Column()
            .layoutWeight(1)
            .height('100%')
            .onClick(() => {
              this.tocOpen = false;
            })
          Column() {
            Row() {
              Text(I18n.t('book_toc', this.lang))
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Text(I18n.t('book_close', this.lang))
                .fontSize(14)
                .fontColor($r('app.color.text_muted'))
                .onClick(() => {
                  this.tocOpen = false;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 10 })
            Column() {
              if (this.toc.length === 0) {
                Text(I18n.t('book_toc_empty', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .padding(16)
                  .width('100%')
              } else {
                List() {
                  ForEach(this.toc, (item: BookTocItem, idx: number) => {
                    ListItem() {
                      Row() {
                        Column({ space: 4 }) {
                          Text(item.title)
                            .fontSize(14)
                            .fontColor(this.pageIndex === item.pageIndex ? '#2563EB' : $r('app.color.text_primary'))
                            .fontWeight(this.pageIndex === item.pageIndex ? FontWeight.Medium : FontWeight.Regular)
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Text(I18n.tf('book_page_n', `${item.pageIndex + 1}`, this.lang))
                            .fontSize(11)
                            .fontColor($r('app.color.text_muted'))
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)
                        .padding({ left: item.level * 12 })
                      }
                      .width('100%')
                      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                      .backgroundColor(this.pageIndex === item.pageIndex ? '#EFF6FF' : Color.Transparent)
                      .onClick(() => this.jumpToc(item))
                    }
                  }, (item: BookTocItem, idx: number) => `${idx}-${item.pageIndex}-${item.title}`)
                }
                .width('100%')
                .layoutWeight(1)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
              }
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('78%')
          .height('100%')
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
  }
}
