import { I18n } from '../common/i18n/I18n';
import { CommentUi } from '../common/utils/CommentUi';
import { CommentItemRow } from './CommentItemRow';
import {
  CommentFlatRow,
  CommentRepository,
  emptyQuestionComment,
  QuestionComment
} from '../data/repository/CommentRepository';

@Component
export struct CommentDetailPanel {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @StorageLink('commentQuestionId') questionId: string = '';
  @StorageLink('commentDetailId') @Watch('onDetailIdChange') detailId: string = '';
  @Prop @Watch('onReload') reloadTick: number = 0;
  @Prop @Watch('onComposeChange') composeOpen: boolean = false;
  @State private root: QuestionComment = emptyQuestionComment();
  @State private flats: CommentFlatRow[] = [];
  @State private loading: boolean = false;
  private repo: CommentRepository = CommentRepository.getInstance();
  private composeWasOpen: boolean = false;
  private onPostedReload: () => void = () => {
    this.loadRoot();
  };

  aboutToAppear(): void {
    this.composeWasOpen = this.composeOpen;
    CommentUi.addReloadListener(this.onPostedReload);
    this.loadRoot();
  }

  aboutToDisappear(): void {
    CommentUi.removeReloadListener(this.onPostedReload);
  }

  onDetailIdChange(): void {
    this.loadRoot();
  }

  onReload(): void {
    this.loadRoot();
  }

  onComposeChange(): void {
    if (this.composeWasOpen && !this.composeOpen) {
      this.loadRoot();
    }
    this.composeWasOpen = this.composeOpen;
  }

  private async loadRoot(): Promise<void> {
    if (this.questionId.length === 0 || this.detailId.length === 0) {
      return;
    }
    this.loading = true;
    try {
      const list = await this.repo.list(this.questionId);
      let found = emptyQuestionComment();
      for (let i = 0; i < list.length; i++) {
        if (list[i].id === this.detailId) {
          found = list[i];
          break;
        }
      }
      this.root = found;
      this.flats = [];
      this.flats = this.flatten(found.replies, 0);
    } catch (_e) {
      this.root = emptyQuestionComment();
      this.flats = [];
    } finally {
      this.loading = false;
    }
  }

  private relatedCount(): number {
    if (this.root.replyCount > 0) {
      return this.root.replyCount;
    }
    return this.flats.length;
  }

  private flatten(nodes: QuestionComment[], depth: number): CommentFlatRow[] {
    const out: CommentFlatRow[] = [];
    this.collect(nodes, depth, out);
    return out;
  }

  private collect(nodes: QuestionComment[], depth: number, out: CommentFlatRow[]): void {
    if (nodes.length === 0) {
      return;
    }
    for (let i = 0; i < nodes.length; i++) {
      const row: CommentFlatRow = {
        key: `${nodes[i].id}_${depth}_${i}`,
        depth: depth,
        item: nodes[i]
      };
      out.push(row);
      this.collect(nodes[i].replies, depth + 1, out);
    }
  }

  private openReply(item: QuestionComment): void {
    CommentUi.openCompose(item.id, item.nickname);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .onClick(() => {
          CommentUi.closeDetail();
        })

      Column() {
        Column()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor($r('app.color.divider'))
          .margin({ top: 8, bottom: 6 })

        Row() {
          Text(I18n.t('comment_detail', this.lang))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#18191C')
            .layoutWeight(1)
          Text('✕')
            .fontSize(18)
            .fontColor('#9499A0')
            .padding(8)
            .onClick(() => {
              CommentUi.closeDetail();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 8 })

        if (this.root.id.length > 0) {
          Scroll() {
            Column() {
              Column() {
                CommentItemRow({
                  item: this.root,
                  inDetail: true,
                  showRepliesLink: false
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16 })

              Divider().color($r('app.color.divider')).margin({ top: 4, bottom: 4 })

              Row() {
                Text(`${I18n.t('comment_related', this.lang)}${this.relatedCount()}${I18n.t('comment_replies_unit', this.lang)}`)
                  .fontSize(13)
                  .fontColor('#9499A0')
                  .layoutWeight(1)
                Text(I18n.t('comment_sort_time', this.lang))
                  .fontSize(12)
                  .fontColor('#9499A0')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 10, bottom: 4 })

              ForEach(this.flats, (row: CommentFlatRow) => {
                Column() {
                  CommentItemRow({
                    item: row.item,
                    inDetail: true,
                    showRepliesLink: false,
                    indent: row.depth
                  })
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
              }, (row: CommentFlatRow) => `${row.key}_${row.item.replyCount}_${row.item.likeCount}_${row.item.content}`)
            }
            .width('100%')
            .padding({ bottom: 12 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.TopStart)

          if (!this.composeOpen) {
            Row({ space: 8 }) {
              Text(I18n.t('comment_ph', this.lang))
                .fontSize(14)
                .fontColor('#9499A0')
                .layoutWeight(1)
              Image($r('app.media.ic_comment_emoji'))
                .width(22)
                .height(22)
                .objectFit(ImageFit.Contain)
            }
            .width('100%')
            .height(36)
            .padding({ left: 14, right: 12 })
            .margin({ left: 16, right: 16, top: 8, bottom: 16 })
            .backgroundColor('#F1F2F3')
            .borderRadius(18)
            .onClick(() => {
              this.openReply(this.root);
            })
          } else {
            Column()
              .width('100%')
              .height(148)
          }
        } else if (this.loading) {
          Column() {
            LoadingProgress().width(36).height(36)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('72%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
  }
}
