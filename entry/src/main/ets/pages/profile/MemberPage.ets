import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { MemberMe, MemberPlan, MemberQuota } from '../../common/models/MemberTypes';
import { IapService } from '../../common/utils/IapService';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { MemberRepository } from '../../data/repository/MemberRepository';
import { MemberBadge } from '../../components/MemberBadge';

@Entry
@Component
struct MemberPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('memberEnabled') memberEnabled: boolean = true;
  @State private loading: boolean = true;
  @State private buying: boolean = false;
  @State private me: MemberMe | null = null;
  @State private plans: MemberPlan[] = [];
  @State private hint: string = '';
  private repo: MemberRepository = MemberRepository.getInstance();

  aboutToAppear(): void {
    this.bootstrap();
  }

  private hostContext(): common.UIAbilityContext {
    const host = this.getUIContext().getHostContext();
    if (host) {
      return host as common.UIAbilityContext;
    }
    return getContext(this) as common.UIAbilityContext;
  }

  private async bootstrap(): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      this.loading = false;
      LoginGate.ensure(I18n.t('member_title', this.lang), () => {
        this.bootstrap();
      });
      return;
    }
    this.loading = true;
    try {
      const ctx = this.hostContext();
      await IapService.restoreUnfinished(ctx);
      const snapshot = await this.repo.me();
      this.me = snapshot;
      const list = snapshot !== null && snapshot.plans.length > 0 ? snapshot.plans : await this.repo.plans();
      await IapService.queryLocalPrice(ctx, list);
      this.plans = list;
      const env = await IapService.queryEnv(ctx);
      this.hint = env === 0 ? '' : I18n.t('member_iap_unavail', this.lang);
    } catch (err) {
      this.hint = err instanceof Error ? err.message : I18n.t('member_load_fail', this.lang);
    } finally {
      this.loading = false;
    }
  }

  private async buy(plan: MemberPlan): Promise<void> {
    if (this.buying || !this.memberEnabled) {
      return;
    }
    this.buying = true;
    try {
      const result = await IapService.buy(this.hostContext(), plan);
      promptAction.showToast({ message: result.message });
      if (result.ok) {
        await this.bootstrap();
      }
    } finally {
      this.buying = false;
    }
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
    if (snap === null || !snap.member) {
      return I18n.t('member_not_yet', this.lang);
    }
    if (snap.lifetime) {
      return I18n.t('member_lifetime_on', this.lang);
    }
    return snap.planName.length > 0 ? snap.planName : I18n.t('member_title', this.lang);
  }

  private memberSub(): string {
    const snap = this.me;
    if (snap === null || !snap.member) {
      return I18n.t('member_hero_sub', this.lang);
    }
    if (snap.lifetime) {
      return I18n.t('member_hero_life', this.lang);
    }
    if (snap.expireTime !== undefined && snap.expireTime > 0) {
      const ms = MemberGate.parseExpireMs(snap.expireTime as number | string);
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
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => {
            router.back();
          })
        // Text(I18n.t('member_title', this.lang))
        //   .fontSize(18)
        //   .fontWeight(FontWeight.Bold)
        //   .fontColor($r('app.color.text_primary'))
        //   .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 8, bottom: 8 })

      if (this.loading) {
        Text(I18n.t('loading', this.lang))
          .fontSize(14)
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 40 })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
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
            }
            .width('100%')
            .padding(18)
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
                  Button(this.buying ? I18n.t('member_buying', this.lang) :
                    (this.me !== null && this.me.member ? I18n.t('member_renew', this.lang) : I18n.t('member_buy', this.lang)))
                    .width('100%')
                    .height(42)
                    .fontSize(15)
                    .backgroundColor(this.isHot(plan) ? '#B45309' : '#1F1633')
                    .enabled(!this.buying)
                    .onClick(() => {
                      this.buy(plan);
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
          .padding({ left: 16, right: 16, bottom: 24 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
