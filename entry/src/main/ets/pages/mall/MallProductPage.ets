import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import {
  MallProduct,
  mallFenText,
  mallGoodsLabel,
  mallNum,
  mallPayLabel,
  mallProductPrice,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';

interface MallProductNav {
  productId?: string;
}

@Entry
@Component
struct MallProductPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private product: MallProduct | null = null;
  private repo: MallRepository = MallRepository.getInstance();
  private productId: string = '';

  aboutToAppear(): void {
    const nav = router.getParams() as MallProductNav;
    this.productId = nav !== undefined && nav.productId !== undefined ? nav.productId : '';
    this.reload();
  }

  private async reload(): Promise<void> {
    if (this.productId.length === 0) {
      this.loading = false;
      return;
    }
    this.loading = true;
    try {
      this.product = await this.repo.product(this.productId);
    } catch (err) {
      this.product = null;
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private productName(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.name);
  }

  private productSubtitle(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.subtitle);
  }

  private productCover(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.coverUrl);
  }

  private productDetail(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.detail);
  }

  private productHint(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.virtualHint);
  }

  private isCashPay(): boolean {
    const p = this.product;
    return p !== null && p.payType === 'cash';
  }

  private isBothPay(): boolean {
    const p = this.product;
    return p !== null && p.payType === 'both';
  }

  private isPanGoods(): boolean {
    const p = this.product;
    return p !== null && p.goodsType === 'pan';
  }

  private buyLabel(): string {
    if (this.isBothPay()) {
      return I18n.t('mall_buy_now', this.lang);
    }
    return this.isCashPay() ? I18n.t('mall_buy_cash', this.lang) : I18n.t('mall_buy_points', this.lang);
  }

  private priceLabel(): string {
    const p = this.product;
    return p === null ? '' : mallProductPrice(p);
  }

  private goodsChip(): string {
    const p = this.product;
    return p === null ? '' : mallGoodsLabel(p.goodsType);
  }

  private payChip(): string {
    const p = this.product;
    return p === null ? '' : mallPayLabel(p.payType);
  }

  private freightLabel(): string {
    const p = this.product;
    if (p === null || p.goodsType !== 'physical' || mallNum(p.freightFen) <= 0) {
      return '';
    }
    return I18n.tf('mall_freight', mallFenText(p.freightFen), this.lang);
  }

  private stockText(): string {
    const p = this.product;
    if (p === null) {
      return '';
    }
    const stock = mallNum(p.stock, -1);
    if (stock < 0) {
      return I18n.t('mall_stock_unlimited', this.lang);
    }
    return I18n.tf('mall_stock', `${stock}`, this.lang);
  }

  private originText(): string {
    const p = this.product;
    if (p === null || (p.payType !== 'cash' && p.payType !== 'both')) {
      return '';
    }
    const sale = mallNum(p.effectivePriceFen, mallNum(p.priceFen));
    if (p.vipActive === true && mallNum(p.priceFen) > sale) {
      return mallFenText(p.priceFen);
    }
    const origin = mallNum(p.originalPriceFen);
    if (origin <= sale) {
      return '';
    }
    return mallFenText(origin);
  }

  private showVipTag(): boolean {
    const p = this.product;
    return p !== null && p.vipActive === true;
  }

  private buy(): void {
    const p = this.product;
    if (p === null) {
      return;
    }
    const stock = mallNum(p.stock, -1);
    if (stock === 0) {
      promptAction.showToast({ message: I18n.t('mall_sold_out', this.lang) });
      return;
    }
    LoginGate.ensure(I18n.t('mall_title', this.lang), () => {
      router.pushUrl({
        url: 'pages/mall/MallConfirmPage',
        params: { 'productId': this.productId }
      });
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('mall_detail', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.product === null) {
        Column() {
          Text(I18n.t('mall_gone', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.productCover().length > 0) {
              Image(this.productCover())
                .width('100%')
                .height(200)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
            }
            Text(this.productName())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            if (this.productSubtitle().length > 0) {
              Text(this.productSubtitle())
                .fontSize(14)
                .fontColor($r('app.color.text_muted'))
                .width('100%')
            }
            Row({ space: 8 }) {
              Text(this.priceLabel())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.danger'))
              if (this.originText().length > 0) {
                Text(this.originText())
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .decoration({ type: TextDecorationType.LineThrough })
              }
              if (this.showVipTag()) {
                Text(I18n.t('mall_vip_tag', this.lang))
                  .fontSize(10)
                  .fontColor($r('app.color.text_on_color'))
                  .backgroundColor($r('app.color.warning_text'))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(4)
              }
            }
            .width('100%')
            Row({ space: 8 }) {
              Text(this.goodsChip())
                .fontSize(12)
                .fontColor($r('app.color.chip_idle_text'))
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(4)
              Text(this.payChip())
                .fontSize(12)
                .fontColor($r('app.color.chip_idle_text'))
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(4)
              Text(this.stockText())
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
            }
            .width('100%')
            if (this.freightLabel().length > 0) {
              Text(this.freightLabel())
                .fontSize(13)
                .fontColor($r('app.color.text_muted'))
                .width('100%')
            }
            if (this.productDetail().length > 0) {
              Text(this.productDetail())
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .lineHeight(22)
                .width('100%')
            }
            if (this.isPanGoods()) {
              Text(I18n.t('mall_pan_hint', this.lang))
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .padding(10)
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(8)
            }
            if (this.productHint().length > 0) {
              Text(this.productHint())
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .padding(10)
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(8)
            }
          }
          .padding({ left: 16, right: 16, bottom: 24 })
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)

        Button(this.buyLabel())
          .width('100%')
          .height(44)
          .margin({ left: 16, right: 16, bottom: 16 })
          .backgroundColor($r('app.color.danger'))
          .fontColor($r('app.color.text_on_color'))
          .onClick(() => {
            this.buy();
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
