import { AlipayPayService } from './AlipayPayService';

/**
 * 会员支付渠道入口。当前只接支付宝；微信、华为以后在这里加分支。
 */
export class PayCheckout {
  static readonly ALIPAY: string = 'alipay';
  static readonly WECHAT: string = 'wechat';
  static readonly HUAWEI: string = 'huawei';

  static start(channel: string, orderStr: string): Promise<string> {
    if (channel === PayCheckout.ALIPAY) {
      return AlipayPayService.pay(orderStr);
    }
    if (channel === PayCheckout.WECHAT) {
      return Promise.reject(new Error('微信支付尚未开通'));
    }
    if (channel === PayCheckout.HUAWEI) {
      return Promise.reject(new Error('华为支付尚未开通'));
    }
    return Promise.reject(new Error('不支持的支付渠道'));
  }
}
