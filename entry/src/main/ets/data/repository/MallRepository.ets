import { HttpClient } from '../../common/network/HttpClient';
import {
  JeecgMallAddressListResp,
  JeecgMallAddressResp,
  JeecgMallMeResp,
  JeecgMallMsgResp,
  JeecgMallOrderPageResp,
  JeecgMallOrderResp,
  JeecgMallProductListResp,
  JeecgMallProductResp,
  MallAddress,
  MallAddressBody,
  MallCreateBody,
  MallMe,
  MallOrder,
  MallProduct,
  copyMallAddress,
  copyMallMe,
  copyMallOrder,
  copyMallProduct,
  mallNum,
  mallStr
} from '../../common/models/MallTypes';

export class MallRepository {
  private static instance: MallRepository | null = null;

  static getInstance(): MallRepository {
    if (!MallRepository.instance) {
      MallRepository.instance = new MallRepository();
    }
    return MallRepository.instance;
  }

  async products(): Promise<MallProduct[]> {
    const resp = await HttpClient.get('/api/mall/products', '');
    if (resp.body.length === 0) {
      throw new Error(this.parseMessage('', '商品加载失败'));
    }
    const parsed: JeecgMallProductListResp = JSON.parse(resp.body) as JeecgMallProductListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '商品加载失败');
    const list: MallProduct[] = [];
    const rawList = parsed.result;
    if (rawList !== undefined) {
      for (let i = 0; i < rawList.length; i++) {
        const item = copyMallProduct(rawList[i]);
        if (mallStr(item.id).length > 0) {
          list.push(item);
        }
      }
    }
    return list;
  }

  async product(id: string): Promise<MallProduct | null> {
    const resp = await HttpClient.get(`/api/mall/products/${id}`, '');
    if (resp.body.length === 0) {
      throw new Error('商品不存在');
    }
    const parsed: JeecgMallProductResp = JSON.parse(resp.body) as JeecgMallProductResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '商品不存在');
    return parsed.result !== undefined ? copyMallProduct(parsed.result) : null;
  }

  async me(): Promise<MallMe> {
    const resp = await HttpClient.get('/api/mall/me', '');
    if (resp.body.length === 0) {
      throw new Error('积分加载失败');
    }
    const parsed: JeecgMallMeResp = JSON.parse(resp.body) as JeecgMallMeResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '积分加载失败');
    const result = parsed.result;
    if (result !== undefined) {
      const me = copyMallMe(result);
      AppStorage.setOrCreate('userPoints', mallNum(me.points));
      return me;
    }
    const empty: MallMe = { points: 0, userId: 0 };
    return empty;
  }

  async addresses(): Promise<MallAddress[]> {
    const resp = await HttpClient.get('/api/mall/addresses', '');
    if (resp.body.length === 0) {
      throw new Error('地址加载失败');
    }
    const parsed: JeecgMallAddressListResp = JSON.parse(resp.body) as JeecgMallAddressListResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '地址加载失败');
    const list: MallAddress[] = [];
    const rawList = parsed.result;
    if (rawList !== undefined) {
      for (let i = 0; i < rawList.length; i++) {
        const item = copyMallAddress(rawList[i]);
        if (mallStr(item.id).length > 0) {
          list.push(item);
        }
      }
    }
    return list;
  }

  async saveAddress(body: MallAddressBody): Promise<MallAddress> {
    const payload: MallAddressBody = body;
    const resp = await HttpClient.postJson('/api/mall/addresses', JSON.stringify(payload));
    if (resp.body.length === 0) {
      throw new Error('保存地址失败');
    }
    const parsed: JeecgMallAddressResp = JSON.parse(resp.body) as JeecgMallAddressResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '保存地址失败');
    if (parsed.result === undefined) {
      throw new Error('保存地址失败');
    }
    return copyMallAddress(parsed.result);
  }

  async deleteAddress(id: string): Promise<void> {
    const resp = await HttpClient.postJson(`/api/mall/addresses/${id}/delete`, '{}');
    if (resp.body.length === 0) {
      if (!resp.ok) {
        throw new Error('删除失败');
      }
      return;
    }
    const parsed: JeecgMallMsgResp = JSON.parse(resp.body) as JeecgMallMsgResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '删除失败');
  }

  async createOrder(body: MallCreateBody): Promise<MallOrder> {
    const payload: MallCreateBody = body;
    const resp = await HttpClient.postJson('/api/mall/orders', JSON.stringify(payload));
    if (resp.body.length === 0) {
      throw new Error('下单失败');
    }
    const parsed: JeecgMallOrderResp = JSON.parse(resp.body) as JeecgMallOrderResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '下单失败');
    if (parsed.result === undefined) {
      throw new Error('下单失败');
    }
    return copyMallOrder(parsed.result);
  }

  async orders(): Promise<MallOrder[]> {
    const resp = await HttpClient.get('/api/mall/orders', 'pageNo=1&pageSize=50');
    if (resp.body.length === 0) {
      throw new Error('订单加载失败');
    }
    const parsed: JeecgMallOrderPageResp = JSON.parse(resp.body) as JeecgMallOrderPageResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '订单加载失败');
    const page = parsed.result;
    const list: MallOrder[] = [];
    if (page === undefined || page.records === undefined) {
      return list;
    }
    for (let i = 0; i < page.records.length; i++) {
      const item = copyMallOrder(page.records[i]);
      if (mallStr(item.id).length > 0) {
        list.push(item);
      }
    }
    return list;
  }

  async order(id: string): Promise<MallOrder | null> {
    const resp = await HttpClient.get(`/api/mall/orders/${id}`, '');
    if (resp.body.length === 0) {
      throw new Error('订单不存在');
    }
    const parsed: JeecgMallOrderResp = JSON.parse(resp.body) as JeecgMallOrderResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '订单不存在');
    return parsed.result !== undefined ? copyMallOrder(parsed.result) : null;
  }

  async cancel(id: string): Promise<MallOrder> {
    const resp = await HttpClient.postJson(`/api/mall/orders/${id}/cancel`, '{}');
    if (resp.body.length === 0) {
      throw new Error('取消失败');
    }
    const parsed: JeecgMallOrderResp = JSON.parse(resp.body) as JeecgMallOrderResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '取消失败');
    if (parsed.result === undefined) {
      throw new Error('取消失败');
    }
    return copyMallOrder(parsed.result);
  }

  async confirm(id: string): Promise<MallOrder> {
    const resp = await HttpClient.postJson(`/api/mall/orders/${id}/confirm`, '{}');
    if (resp.body.length === 0) {
      throw new Error('确认收货失败');
    }
    const parsed: JeecgMallOrderResp = JSON.parse(resp.body) as JeecgMallOrderResp;
    this.ensureOk(parsed.success, parsed.message, resp.ok, '确认收货失败');
    if (parsed.result === undefined) {
      throw new Error('确认收货失败');
    }
    return copyMallOrder(parsed.result);
  }

  private ensureOk(success: boolean | undefined, message: string | undefined, ok: boolean, fallback: string): void {
    if (success === false || !ok) {
      const text = mallStr(message);
      throw new Error(text.length > 0 ? text : fallback);
    }
  }

  private parseMessage(body: string, fallback: string): string {
    try {
      const parsed: JeecgMallMsgResp = JSON.parse(body) as JeecgMallMsgResp;
      const text = mallStr(parsed.message);
      if (text.length > 0) {
        return text;
      }
    } catch (_e) {
    }
    return fallback;
  }

  static pickAddressId(): string {
    const raw = AppStorage.get('mallSelectedAddressId') as string;
    return raw !== undefined ? raw : '';
  }

  static setPickAddressId(id: string): void {
    AppStorage.setOrCreate('mallSelectedAddressId', id);
  }
}
