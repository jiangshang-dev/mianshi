export interface MemberQuota {
  scene: string;
  periodKey: string;
  used: number;
  limit: number;
  remain: number;
  unlimited: boolean;
  member: boolean;
}

export interface MemberPlan {
  id: string;
  code: string;
  name: string;
  subtitle: string;
  durationDays: number;
  priceFen: number;
  originalPriceFen: number;
  iapProductId: string;
  iapType: string;
  localPrice?: string;
}

export interface MemberMe {
  member: boolean;
  /** 曾经付费开通过。未返回时按未付费处理。 */
  paidMember?: boolean;
  lifetime: boolean;
  memberEnabled?: boolean;
  planCode: string;
  planName: string;
  /** 后端 Long，JSON 可能是 number 或 string */
  expireTime?: number | string;
  questionAi: MemberQuota | null;
  interviewAi: MemberQuota | null;
  plans: MemberPlan[];
}

export interface JeecgMemberMeResp {
  success?: boolean;
  message?: string;
  result?: MemberMe;
  code?: number;
}

export interface JeecgMemberPlanListResp {
  success?: boolean;
  message?: string;
  result?: MemberPlan[];
  code?: number;
}

export interface IapPurchaseData {
  type?: number;
  jwsPurchaseOrder?: string;
}

export interface IapPurchaseOrder {
  productId: string;
  productType: string;
  purchaseOrderId: string;
  purchaseToken: string;
  finishStatus?: string;
}

export interface AppPayPrepare {
  orderId: string;
  orderNo: string;
  channel: string;
  status: string;
  orderStr?: string;
}

export interface JeecgAppPayResp {
  success?: boolean;
  message?: string;
  result?: AppPayPrepare;
  code?: number;
}

export interface AppPayOrderStatus {
  orderId: string;
  status: string;
}

export interface JeecgAppPayOrderResp {
  success?: boolean;
  message?: string;
  result?: AppPayOrderStatus;
  code?: number;
}

export interface IapVerifyBody {
  purchaseData: string;
  jwsPurchaseOrder: string;
  productId: string;
  source: string;
}
