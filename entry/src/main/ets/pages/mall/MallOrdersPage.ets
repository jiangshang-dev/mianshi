import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { IapService } from '../../common/utils/IapService';
import {
  MallOrder,
  mallFenText,
  mallNum,
  mallStatusLabel,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';

@Entry
@Component
struct MallOrdersPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private items: MallOrder[] = [];
  private repo: MallRepository = MallRepository.getInstance();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private hostContext(): common.UIAbilityContext {
    const host = this.getUIContext().getHostContext();
    if (host) {
      return host as common.UIAbilityContext;
    }
    return getContext(this) as common.UIAbilityContext;
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      await IapService.restoreUnfinished(this.hostContext());
      this.items = await this.repo.orders();
    } catch (err) {
      this.items = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private payText(item: MallOrder): string {
    if (item.payType === 'cash') {
      return mallFenText(item.payAmountFen);
    }
    return `${mallNum(item.pointsCost)}积分`;
  }

  private open(item: MallOrder): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/mall/MallOrderDetailPage',
      params: { 'orderId': id }
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('mall_orders', this.lang))
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
      } else if (this.items.length === 0) {
        Column() {
          Text(I18n.t('mall_order_empty', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.items, (item: MallOrder) => {
            ListItem() {
              Column({ space: 6 }) {
                Row() {
                  Text(mallStr(item.orderNo))
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .layoutWeight(1)
                  Text(mallStatusLabel(item.status))
                    .fontSize(13)
                    .fontColor(item.status === 'cancelled' ? '#9CA3AF' : '#CF0A2C')
                }
                .width('100%')
                Text(mallStr(item.productName))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Row() {
                  Text(`x${mallNum(item.quantity, 1)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_muted'))
                    .layoutWeight(1)
                  Text(this.payText(item))
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#CF0A2C')
                }
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .onClick(() => {
                this.open(item);
              })
            }
          }, (item: MallOrder) => mallStr(item.id))
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
