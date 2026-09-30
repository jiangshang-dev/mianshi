import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { MemberMe, MemberPlan, MemberQuota } from '../../common/models/MemberTypes';
import { PayCheckout } from '../../common/pay/PayCheckout';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { MemberRepository } from '../../data/repository/MemberRepository';
import { MemberBadge } from '../../components/MemberBadge';

@Entry
@Component
struct MemberPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('memberEnabled') memberEnabled: boolean = true;
  @StorageLink('isMember') isMember: boolean = false;
  @StorageLink('isLifetimeMember') isLifetime: boolean = false;
  @StorageLink('memberPlanName') cachedPlanName: string = '';
  @StorageLink('memberExpireTime') cachedExpire: number = 0;
  @State private plansLoading: boolean = true;
  @State private buying: boolean = false;
  @State private me: MemberMe | null = null;
  @State private plans: MemberPlan[] = [];
  @State private hint: string = '';
  @State private paySheetOpen: boolean = false;
  @State private pendingPlan: MemberPlan | null = null;
  private repo: MemberRepository = MemberRepository.getInstance();

  aboutToAppear(): void {
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      this.plansLoading = false;
      LoginGate.ensure(I18n.t('member_title', this.lang), () => {
        this.bootstrap();
      });
      return;
    }
    const firstOpen = this.plans.length === 0;
    if (firstOpen) {
      this.plansLoading = true;
    }
    try {
      const snapshot = await this.repo.me();
      this.me = snapshot;
      this.plans = snapshot !== null && snapshot.plans.length > 0 ? snapshot.plans : await this.repo.plans();
      this.hint = '';
    } catch (err) {
      this.hint = err instanceof Error ? err.message : I18n.t('member_load_fail', this.lang);
    } finally {
      this.plansLoading = false;
    }
  }

  private openPaySheet(plan: MemberPlan): void {
    if (this.buying || !this.memberEnabled) {
      return;
    }
    this.pendingPlan = plan;
    this.paySheetOpen = true;
  }

  private confirmAlipay(): void {
    const plan = this.pendingPlan;
    this.paySheetOpen = false;
    if (plan === null) {
      return;
    }
    this.buy(plan);
  }

  private async buy(plan: MemberPlan): Promise<void> {
    if (this.buying || !this.memberEnabled) {
      return;
    }
    this.buying = true;
    try {
      const prepared = await this.repo.createAppOrder(plan.id, PayCheckout.ALIPAY);
      const orderStr = prepared.orderStr !== undefined ? prepared.orderStr : '';
      console.info('alipay_orderNo=' + prepared.orderNo);
      if (orderStr.length === 0) {
        promptAction.showToast({ message: I18n.t('member_pay_fail', this.lang) });
        return;
      }
      const status = await this.launchAlipay(orderStr);
      if (status === '9000') {
        const synced = await this.repo.syncAppOrder(prepared.orderId);
        promptAction.showToast({
          message: synced !== null && synced.status === 'paid'
            ? I18n.t('member_pay_ok', this.lang)
            : I18n.t('member_pay_pending', this.lang)
        });
        await this.bootstrap();
      } else if (status === '8000') {
        promptAction.showToast({ message: I18n.t('member_pay_pending', this.lang) });
      } else if (status === '6001') {
        promptAction.showToast({ message: I18n.t('member_pay_cancel', this.lang) });
      } else {
        promptAction.showToast({ message: I18n.t('member_pay_fail', this.lang) });
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : I18n.t('member_pay_fail', this.lang);
      promptAction.showToast({ message: message });
    } finally {
      this.buying = false;
    }
  }

  private launchAlipay(orderStr: string): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      this.getUIContext().runScopedTask(() => {
        PayCheckout.start(PayCheckout.ALIPAY, orderStr).then((status: string) => {
          resolve(status);
        }).catch((err: Error) => {
          reject(err);
        });
      });
    });
  }

  private actionLabel(): string {
    if (this.buying) {
      return I18n.t('member_buying', this.lang);
    }
    const snap = this.me;
    if (snap !== null && snap.paidMember === true) {
      return I18n.t('member_renew', this.lang);
    }
    if (snap !== null && snap.member) {
      return I18n.t('member_upgrade', this.lang);
    }
    return I18n.t('member_buy', this.lang);
  }

  private priceText(plan: MemberPlan): string {
    if (plan.localPrice !== undefined && plan.localPrice.length > 0) {
      return plan.localPrice;
    }
    const fen = plan.priceFen !== undefined ? plan.priceFen : 0;
    return `¥${(fen / 100).toFixed(2)}`;
  }

  private originText(plan: MemberPlan): string {
    if (plan.originalPriceFen === undefined || plan.originalPriceFen <= plan.priceFen) {
      return '';
    }
    return `¥${(plan.originalPriceFen / 100).toFixed(2)}`;
  }

  private isHot(plan: MemberPlan): boolean {
    return plan.code === 'member_year' || plan.code === 'member_quarter';
  }

  private memberTitle(): string {
    const snap = this.me;
    const active = snap !== null ? snap.member : this.isMember;
    const lifetime = snap !== null ? snap.lifetime : this.isLifetime;
    const planName = snap !== null ? snap.planName : this.cachedPlanName;
    if (!active) {
      return I18n.t('member_not_yet', this.lang);
    }
    if (lifetime) {
      return I18n.t('member_lifetime_on', this.lang);
    }
    return planName.length > 0 ? planName : I18n.t('member_title', this.lang);
  }

  private memberSub(): string {
    const snap = this.me;
    const active = snap !== null ? snap.member : this.isMember;
    const lifetime = snap !== null ? snap.lifetime : this.isLifetime;
    if (!active) {
      return I18n.t('member_hero_sub', this.lang);
    }
    if (lifetime) {
      return I18n.t('member_hero_life', this.lang);
    }
    const expireRaw = snap !== null ? snap.expireTime : this.cachedExpire;
    if (expireRaw !== undefined && expireRaw !== 0) {
      const ms = MemberGate.parseExpireMs(expireRaw as number | string);
      if (ms > 0) {
        const d = new Date(ms);
        if (!isNaN(d.getTime())) {
          const date = `${d.getFullYear()}-${this.datePad(d.getMonth() + 1)}-${this.datePad(d.getDate())}`;
          return I18n.tf('member_until', date, this.lang);
        }
      }
    }
    return I18n.t('member_hero_on', this.lang);
  }

  private quotaLine(q: MemberQuota | null, label: string): string {
    if (q === null) {
      return `${label} · —`;
    }
    if (q.unlimited) {
      return `${label} · ${I18n.t('member_unlimited', this.lang)}`;
    }
    return `${label} · ${I18n.tf('member_remain', `${q.remain}/${q.limit}`, this.lang)}`;
  }

  private datePad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  private isErrorHint(): boolean {
    return this.hint.indexOf('失败') >= 0;
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(26)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 6 })
          .onClick(() => {
            router.back();
          })
        Text(I18n.t('member_title', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 10 }) {
          Column({ space: 8 }) {
              Row({ space: 1 }) {
                Text(this.memberTitle())
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFF7DC')
                  .layoutWeight(1)
                MemberBadge({ tapToOpen: false })
              }
              .width('100%')
              Text(this.memberSub())
                .fontSize(13)
                .fontColor('#E8D5A3')
                .width('100%')
              Row({ space: 8 }) {
                Text(this.quotaLine(this.me !== null ? this.me.questionAi : null, I18n.t('ai_qa', this.lang)))
                  .fontSize(12)
                  .fontColor('#F6E2A4')
                  .layoutWeight(1)
                Text(this.quotaLine(this.me !== null ? this.me.interviewAi : null, I18n.t('tab_interview', this.lang)))
                  .fontSize(12)
                  .fontColor('#F6E2A4')
                  .layoutWeight(1)
              }
              .width('100%')
              Text(this.quotaLine(this.me !== null && this.me.listenAi !== undefined ? this.me.listenAi : null,
                I18n.t('home_grid_listen', this.lang)))
                .fontSize(12)
                .fontColor('#F6E2A4')
                .width('100%')
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .borderRadius(18)
          .linearGradient({ angle: 145, colors: [['#1F1633', 0], ['#3A2A12', 0.55], ['#8A5A00', 1]] })

            if (!this.memberEnabled) {
              Column({ space: 6 }) {
                Text(I18n.t('member_gate_off_title', this.lang))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                Text(I18n.t('member_gate_off_msg', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#F3F4F6')
              .borderRadius(14)
            } else {
              Column({ space: 10 }) {
                Text(I18n.t('member_perk_title', this.lang))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                Text(I18n.t('member_perk_ai', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(I18n.t('member_perk_iv', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(I18n.t('member_perk_ai_assist', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(I18n.t('member_perk_quota', this.lang))
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
              }
              .width('100%')
              .padding(14)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(14)

              if (this.hint.length > 0) {
                Text(this.hint)
                  .fontSize(12)
                  .fontColor(this.isErrorHint() ? '#DC2626' : '#6B7280')
                  .width('100%')
              }

              if (this.plansLoading) {
                Column({ space: 8 }) {
                  LoadingProgress()
                    .width(28)
                    .height(28)
                    .color('#B45309')
                  Text(I18n.t('loading', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.text_muted'))
                }
                .width('100%')
                .padding({ top: 20, bottom: 20 })
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }

              ForEach(this.plans, (plan: MemberPlan) => {
                Column({ space: 8 }) {
                  Row() {
                    Column({ space: 4 }) {
                      Row({ space: 6 }) {
                        Text(plan.name)
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .fontColor($r('app.color.text_primary'))
                        if (this.isHot(plan)) {
                          Text(I18n.t('member_plan_hot', this.lang))
                            .fontSize(10)
                            .fontColor('#9A3412')
                            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                            .backgroundColor('#FFEDD5')
                            .borderRadius(4)
                        }
                      }
                      Text(plan.subtitle)
                        .fontSize(12)
                        .fontColor($r('app.color.text_muted'))
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Column({ space: 2 }) {
                      Text(this.priceText(plan))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#B45309')
                      if (this.originText(plan).length > 0) {
                        Text(this.originText(plan))
                          .fontSize(11)
                          .fontColor($r('app.color.text_muted'))
                          .decoration({ type: TextDecorationType.LineThrough })
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  Button(this.actionLabel())
                    .width('100%')
                    .height(42)
                    .fontSize(15)
                    .backgroundColor(this.isHot(plan) ? '#B45309' : '#1F1633')
                    .enabled(!this.buying)
                    .onClick(() => {
                      this.openPaySheet(plan);
                    })
                }
                .width('100%')
                .padding(14)
                .backgroundColor($r('app.color.card_bg'))
                .borderRadius(14)
                .border({
                  width: this.isHot(plan) ? 1 : 0,
                  color: '#F6E2A4'
                })
              }, (plan: MemberPlan) => plan.code)

              // Button(I18n.t('member_restore', this.lang))
              //   .width('100%')
              //   .height(40)
              //   .fontSize(14)
              //   .backgroundColor('#FFF7ED')
              //   .fontColor('#B45309')
              //   .enabled(!this.buying)
              //   .onClick(() => {
              //     this.bootstrap();
              //   })
            }

            Text(I18n.t('member_iap_tip', this.lang))
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .bindSheet(this.paySheetOpen, this.payMethodSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      showClose: true,
      onDisappear: () => {
        this.paySheetOpen = false;
      }
    })
  }

  @Builder
  private payMethodSheet() {
    Column({ space: 14 }) {
      Text(I18n.t('member_pay_pick', this.lang))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Text(I18n.t('member_pay_alipay_only', this.lang))
        .fontSize(13)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .lineHeight(20)
      Row({ space: 12 }) {
        Text('支')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor('#1677FF')
        Text(I18n.t('member_pay_alipay', this.lang))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(22)
          .fontColor(['#1677FF'])
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F0F7FF')
      .borderRadius(14)
      .border({ width: 1, color: '#BFDBFE' })
      Button(I18n.t('member_pay_go_alipay', this.lang))
        .width('100%')
        .height(44)
        .fontSize(16)
        .backgroundColor('#1677FF')
        .onClick(() => {
          this.confirmAlipay();
        })
      Text(I18n.t('cancel', this.lang))
        .fontSize(14)
        .fontColor($r('app.color.text_muted'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 2, bottom: 4 })
        .onClick(() => {
          this.paySheetOpen = false;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 16 })
  }
}
