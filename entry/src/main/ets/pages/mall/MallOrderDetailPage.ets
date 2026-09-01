import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import {
  MallOrder,
  mallFenText,
  mallGoodsLabel,
  mallNum,
  mallPayLabel,
  mallStatusLabel,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';

interface MallOrderNav {
  orderId?: string;
}

interface DialogResult {
  index: number;
}

@Entry
@Component
struct MallOrderDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private acting: boolean = false;
  @State private order: MallOrder | null = null;
  private repo: MallRepository = MallRepository.getInstance();
  private orderId: string = '';

  aboutToAppear(): void {
    const nav = router.getParams() as MallOrderNav;
    this.orderId = nav !== undefined && nav.orderId !== undefined ? nav.orderId : '';
    this.reload();
  }

  private async reload(): Promise<void> {
    if (this.orderId.length === 0) {
      this.loading = false;
      return;
    }
    this.loading = true;
    try {
      this.order = await this.repo.order(this.orderId);
    } catch (err) {
      this.order = null;
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private payText(): string {
    const o = this.order;
    if (o === null) {
      return '';
    }
    if (o.payType === 'cash') {
      return mallFenText(o.payAmountFen);
    }
    return `${mallNum(o.pointsCost)}积分`;
  }

  private orderStatus(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.status);
  }

  private orderProductName(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.productName);
  }

  private orderNo(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.orderNo);
  }

  private orderQty(): string {
    const o = this.order;
    return `${mallNum(o === null ? undefined : o.quantity, 1)}`;
  }

  private orderGoods(): string {
    const o = this.order;
    return o === null ? '' : mallGoodsLabel(o.goodsType);
  }

  private orderPay(): string {
    const o = this.order;
    return o === null ? '' : mallPayLabel(o.payType);
  }

  private orderTime(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.createTime);
  }

  private isPhysicalOrder(): boolean {
    const o = this.order;
    return o !== null && o.goodsType === 'physical';
  }

  private orderReceiver(): string {
    const o = this.order;
    return o === null ? '' : `${mallStr(o.receiverName)}  ${mallStr(o.receiverPhone)}`;
  }

  private orderAddr(): string {
    const o = this.order;
    return o === null ? '' : `${mallStr(o.receiverRegion)}${mallStr(o.receiverDetail)}`;
  }

  private orderLogistics(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.logisticsCompany);
  }

  private orderLogisticsNo(): string {
    const o = this.order;
    return o === null ? '' : mallStr(o.logisticsNo);
  }

  private canCancel(): boolean {
    const o = this.order;
    if (o === null) {
      return false;
    }
    return o.status === 'pending_pay' || o.status === 'paid';
  }

  private canConfirm(): boolean {
    return this.order !== null && this.order.status === 'shipped';
  }

  private askCancel(): void {
    promptAction.showDialog({
      title: I18n.t('mall_cancel', this.lang),
      message: I18n.t('mall_cancel_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('mall_cancel', this.lang), color: '#DC2626' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        this.doCancel();
      }
    }).catch(() => {
    });
  }

  private askConfirm(): void {
    promptAction.showDialog({
      title: I18n.t('mall_confirm_recv', this.lang),
      message: I18n.t('mall_confirm_recv_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('mall_confirm_recv', this.lang), color: '#2563EB' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        this.doConfirm();
      }
    }).catch(() => {
    });
  }

  private async doCancel(): Promise<void> {
    if (this.acting) {
      return;
    }
    this.acting = true;
    try {
      this.order = await this.repo.cancel(this.orderId);
      promptAction.showToast({ message: I18n.t('mall_cancelled', this.lang) });
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_order_fail', this.lang) });
    } finally {
      this.acting = false;
    }
  }

  private async doConfirm(): Promise<void> {
    if (this.acting) {
      return;
    }
    this.acting = true;
    try {
      this.order = await this.repo.confirm(this.orderId);
      promptAction.showToast({ message: I18n.t('mall_received', this.lang) });
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_order_fail', this.lang) });
    } finally {
      this.acting = false;
    }
  }

  @Builder
  kv(label: string, value: string) {
    if (value.length > 0) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width(88)
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('mall_order_detail', this.lang))
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
      } else if (this.order === null) {
        Column() {
          Text(I18n.t('mall_order_gone', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 8 }) {
              Text(mallStatusLabel(this.orderStatus()))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#CF0A2C')
                .width('100%')
              if (this.orderStatus() === 'pending_pay') {
                Text(I18n.t('mall_cash_hint', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .width('100%')
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)

            Column({ space: 8 }) {
              Text(this.orderProductName())
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              this.kv(I18n.t('mall_order_no', this.lang), this.orderNo())
              this.kv(I18n.t('mall_qty', this.lang), this.orderQty())
              this.kv(I18n.t('mall_goods_type', this.lang), this.orderGoods())
              this.kv(I18n.t('mall_pay_type', this.lang), this.orderPay())
              this.kv(I18n.t('mall_pay_amount', this.lang), this.payText())
              this.kv(I18n.t('mall_time', this.lang), this.orderTime())
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)

            if (this.isPhysicalOrder()) {
              Column({ space: 8 }) {
                Text(I18n.t('mall_address', this.lang))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                this.kv(I18n.t('mall_recv_name', this.lang), this.orderReceiver())
                this.kv(I18n.t('mall_detail_addr', this.lang), this.orderAddr())
                this.kv(I18n.t('mall_logistics', this.lang), this.orderLogistics())
                this.kv(I18n.t('mall_logistics_no', this.lang), this.orderLogisticsNo())
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
            }
          }
          .padding({ left: 16, right: 16, bottom: 16 })
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)

        if (this.canCancel() || this.canConfirm()) {
          Row({ space: 10 }) {
            if (this.canCancel()) {
              Button(I18n.t('mall_cancel', this.lang))
                .layoutWeight(1)
                .height(42)
                .backgroundColor('#FEF2F2')
                .fontColor('#DC2626')
                .enabled(!this.acting)
                .onClick(() => {
                  this.askCancel();
                })
            }
            if (this.canConfirm()) {
              Button(I18n.t('mall_confirm_recv', this.lang))
                .layoutWeight(1)
                .height(42)
                .backgroundColor('#CF0A2C')
                .enabled(!this.acting)
                .onClick(() => {
                  this.askConfirm();
                })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
