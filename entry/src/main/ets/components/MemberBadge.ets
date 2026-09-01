import { I18n } from '../common/i18n/I18n';
import { MemberGate } from '../common/utils/MemberGate';

@Component
export struct MemberBadge {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('memberEnabled') memberEnabled: boolean = true;
  @StorageLink('isMember') isMember: boolean = false;
  @StorageLink('isLifetimeMember') isLifetime: boolean = false;
  @StorageLink('memberPlanName') planName: string = '';
  @Prop tapToOpen: boolean = true;

  private badgeText(): string {
    if (this.planName.length > 0) {
      return this.planName;
    }
    return this.isLifetime ? I18n.t('member_badge_life', this.lang) : I18n.t('member_badge', this.lang);
  }

  build() {
    if (!this.memberEnabled) {
      Blank().width(0).height(0)
    } else if (this.isMember) {
      Text(this.badgeText())
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8A5A00')
        .padding({ left: 7, right: 7, top: 2, bottom: 2 })
        .borderRadius(4)
        .backgroundColor('#F6E2A4')
        .onClick(() => {
          if (this.tapToOpen) {
            MemberGate.goMember();
          }
        })
    } else {
      Text(I18n.t('member_badge_need', this.lang))
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#B45309')
        .padding({ left: 7, right: 7, top: 2, bottom: 2 })
        .borderRadius(4)
        .backgroundColor('#FEF3C7')
        .onClick(() => {
          if (this.tapToOpen) {
            MemberGate.goMember();
          }
        })
    }
  }
}

@Component
export struct MemberNeedHint {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('memberEnabled') memberEnabled: boolean = true;
  @StorageLink('isMember') isMember: boolean = false;

  build() {
    if (!this.memberEnabled || this.isMember) {
      Blank().width(0).height(0)
    } else {
      Row({ space: 8 }) {
        Text(I18n.t('member_badge_need', this.lang))
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#92400E')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('#FDE68A')
          .borderRadius(6)
        Text(I18n.t('member_ai_need', this.lang))
          .fontSize(12)
          .fontColor('#92400E')
          .layoutWeight(1)
          .maxLines(2)
        Text(I18n.t('member_go', this.lang))
          .fontSize(12)
          .fontColor('#B45309')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      .backgroundColor('#FFFBEB')
      .borderRadius(10)
      .onClick(() => {
        MemberGate.goMember();
      })
    }
  }
}
