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
  onDelete: (item: ForumReply) => void = (_item: ForumReply) => {
  };
  onReport: (item: ForumReply) => void = (_item: ForumReply) => {
  };

  private likeColor(on: boolean): ResourceColor {
    return on ? $r('app.color.accent') : $r('app.color.chevron');
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
                .fontColor($r('app.color.text_on_color'))
                .backgroundColor($r('app.color.accent'))
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
            if (mallBool(this.reply.featured)) {
              Text(I18n.t('forum_featured', this.lang))
                .fontSize(10)
                .fontColor($r('app.color.text_on_color'))
                .backgroundColor('#D97706')
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(ForumUi.relativeTime(mallStr(this.reply.createTime), this.lang))
            .fontSize(11)
            .fontColor($r('app.color.chevron'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        if (this.floor > 0) {
          Text(I18n.tf('forum_floor', `${this.floor}`, this.lang))
            .fontSize(12)
            .fontColor($r('app.color.chevron'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      this.bodyBlock()

      Row({ space: 16 }) {
        Text(ForumUi.ipLabel(mallStr(this.reply.ipAddress)).length > 0 ?
          `${ForumUi.relativeTime(mallStr(this.reply.createTime), this.lang)} · ${ForumUi.ipLabel(mallStr(this.reply.ipAddress))}` :
          ForumUi.relativeTime(mallStr(this.reply.createTime), this.lang))
          .fontSize(12)
          .fontColor($r('app.color.chevron'))
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
            .fillColor($r('app.color.accent'))
          Text(I18n.t('forum_reply_action', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.accent'))
        }
        .onClick(() => this.onReply(this.reply))
        if (mallBool(this.reply.mine)) {
          Text(I18n.t('delete', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.danger'))
            .onClick(() => this.onDelete(this.reply))
        } else {
          Text(I18n.t('content_report', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.chevron'))
            .onClick(() => this.onReport(this.reply))
        }
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
              .fontColor($r('app.color.text_on_color'))
              .backgroundColor($r('app.color.accent'))
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
          if (mallBool(this.reply.featured)) {
            Text(I18n.t('forum_featured', this.lang))
              .fontSize(10)
              .fontColor($r('app.color.text_on_color'))
              .backgroundColor('#D97706')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
          if (mallStr(this.reply.replyToNickname).length > 0) {
            Text(I18n.t('forum_reply_action', this.lang))
              .fontSize(12)
              .fontColor($r('app.color.chevron'))
            Text(mallStr(this.reply.replyToNickname))
              .fontSize(12)
              .fontColor($r('app.color.text_muted'))
              .maxLines(1)
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        if (mallBool(this.reply.mine)) {
          Text(I18n.t('delete', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.danger'))
            .margin({ right: 10 })
            .onClick(() => this.onDelete(this.reply))
        } else {
          Text(I18n.t('content_report', this.lang))
            .fontSize(12)
            .fontColor($r('app.color.chevron'))
            .margin({ right: 10 })
            .onClick(() => this.onReport(this.reply))
        }
        Text(I18n.t('forum_reply_action', this.lang))
          .fontSize(12)
          .fontColor($r('app.color.accent'))
          .onClick(() => this.onReply(this.reply))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      this.bodyBlock()
      if (ForumUi.ipLabel(mallStr(this.reply.ipAddress)).length > 0) {
        Text(ForumUi.ipLabel(mallStr(this.reply.ipAddress)))
          .fontSize(11)
          .fontColor($r('app.color.chevron'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  bodyBlock() {
    if (mallBool(this.reply.rejected) || mallBool(this.reply.pending)) {
      Text(mallStr(this.reply.rejectHint).length > 0 ? mallStr(this.reply.rejectHint) :
        (mallBool(this.reply.pending) ? I18n.t('forum_pending', this.lang) : I18n.t('forum_rejected', this.lang)))
        .fontSize(12)
        .fontColor($r('app.color.warning_text'))
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
        .fontColor($r('app.color.accent'))
        .padding({ top: 2, bottom: 2 })
        .onClick(() => this.onToggleContent(this.reply))
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
          .fontColor($r('app.color.text_on_color'))
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
