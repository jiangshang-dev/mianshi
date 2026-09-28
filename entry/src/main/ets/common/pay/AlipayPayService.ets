import { Pay } from '@cashier_alipay/cashiersdk';

/**
 * 拉起支付宝收银台。必须在 UI 线程调用。
 */
export class AlipayPayService {
  static pay(orderStr: string): Promise<string> {
    const cashier = new Pay();
    return cashier.pay(orderStr, true).then((result: Map<string, string>) => {
      const status = result.get('resultStatus');
      return status !== undefined ? status : '';
    });
  }
}
