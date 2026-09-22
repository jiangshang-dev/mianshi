import { promptAction, router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { I18n } from '../../common/i18n/I18n';
import { BlogArticle, copyBlogArticle, mallBool } from '../../common/models/BlogTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { MdContentView } from '../../components/MdContentView';
import { BlogCommentBlock } from '../../components/BlogCommentBlock';
import { MdParser, MdSection } from '../../data/parser/MdParser';
import { BlogRepository } from '../../data/repository/BlogRepository';
import { ContentReportNav } from '../../common/utils/ContentReportNav';
import { ForumUi } from '../../common/utils/ForumUi';
import { LoginGate } from '../../common/utils/LoginGate';

interface BlogDetailParams {
  articleId?: string;
}

@Entry
@Component
struct BlogDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private article: BlogArticle | null = null;
  @State private tocOpen: boolean = false;
  @State private refreshing: boolean = false;
  @State private sections: MdSection[] = [];
  @State private expanded: boolean = false;
  private articleId: string = '';
  private scroller: Scroller = new Scroller();
  private repo: BlogRepository = BlogRepository.getInstance();

  private pageReady: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as BlogDetailParams;
    this.articleId = params !== undefined && params.articleId !== undefined ? params.articleId : '';
    this.load(false);
  }

  onPageShow(): void {
    if (!this.pageReady) {
      this.pageReady = true;
      return;
    }
    this.load(true);
    BlogRepository.bumpComments();
  }

  aboutToDisappear(): void {
    BlogRepository.bumpList();
  }

  private pullRefresh(): void {
    this.refreshing = true;
    this.load(true).then(() => {
      BlogRepository.bumpComments();
      BlogRepository.bumpList();
      this.refreshing = false;
    }).catch(() => {
      this.refreshing = false;
    });
  }

  private async load(silent: boolean): Promise<void> {
    if (this.articleId.length === 0) {
      this.loading = false;
      return;
    }
    if (!silent) {
      this.loading = true;
    }
    try {
      const detail = copyBlogArticle(await this.repo.detail(this.articleId));
      this.article = detail;
      this.sections = MdParser.splitSections(mallStr(detail.content));
      const pts = mallNum(detail.readPoints);
      if (!silent && pts > 0) {
        const cur = mallNum(AppStorage.get('userPoints') as number);
        AppStorage.setOrCreate('userPoints', cur + pts);
        promptAction.showToast({ message: I18n.tf('blog_read_pts', `${pts}`, this.lang) });
      }
    } catch (err) {
      this.article = null;
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('blog_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private toggleLike(): void {
    LoginGate.ensure(I18n.t('blog_like', this.lang), () => {
      this.repo.toggleLike(this.articleId).then((res) => {
        const current = this.article;
        if (current === null) {
          return;
        }
        current.liked = res.on === true;
        current.likeCount = mallNum(res.count);
        this.article = current;
      }).catch((err: Error) => {
        promptAction.showToast({ message: err.message });
      });
    });
  }

  private toggleFav(): void {
    LoginGate.ensure(I18n.t('blog_fav', this.lang), () => {
      this.repo.toggleFavorite(this.articleId).then((res) => {
        const current = this.article;
        if (current === null) {
          return;
        }
        current.favored = res.on === true;
        current.favoriteCount = mallNum(res.count);
        this.article = current;
        promptAction.showToast({
          message: res.on === true ? I18n.t('fav_on', this.lang) : I18n.t('fav_off', this.lang)
        });
      }).catch((err: Error) => {
        promptAction.showToast({ message: err.message });
      });
    });
  }

  private shareArticle(): void {
    const title = this.articleTitle();
    const summary = this.articleSummary();
    const text = summary.length > 0 ? `${title}\n${summary}` : title;
    if (text.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      promptAction.showToast({ message: I18n.t('forum_copied', this.lang) });
    }).catch(() => {
      promptAction.showToast({ message: I18n.t('forum_copied', this.lang) });
    });
  }

  private followSoon(): void {
    promptAction.showToast({ message: I18n.t('forum_soon', this.lang) });
  }

  private openMember(): void {
    LoginGate.ensure(I18n.t('member_title', this.lang), () => {
      router.pushUrl({ url: 'pages/profile/MemberPage' });
    });
  }

  private jumpSection(index: number): void {
    this.tocOpen = false;
    this.scroller.scrollToIndex(index + 1);
  }

  private articleTitle(): string {
    return this.article === null ? '' : mallStr(this.article.title);
  }

  private articleSummary(): string {
    return this.article === null ? '' : mallStr(this.article.summary);
  }

  private articleCover(): string {
    return this.article === null ? '' : mallStr(this.article.coverUrl);
  }

  private articleContent(): string {
    return this.article === null ? '' : mallStr(this.article.content);
  }

  private articleAuthor(): string {
    return this.article === null ? '' : mallStr(this.article.authorName);
  }

  private articleCategory(): string {
    return this.article === null ? '' : mallStr(this.article.categoryName);
  }

  private articleIp(): string {
    return this.article === null ? '' : ForumUi.ipLabel(mallStr(this.article.ipAddress));
  }

  private reportArticle(): void {
    ContentReportNav.open(this.lang, 'BLOG_ARTICLE', this.articleId, this.articleTitle());
  }

  private articleTime(): string {
    return this.article === null ? '' : mallStr(this.article.publishTime);
  }

  private articleLiked(): boolean {
    return this.article === null ? false : mallBool(this.article.liked);
  }

  private articleFavored(): boolean {
    return this.article === null ? false : mallBool(this.article.favored);
  }

  private articleVipLocked(): boolean {
    return this.article === null ? false : mallBool(this.article.vipLocked);
  }

  private articleVipOnly(): boolean {
    return this.article === null ? false : mallBool(this.article.vipOnly);
  }

  private articleViewCount(): number {
    return this.article === null ? 0 : mallNum(this.article.viewCount);
  }

  private articleLikeCount(): number {
    return this.article === null ? 0 : mallNum(this.article.likeCount);
  }

  private visibleSections(): MdSection[] {
    if (this.expanded || this.sections.length <= 1) {
      return this.sections;
    }
    const out: MdSection[] = [];
    out.push(this.sections[0]);
    return out;
  }

  private needExpand(): boolean {
    return !this.expanded && !this.articleVipLocked() && this.sections.length > 1;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.text_primary'))
            .padding({ right: 8 })
            .onClick(() => router.back())
          Text(I18n.t('tab_blog', this.lang))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Text(this.articleFavored() ? '★' : '☆')
            .fontSize(22)
            .fontColor(this.articleFavored() ? '#F59E0B' : '#6B7280')
            .padding({ left: 10, right: 6 })
            .onClick(() => this.toggleFav())
          // Image($r('app.media.ic_forum_share'))
          //   .width(20)
          //   .height(20)
          //   .objectFit(ImageFit.Contain)
          //   .fillColor('#111827')
          //   .padding({ left: 6, right: 4 })
          //   .onClick(() => this.shareArticle())
          Text(I18n.t('content_report', this.lang))
            .fontSize(14)
            .fontColor('#6B7280')
            .padding({ left: 8, top: 6, bottom: 6 })
            .onClick(() => this.reportArticle())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.card_bg'))

        if (this.loading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.article === null) {
          Column() {
            Text(I18n.t('blog_not_found', this.lang)).fontSize(15).fontColor($r('app.color.text_muted'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.refreshing }) {
            List({ scroller: this.scroller, space: 0 }) {
              ListItem() {
                this.articleHeader()
              }

              if (this.articleCover().length > 0) {
                ListItem() {
                  Image(this.articleCover())
                    .width('100%')
                    .height(180)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(10)
                    .margin({ left: 16, right: 16, top: 12, bottom: 8 })
                }
              }

              if (this.articleSummary().length > 0) {
                ListItem() {
                  Row({ space: 8 }) {
                    Text('“')
                      .fontSize(28)
                      .fontColor('#2563EB')
                      .margin({ top: -6 })
                    Text(this.articleSummary())
                      .fontSize(13)
                      .fontColor('#1E3A8A')
                      .lineHeight(20)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                  .padding(12)
                  .margin({ left: 16, right: 16, top: 4, bottom: 8 })
                  .backgroundColor('#EFF6FF')
                  .borderRadius(10)
                }
              }

              if (this.sections.length === 0) {
                ListItem() {
                  Column() {
                    MdContentView({ content: this.articleContent(), lockHalf: this.articleVipLocked() })
                  }
                  .padding({ left: 16, right: 16, top: 4 })
                }
              } else {
                ForEach(this.visibleSections(), (sec: MdSection, idx: number) => {
                  ListItem() {
                    Column({ space: 8 }) {
                      Text(sec.title)
                        .fontSize(sec.level === 2 ? 18 : 16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.text_primary'))
                        .width('100%')
                      MdContentView({ content: sec.content, lockHalf: this.articleVipLocked() })
                    }
                    .padding({ left: 16, right: 16, top: 10 })
                  }
                }, (sec: MdSection, idx: number) => `${idx}-${sec.title}`)
              }

              if (this.needExpand()) {
                ListItem() {
                  Row({ space: 4 }) {
                    Text(I18n.t('blog_expand', this.lang))
                      .fontSize(14)
                      .fontColor('#2563EB')
                    Text('⌄')
                      .fontSize(14)
                      .fontColor('#2563EB')
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding({ top: 8, bottom: 12 })
                  .onClick(() => {
                    this.expanded = true;
                  })
                }
              }

              if (this.articleVipLocked()) {
                ListItem() {
                  Column() {
                    Column({ space: 10 }) {
                      Text(I18n.t('blog_vip_lock', this.lang))
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                        .width('100%')
                        .textAlign(TextAlign.Center)
                      // Button(I18n.t('blog_open_vip', this.lang))
                      //   .width('100%')
                      //   .height(42)
                      //   .backgroundColor($r('app.color.accent'))
                      //   .onClick(() => this.openMember())
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Center)
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .backgroundColor('#FFF7ED')
                    .borderRadius(12)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, bottom: 12 })
                }
              }

              ListItem() {
                BlogCommentBlock({
                  articleId: this.articleId,
                  authorName: this.articleAuthor(),
                  onOpenToc: () => {
                    if (this.sections.length === 0) {
                      promptAction.showToast({ message: I18n.t('blog_no_toc', this.lang) });
                      return;
                    }
                    this.tocOpen = true;
                  },
                  onPosted: () => {
                    this.load(true);
                  }
                })
              }

              ListItem() {
                Row().height(88).width('100%')
              }
            }
            .layoutWeight(1)
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
          .layoutWeight(1)
          .width('100%')
          .onRefreshing(() => this.pullRefresh())
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))

      if (this.tocOpen) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => {
              this.tocOpen = false;
            })
          Column({ space: 8 }) {
            Text(I18n.t('blog_toc', this.lang))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            ForEach(this.sections, (sec: MdSection, idx: number) => {
              Text(sec.title)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .padding({ left: sec.level === 3 ? 12 : 0, top: 8, bottom: 8 })
                .width('100%')
                .onClick(() => this.jumpSection(idx))
            }, (sec: MdSection, idx: number) => `toc-${idx}-${sec.title}`)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius({ topLeft: 16, topRight: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  articleHeader() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(this.articleTitle())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (this.articleVipOnly()) {
          Text('VIP')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#D97706')
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
            .borderRadius(4)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        Column() {
          Text(ForumUi.nickInitial(this.articleAuthor()))
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ForumUi.avatarColor(this.articleAuthor()))
        .flexShrink(0)

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(this.articleAuthor())
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
            Text(I18n.t('blog_author', this.lang))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#2563EB')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
            if (this.articleVipOnly()) {
              Text('VIP')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#D97706')
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(4)
            }
          }
          .alignItems(VerticalAlign.Center)
          Text(`${ForumUi.relativeTime(this.articleTime(), this.lang)}${this.articleCategory().length > 0 ?
            ' · ' + this.articleCategory() : ''}${this.articleIp().length > 0 ? ' · ' + this.articleIp() : ''}`)
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })

        // Text(I18n.t('blog_follow', this.lang))
        //   .fontSize(13)
        //   .fontColor('#2563EB')
        //   .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        //   .borderRadius(16)
        //   .border({ width: 1, color: '#2563EB' })
        //   .onClick(() => this.followSoon())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 16 }) {
        Text(I18n.tf('blog_views', ForumUi.formatCount(this.articleViewCount()), this.lang))
          .fontSize(13)
          .fontColor('#6B7280')
        Text(I18n.tf('blog_agree', ForumUi.formatCount(this.articleLikeCount()), this.lang))
          .fontSize(13)
          .fontColor(this.articleLiked() ? '#2563EB' : '#6B7280')
          .onClick(() => this.toggleLike())
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 8, bottom: 4 })
    .backgroundColor($r('app.color.card_bg'))
  }
}
