import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import {
  MallAddress,
  MallCreateBody,
  MallProduct,
  mallAddressLine,
  mallFenText,
  mallNum,
  mallProductPrice,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';

interface MallConfirmNav {
  productId?: string;
}

@Entry
@Component
struct MallConfirmPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private submitting: boolean = false;
  @State private product: MallProduct | null = null;
  @State private addresses: MallAddress[] = [];
  @State private selectedId: string = '';
  @State private quantity: number = 1;
  @State private remark: string = '';
  @State private points: number = 0;
  private repo: MallRepository = MallRepository.getInstance();
  private productId: string = '';

  aboutToAppear(): void {
    const nav = router.getParams() as MallConfirmNav;
    this.productId = nav !== undefined && nav.productId !== undefined ? nav.productId : '';
    this.reload();
  }

  onPageShow(): void {
    this.loadAddresses();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      this.product = await this.repo.product(this.productId);
      const me = await this.repo.me();
      this.points = mallNum(me.points);
      await this.loadAddresses();
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private async loadAddresses(): Promise<void> {
    try {
      this.addresses = await this.repo.addresses();
    } catch (_e) {
      this.addresses = [];
    }
    const picked = MallRepository.pickAddressId();
    if (picked.length > 0 && this.hasAddress(picked)) {
      this.selectedId = picked;
      return;
    }
    if (this.selectedId.length > 0 && this.hasAddress(this.selectedId)) {
      return;
    }
    let defId = '';
    for (let i = 0; i < this.addresses.length; i++) {
      if (this.addresses[i].isDefault === 1) {
        defId = mallStr(this.addresses[i].id);
        break;
      }
    }
    if (defId.length === 0 && this.addresses.length > 0) {
      defId = mallStr(this.addresses[0].id);
    }
    this.selectedId = defId;
  }

  private hasAddress(id: string): boolean {
    for (let i = 0; i < this.addresses.length; i++) {
      if (mallStr(this.addresses[i].id) === id) {
        return true;
      }
    }
    return false;
  }

  private selectedAddress(): MallAddress | null {
    for (let i = 0; i < this.addresses.length; i++) {
      if (mallStr(this.addresses[i].id) === this.selectedId) {
        return this.addresses[i];
      }
    }
    return null;
  }

  private selectedName(): string {
    const addr = this.selectedAddress();
    return addr === null ? '' : mallStr(addr.receiverName);
  }

  private selectedPhone(): string {
    const addr = this.selectedAddress();
    return addr === null ? '' : mallStr(addr.receiverPhone);
  }

  private selectedLine(): string {
    const addr = this.selectedAddress();
    return addr === null ? '' : mallAddressLine(addr);
  }

  private productName(): string {
    const p = this.product;
    return p === null ? '' : mallStr(p.name);
  }

  private productPrice(): string {
    const p = this.product;
    return p === null ? '' : mallProductPrice(p);
  }

  private isPhysical(): boolean {
    return this.product !== null && this.product.goodsType === 'physical';
  }

  private isCash(): boolean {
    return this.product !== null && this.product.payType === 'cash';
  }

  private changeQty(delta: number): void {
    const next = this.quantity + delta;
    if (next < 1) {
      return;
    }
    const stock = this.product !== null ? mallNum(this.product.stock, -1) : -1;
    if (stock >= 0 && next > stock) {
      promptAction.showToast({ message: I18n.t('mall_stock_short', this.lang) });
      return;
    }
    this.quantity = next;
  }

  private payText(): string {
    const p = this.product;
    if (p === null) {
      return '';
    }
    if (this.isCash()) {
      const goods = mallNum(p.priceFen) * this.quantity;
      const freight = this.isPhysical() ? mallNum(p.freightFen) : 0;
      return mallFenText(goods + freight);
    }
    return `${mallNum(p.pointsPrice) * this.quantity}积分`;
  }

  private goAddress(): void {
    router.pushUrl({
      url: 'pages/mall/MallAddressPage',
      params: { 'pick': '1' }
    });
  }

  private async submit(): Promise<void> {
    if (this.submitting || this.product === null) {
      return;
    }
    if (this.isPhysical() && this.selectedId.length === 0) {
      promptAction.showToast({ message: I18n.t('mall_need_addr', this.lang) });
      return;
    }
    this.submitting = true;
    try {
      const body: MallCreateBody = {
        productId: this.productId,
        quantity: this.quantity,
        addressId: this.selectedId,
        remark: this.remark.trim()
      };
      const order = await this.repo.createOrder(body);
      const oid = mallStr(order.id);
      promptAction.showToast({
        message: this.isCash() ? I18n.t('mall_wait_pay', this.lang) : I18n.t('mall_order_ok', this.lang)
      });
      if (oid.length > 0) {
        router.pushUrl({
          url: 'pages/mall/MallOrderDetailPage',
          params: { 'orderId': oid }
        });
      }
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_order_fail', this.lang) });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('mall_confirm', this.lang))
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
            if (this.isPhysical()) {
              Column({ space: 6 }) {
                Row() {
                  Text(I18n.t('mall_address', this.lang))
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(I18n.t('mall_manage_addr', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.accent'))
                    .onClick(() => {
                      this.goAddress();
                    })
                }
                .width('100%')
                if (this.selectedId.length === 0) {
                  Text(I18n.t('mall_need_addr', this.lang))
                    .fontSize(13)
                    .fontColor('#DC2626')
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                    .onClick(() => {
                      this.goAddress();
                    })
                } else {
                  Text(`${this.selectedName()}  ${this.selectedPhone()}`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')
                  Text(this.selectedLine())
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .width('100%')
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
            }

            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(this.productName())
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text(this.productPrice())
                  .fontSize(13)
                  .fontColor('#CF0A2C')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Row({ space: 10 }) {
                Text('-')
                  .fontSize(18)
                  .fontColor($r('app.color.text_primary'))
                  .onClick(() => {
                    this.changeQty(-1);
                  })
                Text(`${this.quantity}`).fontSize(15).fontColor($r('app.color.text_primary'))
                Text('+')
                  .fontSize(18)
                  .fontColor($r('app.color.text_primary'))
                  .onClick(() => {
                    this.changeQty(1);
                  })
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)

            Column({ space: 6 }) {
              Text(I18n.t('mall_remark', this.lang)).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
              TextInput({ text: this.remark, placeholder: I18n.t('mall_remark_ph', this.lang) })
                .height(44)
                .backgroundColor($r('app.color.page_bg'))
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_muted'))
                .onChange((v: string) => {
                  this.remark = v;
                })
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)

            if (!this.isCash()) {
              Text(I18n.tf('mall_points', `${this.points}`, this.lang))
                .fontSize(13)
                .fontColor($r('app.color.text_muted'))
                .width('100%')
            } else {
              Text(I18n.t('mall_cash_hint', this.lang))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .width('100%')
            }
          }
          .padding({ left: 16, right: 16, bottom: 16 })
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)

        Row() {
          Text(this.payText())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#CF0A2C')
            .layoutWeight(1)
          Button(this.submitting ? I18n.t('mall_submitting', this.lang) : I18n.t('mall_submit', this.lang))
            .height(42)
            .width(140)
            .backgroundColor('#CF0A2C')
            .enabled(!this.submitting)
            .onClick(() => {
              this.submit();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16, top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
