import { Log, Pay } from '@cashier_alipay/cashiersdk';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

/**
 * 拉起支付宝收银台。必须在 UI 线程调用。
 */
export class AlipayPayService {
  static pay(orderStr: string): Promise<string> {
    Log.setupLogCallback((line: string) => {
      console.info('alipay_sdk ' + line);
    });
    const hasAppId = orderStr.indexOf('app_id=2021007105684003') >= 0;
    const hasMethod = orderStr.indexOf('alipay.trade.app.pay') >= 0;
    const hasSign = orderStr.indexOf('sign=') >= 0;
    const head = orderStr.substring(0, Math.min(180, orderStr.length));
    console.info('alipay_order len=' + orderStr.length
      + ' appId=' + (hasAppId ? '1' : '0')
      + ' method=' + (hasMethod ? '1' : '0')
      + ' sign=' + (hasSign ? '1' : '0')
      + ' head=' + head);
    hilog.info(DOMAIN, 'alipay', 'orderLen=%{public}d appId=%{public}s method=%{public}s sign=%{public}s',
      orderStr.length, hasAppId ? 'yes' : 'no', hasMethod ? 'yes' : 'no', hasSign ? 'yes' : 'no');
    const cashier = new Pay();
    return cashier.pay(orderStr, true).then((result: Map<string, string>) => {
      const status = result.get('resultStatus');
      const memo = result.get('memo');
      const raw = result.get('result');
      console.info('alipay_result status=' + status + ' memo=' + memo + ' result=' + raw);
      hilog.info(DOMAIN, 'alipay', 'pay status=%{public}s memo=%{public}s',
        status !== undefined ? status : '', memo !== undefined ? memo : '');
      return status !== undefined ? status : '';
    });
  }
}
