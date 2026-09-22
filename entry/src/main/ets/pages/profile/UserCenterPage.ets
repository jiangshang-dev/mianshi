import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { LoginGate } from '../../common/utils/LoginGate';
import { MemberGate } from '../../common/utils/MemberGate';
import { MemberBadge } from '../../components/MemberBadge';
import {
  CheckinDay,
  CheckinResult,
  MemberBonus,
  PointsLedgerRow,
  PointsMe,
  emptyPointsMe,
  pointsChangeText
} from '../../common/models/PointsTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { PointsRepository } from '../../data/repository/PointsRepository';

@Entry
@Component
struct UserCenterPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('userDisplayName') displayName: string = '';
  @StorageLink('userAvatarUrl') avatarUrl: string = '';
  @StorageLink('memberEnabled') memberEnabled: boolean = true;
  @State private loading: boolean = true;
  @State private checking: boolean = false;
  @State private me: PointsMe = emptyPointsMe();
  private repo: PointsRepository = PointsRepository.getInstance();

  aboutToAppear(): void {
    this.reload(true);
  }

  onPageShow(): void {
    this.reload(false);
  }

  private async reload(block: boolean): Promise<void> {
    if (!LoginGate.isLoggedIn()) {
      this.loading = false;
      LoginGate.ensure(I18n.t('uc_title', this.lang), () => {
        this.reload(true);
      });
      return;
    }
    if (block) {
      this.loading = true;
    }
    try {
      this.me = await this.repo.me();
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('uc_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private async doCheckin(): Promise<void> {
    if (this.checking || this.me.todayChecked === true) {
      return;
    }
    this.checking = true;
    try {
      const result: CheckinResult = await this.repo.checkin();
      await this.reload(false);
      if (result.already === true) {
        promptAction.showToast({ message: I18n.t('uc_checked', this.lang) });
      } else {
        promptAction.showToast({
          message: I18n.tf('uc_checkin_ok', `${mallNum(result.awarded)}`, this.lang)
        });
      }
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('uc_checkin_fail', this.lang) });
    } finally {
      this.checking = false;
    }
  }

  private pointsText(): string {
    return `${mallNum(this.me.points)}`;
  }

  private streakText(): string {
    return I18n.tf('uc_streak', `${mallNum(this.me.streak)}`, this.lang);
  }

  private studyText(): string {
    return I18n.tf2('uc_study_line', `${mallNum(this.me.studyMinutes)}`,
      `${mallNum(this.me.studyPointsToday)}`, this.lang);
  }

  private studyNextText(): string {
    const minutes = mallNum(this.me.studyMinutes);
    const bucket = mallNum(this.me.studyBucketMinutes, 10);
    const per = mallNum(this.me.studyPointsPerBucket, 5);
    const maxB = mallNum(this.me.studyMaxBuckets, 6);
    if (bucket <= 0) {
      return I18n.t('uc_study_hint', this.lang);
    }
    const done = Math.min(maxB, Math.floor(minutes / bucket));
    if (done >= maxB) {
      return I18n.t('uc_study_max', this.lang);
    }
    const remain = bucket - (minutes % bucket);
    return I18n.tf2('uc_study_next', `${remain}`, `${per}`, this.lang);
  }

  private week(): CheckinDay[] {
    return this.me.week !== undefined ? this.me.week : [];
  }

  private bonuses(): MemberBonus[] {
    return this.me.memberBonuses !== undefined ? this.me.memberBonuses : [];
  }

  private recent(): PointsLedgerRow[] {
    return this.me.recent !== undefined ? this.me.recent : [];
  }

  private goMall(): void {
    router.pushUrl({ url: 'pages/mall/MallPage' });
  }

  private goMember(): void {
    MemberGate.goMember();
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor($r('app.color.text_primary')).padding({ right: 8 }).onClick(() => router.back())
        Text(I18n.t('uc_title', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Row({ space: 12 }) {
              if (this.avatarUrl.length > 0) {
                Image(this.avatarUrl)
                  .width(52)
                  .height(52)
                  .borderRadius(26)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  Text('华').fontSize(18).fontColor($r('app.color.text_on_color'))
                }
                .width(52)
                .height(52)
                .borderRadius(26)
                .justifyContent(FlexAlign.Center)
                .backgroundColor('#CF0A2C')
              }
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(this.displayName.length > 0 ? this.displayName : I18n.t('huawei_user', this.lang))
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  if (this.memberEnabled) {
                    MemberBadge()
                  }
                }
                .width('100%')
                Text(I18n.t('huawei_on', this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)

            Column({ space: 12 }) {
              Row() {
                Column({ space: 2 }) {
                  Text(I18n.t('uc_points', this.lang)).fontSize(12).fontColor($r('app.color.text_muted'))
                  Text(this.pointsText())
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Button(this.me.todayChecked === true ?
                  I18n.t('uc_checked', this.lang) :
                  (this.checking ? I18n.t('uc_checking', this.lang) :
                    I18n.tf('uc_checkin', `${mallNum(this.me.todayReward)}`, this.lang)))
                  .height(36)
                  .fontSize(13)
                  .backgroundColor(this.me.todayChecked === true ? '#E5E7EB' : '#2563EB')
                  .fontColor(this.me.todayChecked === true ? '#6B7280' : Color.White)
                  .enabled(this.me.todayChecked !== true && !this.checking)
                  .onClick(() => {
                    this.doCheckin();
                  })
              }
              .width('100%')
              Text(this.streakText()).fontSize(12).fontColor($r('app.color.text_muted')).width('100%')
              Row() {
                ForEach(this.week(), (item: CheckinDay) => {
                  Column({ space: 4 }) {
                    Text(`+${mallNum(item.points)}`)
                      .fontSize(11)
                      .fontColor(item.reached === true ? '#B45309' : $r('app.color.text_muted'))
                    Column() {
                      Text(`${mallNum(item.day)}`)
                        .fontSize(12)
                        .fontColor(item.reached === true ? Color.White : $r('app.color.text_primary'))
                    }
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(item.reached === true ? '#F59E0B' : '#F3F4F6')
                  }
                  .layoutWeight(1)
                }, (item: CheckinDay) => `${mallNum(item.day)}`)
              }
              .width('100%')
              Text(I18n.t('uc_checkin_hint', this.lang)).fontSize(11).fontColor($r('app.color.text_muted')).width('100%')
            }
            .width('100%')
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)

            Column({ space: 6 }) {
              Text(I18n.t('uc_study', this.lang))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Text(this.studyText()).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
              Text(this.studyNextText()).fontSize(12).fontColor($r('app.color.text_muted')).width('100%')
              Text(I18n.t('uc_study_hint', this.lang)).fontSize(12).fontColor($r('app.color.text_muted')).width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)

            Column({ space: 8 }) {
              Text(I18n.t('uc_member_bonus', this.lang))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              ForEach(this.bonuses(), (item: MemberBonus) => {
                Row() {
                  Text(mallStr(item.name)).fontSize(13).fontColor($r('app.color.text_primary')).layoutWeight(1)
                  Text(`+${mallNum(item.bonusPoints)}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#B45309')
                }
                .width('100%')
              }, (item: MemberBonus) => mallStr(item.code))
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)

            Column({ space: 8 }) {
              Text(I18n.t('uc_ledger', this.lang))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              if (this.recent().length === 0) {
                Text(I18n.t('uc_ledger_empty', this.lang)).fontSize(13).fontColor($r('app.color.text_muted'))
              } else {
                ForEach(this.recent(), (item: PointsLedgerRow) => {
                  Row() {
                    Column({ space: 2 }) {
                      Text(mallStr(item.remark).length > 0 ? mallStr(item.remark) : mallStr(item.bizType))
                        .fontSize(13)
                        .fontColor($r('app.color.text_primary'))
                      Text(mallStr(item.createTime)).fontSize(11).fontColor($r('app.color.text_muted'))
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Text(pointsChangeText(item.changeAmount))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(mallNum(item.changeAmount) >= 0 ? '#16A34A' : '#DC2626')
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (item: PointsLedgerRow) => mallStr(item.id))
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)

            Row({ space: 10 }) {
              Button(I18n.t('mall_title', this.lang))
                .layoutWeight(1)
                .height(40)
                .fontSize(14)
                .backgroundColor('#111827')
                .onClick(() => {
                  this.goMall();
                })
              // if (this.memberEnabled) {
              //   Button(I18n.t('member_title', this.lang))
              //     .layoutWeight(1)
              //     .height(40)
              //     .fontSize(14)
              //     .backgroundColor('#2563EB')
              //     .onClick(() => {
              //       this.goMember();
              //     })
              // }
            }
            .width('100%')
          }
          .padding({ left: 16, right: 16, bottom: 24 })
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
