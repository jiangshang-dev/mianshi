import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import {
  MallCategory,
  MallProduct,
  mallGoodsLabel,
  mallProductPrice,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';
import { PointsRepository } from '../../data/repository/PointsRepository';

@Entry
@Component
struct MallPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private products: MallProduct[] = [];
  @State private shown: MallProduct[] = [];
  @State private categories: MallCategory[] = [];
  @State private catId: string = '';
  @StorageLink('userPoints') userPoints: number = 0;
  private repo: MallRepository = MallRepository.getInstance();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.loadPoints();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      try {
        this.categories = await this.repo.categories();
      } catch (_e) {
        this.categories = [];
      }
      this.products = await this.repo.products();
      this.applyFilter();
      await this.loadPoints();
    } catch (err) {
      this.products = [];
      this.shown = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private applyFilter(): void {
    if (this.catId.length === 0) {
      this.shown = this.products;
      return;
    }
    const list: MallProduct[] = [];
    for (let i = 0; i < this.products.length; i++) {
      if (mallStr(this.products[i].categoryId) === this.catId) {
        list.push(this.products[i]);
      }
    }
    this.shown = list;
  }

  private selectCat(id: string): void {
    this.catId = id;
    this.applyFilter();
  }

  private emptyText(): string {
    if (this.catId.length > 0) {
      return I18n.t('mall_cat_empty', this.lang);
    }
    return I18n.t('mall_empty', this.lang);
  }

  private async loadPoints(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      return;
    }
    try {
      await PointsRepository.getInstance().me();
    } catch (_e) {
    }
  }

  private openProduct(item: MallProduct): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/mall/MallProductPage',
      params: { 'productId': id }
    });
  }

  private openOrders(): void {
    LoginGate.ensure(I18n.t('mall_orders', this.lang), () => {
      router.pushUrl({ url: 'pages/mall/MallOrdersPage' });
    });
  }

  private openAddress(): void {
    LoginGate.ensure(I18n.t('mall_address', this.lang), () => {
      router.pushUrl({ url: 'pages/mall/MallAddressPage' });
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('mall_title', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(I18n.t('mall_orders', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.openOrders();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Row() {
        Text(I18n.tf('mall_points', `${this.userPoints}`, this.lang))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .layoutWeight(1)
        Text(I18n.t('mall_address', this.lang))
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.openAddress();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.categories.length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            Text(I18n.t('mall_cat_all', this.lang))
              .fontSize(13)
              .fontColor(this.catId.length === 0 ? '#FFFFFF' : '#4B5563')
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.catId.length === 0 ? '#2563EB' : '#F3F4F6')
              .onClick(() => this.selectCat(''))
            ForEach(this.categories, (item: MallCategory) => {
              Text(mallStr(item.name))
                .fontSize(13)
                .fontColor(this.catId === mallStr(item.id) ? '#FFFFFF' : '#4B5563')
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.catId === mallStr(item.id) ? '#2563EB' : '#F3F4F6')
                .onClick(() => this.selectCat(mallStr(item.id)))
            }, (item: MallCategory) => mallStr(item.id))
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .width('100%')
      }

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.shown.length === 0) {
        Column() {
          Text(this.emptyText()).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.shown, (item: MallProduct) => {
            ListItem() {
              Row({ space: 12 }) {
                if (mallStr(item.coverUrl).length > 0) {
                  Image(mallStr(item.coverUrl))
                    .width(72)
                    .height(72)
                    .borderRadius(10)
                    .objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    Text('🎁').fontSize(28)
                  }
                  .width(72)
                  .height(72)
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor('#F3F4F6')
                }
                Column({ space: 4 }) {
                  Text(mallStr(item.name))
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(mallStr(item.subtitle))
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 6 }) {
                    if (mallStr(item.categoryName).length > 0) {
                      Text(mallStr(item.categoryName))
                        .fontSize(11)
                        .fontColor('#1677FF')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor('#E8F3FF')
                        .borderRadius(4)
                    }
                    Text(mallGoodsLabel(item.goodsType))
                      .fontSize(11)
                      .fontColor('#6B7280')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .backgroundColor('#F3F4F6')
                      .borderRadius(4)
                    Text(mallProductPrice(item))
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#CF0A2C')
                    if (item.vipActive === true) {
                      Text(I18n.t('mall_vip_tag', this.lang))
                        .fontSize(10)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#D97706')
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .borderRadius(4)
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .onClick(() => {
                this.openProduct(item);
              })
            }
          }, (item: MallProduct) => mallStr(item.id))
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
