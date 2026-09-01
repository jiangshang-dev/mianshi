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
  lifetime: boolean;
  memberEnabled?: boolean;
  planCode: string;
  planName: string;
  expireTime?: number;
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

export interface IapVerifyBody {
  purchaseData: string;
  jwsPurchaseOrder: string;
  productId: string;
  source: string;
}
