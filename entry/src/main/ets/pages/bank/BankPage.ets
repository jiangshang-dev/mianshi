import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Category } from '../../common/models/Types';
import { QuestionItem } from '../../common/models/Types';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

interface BankTab {
  id: string;
  name: string;
}

@Component
export struct BankPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @Prop showNavBack: boolean = false;
  @State private tabs: BankTab[] = [];
  @State private selectedId: string = 'recommend';
  @State private selectedName: string = '推荐';
  @State private difficulty: string = 'all';
  @State private difficultyLabel: string = '全部';
  @State private list: QuestionItem[] = [];
  @State private pageNo: number = 1;
  @State private loading: boolean = true;
  @State private loadingMore: boolean = false;
  @State private finished: boolean = false;
  @State private total: number = 0;
  @State private difficultyIndex: number = 0;
  @State private diffOpts: SelectOption[] = [];
  private readonly pageSize: number = 30;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.buildDiffOpts();
    this.bootstrap();
  }

  private buildDiffOpts(): void {
    const labels: string[] = [
      I18n.t('diff_all', this.lang),
      I18n.t('diff_easy', this.lang),
      I18n.t('diff_mid', this.lang),
      I18n.t('diff_hard', this.lang)
    ];
    const opts: SelectOption[] = [];
    for (let i = 0; i < labels.length; i++) {
      const opt: SelectOption = { value: labels[i] };
      opts.push(opt);
    }
    this.diffOpts = opts;
    this.difficultyLabel = labels[0];
  }

  private async bootstrap(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const groups = await this.repo.getCategoryGroups(ctx);
      let cats: Category[] = [];
      for (let i = 0; i < groups.length; i++) {
        const g = groups[i];
        if (g.name === 'skill' || g.name.indexOf('技能') >= 0 || g.title.indexOf('技能') >= 0) {
          cats = g.items;
          break;
        }
      }
      if (cats.length === 0) {
        cats = await this.repo.getCategories(ctx);
      }
      const tabs: BankTab[] = [];
      const rec: BankTab = { id: 'recommend', name: I18n.t('bank_tab_rec', this.lang) };
      tabs.push(rec);
      const limit = cats.length > 12 ? 12 : cats.length;
      for (let i = 0; i < limit; i++) {
        const c: Category = cats[i];
        if (c.id.length > 0) {
          const tab: BankTab = { id: c.id, name: c.name };
          tabs.push(tab);
        }
      }
      this.tabs = tabs;
      this.selectedId = 'recommend';
      this.selectedName = I18n.t('bank_tab_rec', this.lang);
      await this.reloadList();
    } catch (_e) {
      const fallback: BankTab = { id: 'recommend', name: I18n.t('bank_tab_rec', this.lang) };
      this.tabs = [fallback];
      this.list = [];
    } finally {
      this.loading = false;
    }
  }

  private async reloadList(): Promise<void> {
    this.pageNo = 1;
    this.finished = false;
    this.loading = true;
    try {
      const page = await this.repo.pageQuestions(this.selectedId, 1, this.pageSize, this.diffParam());
      this.list = page.records;
      this.total = page.total;
      this.finished = page.finished;
      this.pageNo = 1;
    } catch (_e) {
      this.list = [];
      this.finished = true;
    } finally {
      this.loading = false;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || this.finished || this.loading) {
      return;
    }
    this.loadingMore = true;
    const next = this.pageNo + 1;
    try {
      const page = await this.repo.pageQuestions(this.selectedId, next, this.pageSize, this.diffParam());
      const merged: QuestionItem[] = [];
      for (let i = 0; i < this.list.length; i++) {
        merged.push(this.list[i]);
      }
      for (let i = 0; i < page.records.length; i++) {
        merged.push(page.records[i]);
      }
      this.list = merged;
      this.total = page.total;
      this.pageNo = next;
      this.finished = page.finished || page.records.length === 0;
    } catch (_e) {
      this.finished = true;
    } finally {
      this.loadingMore = false;
    }
  }

  private diffParam(): string {
    return this.difficulty === 'all' ? '' : this.difficulty;
  }

  private selectTab(tab: BankTab): void {
    if (this.selectedId === tab.id) {
      return;
    }
    this.selectedId = tab.id;
    this.selectedName = tab.name;
    this.reloadList();
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/search/SearchPage' });
  }

  private openQuestion(q: QuestionItem): void {
    router.pushUrl({
      url: 'pages/bank/QuestionDetailPage',
      params: { 'id': q.id, 'title': q.title }
    });
  }

  private startLearn(): void {
    if (this.list.length > 0) {
      this.openQuestion(this.list[0]);
    }
  }

  private previewTags(q: QuestionItem): string[] {
    if (q.tags.length <= 2) {
      return q.tags;
    }
    return [q.tags[0], q.tags[1]];
  }

  private formatCount(n: number): string {
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}w`;
    }
    if (n >= 1000) {
      return `${(n / 1000).toFixed(1)}k`;
    }
    return `${n}`;
  }

  private rankColor(i: number): string {
    if (i === 0) {
      return '#EF4444';
    }
    if (i === 1) {
      return '#F97316';
    }
    if (i === 2) {
      return '#EAB308';
    }
    return '#94A3B8';
  }

  private heroTitle(): string {
    if (this.selectedId === 'recommend') {
      return I18n.t('bank_hero_rec', this.lang);
    }
    return I18n.tf('bank_hero_cat', this.selectedName, this.lang);
  }

  private onDiffChange(index: number): void {
    const values: string[] = ['all', '初级', '中级', '高级'];
    if (index < 0 || index >= values.length) {
      return;
    }
    this.difficultyIndex = index;
    this.difficulty = values[index];
    this.difficultyLabel = `${this.diffOpts[index].value}`;
    this.reloadList();
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Row() {
          if (this.showNavBack) {
            Text('‹')
              .fontSize(28)
              .fontColor($r('app.color.text_primary'))
              .padding({ right: 8 })
              .onClick(() => router.back())
          }
          Text(I18n.t('bank_title_full', this.lang))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')

        // Row({ space: 8 }) {
        //   Text('🔍').fontSize(14)
        //   Text(I18n.t('bank_search_ph', this.lang))
        //     .fontSize(13)
        //     .fontColor($r('app.color.text_muted'))
        //     .layoutWeight(1)
        // }
        // .width('100%')
        // .height(42)
        // .padding({ left: 14, right: 14 })
        // .backgroundColor('#FFFFFF')
        // .borderRadius(21)
        // .onClick(() => this.openSearch())

        Row() {
          // 分类
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.tabs, (tab: BankTab) => {
                Text(tab.name)
                  .fontSize(13)
                  .fontWeight(this.selectedId === tab.id ? FontWeight.Medium : FontWeight.Regular)
                  .fontColor(this.selectedId === tab.id ? $r('app.color.text_on_color') : $r('app.color.header_search_text'))
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.selectedId === tab.id ? $r('app.color.accent') : $r('app.color.card_bg'))
                  .borderRadius(16)
                  .onClick(() => this.selectTab(tab))
              }, (tab: BankTab) => tab.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)

          Text('☰')
            .fontSize(16)
            .fontColor($r('app.color.header_search_text'))
            .padding({ left: 10, top: 6, bottom: 6 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/bank/CategoryAllPage' });
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 8 })

      List() {
        // ListItem() {
          // Stack({ alignContent: Alignment.End }) {
          //   Column({ space: 10 }) {
          //     Text(this.heroTitle())
          //       .fontSize(18)
          //       .fontWeight(FontWeight.Bold)
          //       .fontColor('#FFFFFF')
          //     Text(I18n.t('bank_hero_sub', this.lang))
          //       .fontSize(12)
          //       .fontColor('#DBEAFE')
          //     Row() {
          //       Text(I18n.t('bank_start_learn', this.lang))
          //         .fontSize(13)
          //         .fontWeight(FontWeight.Medium)
          //         .fontColor('#2563EB')
          //         .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          //         .backgroundColor('#FFFFFF')
          //         .borderRadius(16)
          //     }
          //     .onClick(() => this.startLearn())
          //   }
          //   .alignItems(HorizontalAlign.Start)
          //   .width('100%')
          //   .padding({ left: 18, right: 90, top: 18, bottom: 18 })
          //
          //   Text('☕')
          //     .fontSize(48)
          //     .margin({ right: 16 })
          // }
          // .width('100%')
          // .borderRadius(16)
          // .linearGradient({
          //   angle: 135,
          //   colors: [['#3B82F6', 0], ['#2563EB', 1]]
          // })
        // }
        // .padding({ left: 16, right: 16, top: 4, bottom: 8 })

        ListItem() {
          Row() {
            Text(I18n.t('bank_list_title', this.lang))
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Select(this.diffOpts)
              .selected(this.difficultyIndex)
              .value(`${I18n.t('diff_filter', this.lang)} · ${this.difficultyLabel}`)
              .font({ size: 12 })
              .fontColor($r('app.color.header_search_text'))
              .selectedOptionFont({ size: 13 })
              .optionFont({ size: 13 })
              .onSelect((index: number) => this.onDiffChange(index))
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
        }

        if (this.loading && this.list.length === 0) {
          ListItem() {
            Column() {
              LoadingProgress().width(36).height(36).color($r('app.color.accent'))
            }
            .width('100%')
            .height(160)
            .justifyContent(FlexAlign.Center)
          }
        } else if (this.list.length === 0) {
          ListItem() {
            Text(I18n.t('bank_empty_list', this.lang))
              .fontSize(13)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 40, bottom: 40 })
          }
        }

        ForEach(this.list, (q: QuestionItem, index: number) => {
          ListItem() {
            Row({ space: 10 }) {
              Text(`${index + 1}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.rankColor(index))
                .width(26)
              Column({ space: 6 }) {
                Text(q.title)
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 6 }) {
                  ForEach(this.previewTags(q), (t: string) => {
                    Text(t)
                      .fontSize(10)
                      .fontColor($r('app.color.header_search_text'))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .backgroundColor($r('app.color.tag_bg'))
                      .borderRadius(4)
                  }, (t: string) => `${q.id}_${t}`)
                  if (q.difficulty.length > 0) {
                    Text(q.difficulty)
                      .fontSize(10)
                      .fontColor($r('app.color.header_search_text'))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .backgroundColor($r('app.color.ai_badge_bg'))
                      .borderRadius(4)
                  }
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Row({ space: 2 }) {
                Text('🔥').fontSize(11)
                Text(this.formatCount(q.viewCount !== undefined ? q.viewCount : 0))
                  .fontSize(11)
                  .fontColor($r('app.color.text_muted'))
              }
              Text('›').fontSize(18).fontColor($r('app.color.chevron'))
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => this.openQuestion(q))
          }
        }, (q: QuestionItem) => q.id)

        ListItem() {
          Column() {
            if (this.loadingMore) {
              LoadingProgress().width(24).height(24).color($r('app.color.accent'))
            } else if (this.finished && this.list.length > 0) {
              Text(I18n.t('bank_no_more', this.lang))
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
            }
          }
          .width('100%')
          .padding({ top: 12, bottom: 28 })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .onReachEnd(() => {
        this.loadMore();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
