import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { IapPurchaseData, IapPurchaseOrder, IapVerifyBody, MemberPlan } from '../models/MemberTypes';
import { JwsUtil } from './JwsUtil';
import { MemberRepository } from '../../data/repository/MemberRepository';

const DOMAIN = 0x1A0;
const ERR_ACCOUNT_NOT_LOGGED_IN: number = 1001860001;

export interface IapBuyResult {
  ok: boolean;
  message: string;
}

export class IapService {
  static productTypeOf(iapType: string): iap.ProductType {
    if (iapType === 'nonconsumable') {
      return iap.ProductType.NONCONSUMABLE;
    }
    return iap.ProductType.NONRENEWABLE;
  }

  static async queryEnv(context: common.UIAbilityContext): Promise<number> {
    try {
      await iap.queryEnvironmentStatus(context);
      return 0;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'IAP', 'queryEnv %{public}d %{public}s', e.code, e.message);
      return e.code;
    }
  }

  static async queryLocalPrice(context: common.UIAbilityContext, plans: MemberPlan[]): Promise<void> {
    try {
      const nonrenew: string[] = [];
      const noncons: string[] = [];
      for (let i = 0; i < plans.length; i++) {
        const plan = plans[i];
        if (plan.iapProductId.length === 0) {
          continue;
        }
        if (plan.iapType === 'nonconsumable') {
          noncons.push(plan.iapProductId);
        } else {
          nonrenew.push(plan.iapProductId);
        }
      }
      const prices: Map<string, string> = new Map();
      await IapService.fillPrices(context, iap.ProductType.NONRENEWABLE, nonrenew, prices);
      await IapService.fillPrices(context, iap.ProductType.NONCONSUMABLE, noncons, prices);
      for (let i = 0; i < plans.length; i++) {
        const hit = prices.get(plans[i].iapProductId);
        if (hit !== undefined) {
          plans[i].localPrice = hit;
        }
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'queryLocalPrice';
      hilog.warn(DOMAIN, 'IAP', 'queryLocalPrice %{public}s', msg);
    }
  }

  static async buy(context: common.UIAbilityContext, plan: MemberPlan): Promise<IapBuyResult> {
    const env = await IapService.queryEnv(context);
    if (env === ERR_ACCOUNT_NOT_LOGGED_IN) {
      return { ok: false, message: '请先在系统设置中登录华为账号' };
    }
    if (env !== 0) {
      return { ok: false, message: '当前设备暂不支持应用内购买' };
    }
    const param: iap.PurchaseParameter = {
      productId: plan.iapProductId,
      productType: IapService.productTypeOf(plan.iapType)
    };
    try {
      const result = await iap.createPurchase(context, param);
      return await IapService.deliver(context, result.purchaseData, 'iap');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'IAP', 'buy %{public}d %{public}s', e.code, e.message);
      if (e.code === iap.IAPErrorCode.PRODUCT_OWNED || e.code === iap.IAPErrorCode.SYSTEM_ERROR) {
        await IapService.restoreUnfinished(context);
        return { ok: true, message: '已尝试恢复未完成订单' };
      }
      return { ok: false, message: e.message.length > 0 ? e.message : '支付失败' };
    }
  }

  static async restoreUnfinished(context: common.UIAbilityContext): Promise<void> {
    try {
      await IapService.restoreType(context, iap.ProductType.NONRENEWABLE);
      await IapService.restoreType(context, iap.ProductType.NONCONSUMABLE);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'restoreUnfinished';
      hilog.warn(DOMAIN, 'IAP', 'restoreUnfinished %{public}s', msg);
    }
  }

  private static async restoreType(context: common.UIAbilityContext, productType: iap.ProductType): Promise<void> {
    const param: iap.QueryPurchasesParameter = {
      productType: productType,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };
    try {
      const res: iap.QueryPurchaseResult = await iap.queryPurchases(context, param);
      const list: string[] = res.purchaseDataList;
      if (list === undefined || list.length === 0) {
        return;
      }
      for (let i = 0; i < list.length; i++) {
        await IapService.deliver(context, list[i], 'restore');
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, 'IAP', 'restore %{public}d %{public}s', e.code, e.message);
    }
  }

  private static async deliver(context: common.UIAbilityContext, purchaseData: string,
    source: string): Promise<IapBuyResult> {
    try {
      const parsed: IapPurchaseData = JSON.parse(purchaseData) as IapPurchaseData;
      const jws = parsed.jwsPurchaseOrder !== undefined ? parsed.jwsPurchaseOrder : '';
      if (jws.length === 0) {
        return { ok: false, message: '购买凭证为空' };
      }
      const payloadText = JwsUtil.decodePayload(jws);
      const order: IapPurchaseOrder = JSON.parse(payloadText) as IapPurchaseOrder;
      const body: IapVerifyBody = {
        purchaseData: purchaseData,
        jwsPurchaseOrder: jws,
        productId: order.productId,
        source: source
      };
      await MemberRepository.getInstance().verify(body);
      if (order.finishStatus !== '1') {
        const finish: iap.FinishPurchaseParameter = {
          productType: Number(order.productType),
          purchaseToken: order.purchaseToken,
          purchaseOrderId: order.purchaseOrderId
        };
        await iap.finishPurchase(context, finish);
      }
      return { ok: true, message: '开通成功' };
    } catch (err) {
      const msg = err instanceof Error ? err.message : '发货失败';
      hilog.error(DOMAIN, 'IAP', 'deliver %{public}s', msg);
      return { ok: false, message: msg };
    }
  }

  private static async fillPrices(context: common.UIAbilityContext, type: iap.ProductType,
    ids: string[], prices: Map<string, string>): Promise<void> {
    if (ids.length === 0) {
      return;
    }
    const param: iap.QueryProductsParameter = {
      productType: type,
      productIds: ids
    };
    try {
      const products: iap.Product[] = await iap.queryProducts(context, param);
      for (let i = 0; i < products.length; i++) {
        const p = products[i];
        if (p.localPrice !== undefined && p.localPrice.length > 0) {
          prices.set(p.id, p.localPrice);
        }
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.warn(DOMAIN, 'IAP', 'queryProducts %{public}d %{public}s', e.code, e.message);
    }
  }
}
