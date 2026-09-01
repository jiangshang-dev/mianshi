export interface MallProduct {
  id?: string;
  name?: string;
  subtitle?: string;
  coverUrl?: string;
  images?: string;
  detail?: string;
  goodsType?: string;
  payType?: string;
  pointsPrice?: number;
  priceFen?: number;
  originalPriceFen?: number;
  freightFen?: number;
  stock?: number;
  soldCount?: number;
  virtualHint?: string;
  status?: number;
  memberDays?: number;
}

export interface MallAddress {
  id?: string;
  userId?: number;
  receiverName?: string;
  receiverPhone?: string;
  province?: string;
  city?: string;
  district?: string;
  detail?: string;
  isDefault?: number;
}

export interface MallOrder {
  id?: string;
  orderNo?: string;
  userId?: number;
  productId?: string;
  productName?: string;
  coverUrl?: string;
  goodsType?: string;
  payType?: string;
  quantity?: number;
  pointsCost?: number;
  amountFen?: number;
  freightFen?: number;
  payAmountFen?: number;
  status?: string;
  payChannel?: string;
  receiverName?: string;
  receiverPhone?: string;
  receiverRegion?: string;
  receiverDetail?: string;
  logisticsCompany?: string;
  logisticsNo?: string;
  paidTime?: string;
  shipTime?: string;
  receiveTime?: string;
  cancelTime?: string;
  buyerRemark?: string;
  adminRemark?: string;
  createTime?: string;
  panUrl?: string;
  panCode?: string;
}

export interface MallMe {
  points?: number;
  userId?: number;
}

export interface JeecgMallMsgResp {
  success?: boolean;
  message?: string;
  code?: number;
}

export interface JeecgMallProductListResp {
  success?: boolean;
  message?: string;
  result?: MallProduct[];
  code?: number;
}

export interface JeecgMallProductResp {
  success?: boolean;
  message?: string;
  result?: MallProduct;
  code?: number;
}

export interface JeecgMallAddressListResp {
  success?: boolean;
  message?: string;
  result?: MallAddress[];
  code?: number;
}

export interface JeecgMallAddressResp {
  success?: boolean;
  message?: string;
  result?: MallAddress;
  code?: number;
}

export interface JeecgMallMeResp {
  success?: boolean;
  message?: string;
  result?: MallMe;
  code?: number;
}

export interface MallOrderPage {
  records?: MallOrder[];
  total?: number;
}

export interface JeecgMallOrderPageResp {
  success?: boolean;
  message?: string;
  result?: MallOrderPage;
  code?: number;
}

export interface JeecgMallOrderResp {
  success?: boolean;
  message?: string;
  result?: MallOrder;
  code?: number;
}

export interface MallCreateBody {
  productId: string;
  quantity: number;
  addressId: string;
  remark: string;
  payType: string;
}

export interface MallAddressBody {
  id: string;
  receiverName: string;
  receiverPhone: string;
  province: string;
  city: string;
  district: string;
  detail: string;
  isDefault: number;
}

export function mallStr(value?: string): string {
  if (value === undefined) {
    return '';
  }
  try {
    return value.length > 0 ? value : '';
  } catch (_e) {
    return '';
  }
}

export function mallNum(value?: number, fallback: number = 0): number {
  if (value === undefined) {
    return fallback;
  }
  try {
    if (value + 0 === value) {
      return value;
    }
  } catch (_e) {
  }
  return fallback;
}

export function mallFenText(fen?: number): string {
  const v = mallNum(fen);
  return `¥${(v / 100).toFixed(2)}`;
}

export function copyMallProduct(raw: MallProduct): MallProduct {
  try {
    const item: MallProduct = {
      id: mallStr(raw.id),
      name: mallStr(raw.name),
      subtitle: mallStr(raw.subtitle),
      coverUrl: mallStr(raw.coverUrl),
      images: mallStr(raw.images),
      detail: mallStr(raw.detail),
      goodsType: mallStr(raw.goodsType),
      payType: mallStr(raw.payType),
      pointsPrice: mallNum(raw.pointsPrice),
      priceFen: mallNum(raw.priceFen),
      originalPriceFen: mallNum(raw.originalPriceFen),
      freightFen: mallNum(raw.freightFen),
      stock: mallNum(raw.stock, -1),
      soldCount: mallNum(raw.soldCount),
      virtualHint: mallStr(raw.virtualHint),
      status: mallNum(raw.status, 1),
      memberDays: mallNum(raw.memberDays)
    };
    return item;
  } catch (_e) {
    const empty: MallProduct = { id: '', name: '' };
    return empty;
  }
}

export function copyMallAddress(raw: MallAddress): MallAddress {
  try {
    const item: MallAddress = {
      id: mallStr(raw.id),
      userId: mallNum(raw.userId),
      receiverName: mallStr(raw.receiverName),
      receiverPhone: mallStr(raw.receiverPhone),
      province: mallStr(raw.province),
      city: mallStr(raw.city),
      district: mallStr(raw.district),
      detail: mallStr(raw.detail),
      isDefault: mallNum(raw.isDefault)
    };
    return item;
  } catch (_e) {
    const empty: MallAddress = { id: '' };
    return empty;
  }
}

export function copyMallOrder(raw: MallOrder): MallOrder {
  try {
    const item: MallOrder = {
      id: mallStr(raw.id),
      orderNo: mallStr(raw.orderNo),
      userId: mallNum(raw.userId),
      productId: mallStr(raw.productId),
      productName: mallStr(raw.productName),
      coverUrl: mallStr(raw.coverUrl),
      goodsType: mallStr(raw.goodsType),
      payType: mallStr(raw.payType),
      quantity: mallNum(raw.quantity, 1),
      pointsCost: mallNum(raw.pointsCost),
      amountFen: mallNum(raw.amountFen),
      freightFen: mallNum(raw.freightFen),
      payAmountFen: mallNum(raw.payAmountFen),
      status: mallStr(raw.status),
      payChannel: mallStr(raw.payChannel),
      receiverName: mallStr(raw.receiverName),
      receiverPhone: mallStr(raw.receiverPhone),
      receiverRegion: mallStr(raw.receiverRegion),
      receiverDetail: mallStr(raw.receiverDetail),
      logisticsCompany: mallStr(raw.logisticsCompany),
      logisticsNo: mallStr(raw.logisticsNo),
      paidTime: mallStr(raw.paidTime),
      shipTime: mallStr(raw.shipTime),
      receiveTime: mallStr(raw.receiveTime),
      cancelTime: mallStr(raw.cancelTime),
      buyerRemark: mallStr(raw.buyerRemark),
      adminRemark: mallStr(raw.adminRemark),
      createTime: mallStr(raw.createTime),
      panUrl: mallStr(raw.panUrl),
      panCode: mallStr(raw.panCode)
    };
    return item;
  } catch (_e) {
    const empty: MallOrder = { id: '' };
    return empty;
  }
}

export function copyMallMe(raw: MallMe): MallMe {
  try {
    const item: MallMe = {
      points: mallNum(raw.points),
      userId: mallNum(raw.userId)
    };
    return item;
  } catch (_e) {
    const empty: MallMe = { points: 0, userId: 0 };
    return empty;
  }
}

export function mallProductPrice(product: MallProduct): string {
  const pay = mallStr(product.payType);
  if (pay === 'both') {
    return `${mallNum(product.pointsPrice)}积分 / ${mallFenText(product.priceFen)}`;
  }
  if (pay === 'cash') {
    return mallFenText(product.priceFen);
  }
  return `${mallNum(product.pointsPrice)}积分`;
}

export function mallGoodsLabel(goodsType?: string): string {
  const type = mallStr(goodsType);
  if (type === 'physical') {
    return '实物';
  }
  if (type === 'pan') {
    return '网盘';
  }
  return '虚拟';
}

export function mallPayLabel(payType?: string): string {
  const pay = mallStr(payType);
  if (pay === 'cash') {
    return '现金';
  }
  if (pay === 'both') {
    return '积分/现金';
  }
  return '积分';
}

export function mallStatusLabel(status?: string): string {
  if (status === 'pending_pay') {
    return '待支付';
  }
  if (status === 'paid') {
    return '待发货';
  }
  if (status === 'shipped') {
    return '已发货';
  }
  if (status === 'received') {
    return '已完成';
  }
  if (status === 'cancelled') {
    return '已取消';
  }
  return mallStr(status);
}

export function mallAddressLine(addr: MallAddress): string {
  return `${mallStr(addr.province)}${mallStr(addr.city)}${mallStr(addr.district)}${mallStr(addr.detail)}`;
}
