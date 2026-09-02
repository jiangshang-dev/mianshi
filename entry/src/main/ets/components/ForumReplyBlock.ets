import { I18n } from '../common/i18n/I18n';
import { mallBool } from '../common/models/BlogTypes';
import { ForumReply } from '../common/models/ForumTypes';
import { mallNum, mallStr } from '../common/models/MallTypes';
import { ForumUi } from '../common/utils/ForumUi';

@Component
export struct ForumReplyBlock {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop reply: ForumReply = {};
  @Prop compact: boolean = false;
  @Prop floor: number = 0;
  @Prop depth: number = 0;
  @Prop contentExpanded: boolean = false;
  onReply: (item: ForumReply) => void = (_item: ForumReply) => {
  };
  onLike: (item: ForumReply) => void = (_item: ForumReply) => {
  };
  onToggleContent: (item: ForumReply) => void = (_item: ForumReply) => {
  };

  private likeColor(on: boolean): string {
    return on ? '#2563EB' : '#9CA3AF';
  }

  private bodyText(): string {
    return mallStr(this.reply.content);
  }

  private needExpand(): boolean {
    return !this.contentExpanded && ForumUi.longContent(this.bodyText());
  }

  build() {
    Column() {
      if (this.compact) {
        this.compactRow()
      } else {
        this.fullCard()
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: this.depth > 0 ? this.depth * 14 : 0 })
  }

  @Builder
  fullCard() {
    Column({ space: 8 }) {
      Row() {
        this.avatar(36)
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(mallStr(this.reply.nickname))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
            if (mallBool(this.reply.author)) {
              Text(I18n.t('forum_author', this.lang))
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#2563EB')
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
            if (mallBool(this.reply.featured)) {
              Text(I18n.t('forum_featured', this.lang))
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#D97706')
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(ForumUi.relativeTime(mallStr(this.reply.createTime), this.lang))
            .fontSize(11)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        if (this.floor > 0) {
          Text(I18n.tf('forum_floor', `${this.floor}`, this.lang))
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      this.bodyBlock()

      Row({ space: 16 }) {
        Text(ForumUi.relativeTime(mallStr(this.reply.createTime), this.lang))
          .fontSize(12)
          .fontColor('#9CA3AF')
        Row({ space: 4 }) {
          Image($r('app.media.ic_comment_like'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor(this.likeColor(mallBool(this.reply.liked)))
          Text(`${mallNum(this.reply.likeCount)}`)
            .fontSize(12)
            .fontColor(this.likeColor(mallBool(this.reply.liked)))
        }
        .onClick(() => this.onLike(this.reply))
        Row({ space: 4 }) {
          Image($r('app.media.ic_forum_comment'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor('#2563EB')
          Text(I18n.t('forum_reply_action', this.lang))
            .fontSize(12)
            .fontColor('#2563EB')
        }
        .onClick(() => this.onReply(this.reply))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  compactRow() {
    Column({ space: 4 }) {
      Row() {
        Row({ space: 6 }) {
          Text(mallStr(this.reply.nickname))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (mallBool(this.reply.author)) {
            Text(I18n.t('forum_author', this.lang))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#2563EB')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
          if (mallBool(this.reply.featured)) {
            Text(I18n.t('forum_featured', this.lang))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#D97706')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
          if (mallStr(this.reply.replyToNickname).length > 0) {
            Text(I18n.t('forum_reply_action', this.lang))
              .fontSize(12)
              .fontColor('#9CA3AF')
            Text(mallStr(this.reply.replyToNickname))
              .fontSize(12)
              .fontColor('#6B7280')
              .maxLines(1)
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        Text(I18n.t('forum_reply_action', this.lang))
          .fontSize(12)
          .fontColor('#2563EB')
          .onClick(() => this.onReply(this.reply))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      this.bodyBlock()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  bodyBlock() {
    if (mallBool(this.reply.rejected)) {
      Text(mallStr(this.reply.rejectHint).length > 0 ? mallStr(this.reply.rejectHint) : I18n.t('forum_rejected', this.lang))
        .fontSize(12)
        .fontColor('#B45309')
        .width('100%')
    } else {
      if (mallBool(this.reply.pending)) {
        Text(mallStr(this.reply.rejectHint).length > 0 ? mallStr(this.reply.rejectHint) : I18n.t('forum_pending', this.lang))
          .fontSize(12)
          .fontColor('#B45309')
          .width('100%')
      }
      Text(this.bodyText())
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .lineHeight(22)
        .maxLines(this.needExpand() ? 3 : 20)
        .width('100%')
      if (this.needExpand()) {
        Text(I18n.t('forum_expand', this.lang))
          .fontSize(13)
          .fontColor('#2563EB')
          .padding({ top: 2, bottom: 2 })
          .onClick(() => this.onToggleContent(this.reply))
      }
    }
  }

  @Builder
  avatar(size: number) {
    if (mallStr(this.reply.avatar).length > 0) {
      Image(mallStr(this.reply.avatar))
        .width(size)
        .height(size)
        .borderRadius(size / 2)
        .objectFit(ImageFit.Cover)
        .flexShrink(0)
    } else {
      Column() {
        Text(ForumUi.nickInitial(mallStr(this.reply.nickname)))
          .fontSize(13)
          .fontColor('#FFFFFF')
      }
      .width(size)
      .height(size)
      .borderRadius(size / 2)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(ForumUi.avatarColor(mallStr(this.reply.nickname)))
      .flexShrink(0)
    }
  }
}
