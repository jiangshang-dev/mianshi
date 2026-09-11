import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BookCategory, BookItem } from '../../common/models/BookTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BookCover } from '../../components/BookCover';
import { BookRepository } from '../../data/repository/BookRepository';

interface BookPair {
  a: BookItem;
  b: BookItem;
  hasB: boolean;
  key: string;
}

@Component
export struct BookPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private mainTab: number = 0;
  @State private loading: boolean = true;
  @State private cats: BookCategory[] = [];
  @State private hotBooks: BookItem[] = [];
  @State private newBooks: BookItem[] = [];
  @State private featured: BookItem = { id: '' };
  @State private rankList: BookItem[] = [];
  @State private shelfList: BookItem[] = [];
  @State private catId: string = '';
  @State private catBooks: BookItem[] = [];
  private repo: BookRepository = BookRepository.getInstance();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    if (this.cats.length === 0) {
      this.reload();
    }
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      const home = await this.repo.home();
      this.cats = home.categories !== undefined ? home.categories : await this.repo.categories();
      this.hotBooks = home.weekly !== undefined ? home.weekly.slice(0, 4) : [];
      this.newBooks = home.featured !== undefined ? home.featured.slice(0, 6) : [];
      if (this.newBooks.length === 0 && this.hotBooks.length > 0) {
        this.newBooks = this.hotBooks;
      }
      if (home.featured !== undefined && home.featured.length > 0) {
        this.featured = home.featured[0];
      } else if (this.hotBooks.length > 0) {
        this.featured = this.hotBooks[0];
      } else {
        this.featured = this.emptyBook();
      }
      if (home.continueReading !== undefined && mallStr(home.continueReading.id).length > 0) {
        this.shelfList = [home.continueReading];
      } else {
        this.shelfList = [];
      }
      if (this.catId.length === 0 && this.cats.length > 0) {
        this.catId = mallStr(this.cats[0].id);
      }
    } catch (_e) {
      this.cats = [];
      this.hotBooks = [];
      this.newBooks = [];
    }
    try {
      const rank = await this.repo.list('rank', '', 1);
      this.rankList = rank.records !== undefined ? rank.records : [];
      if (this.hotBooks.length === 0 && this.rankList.length > 0) {
        this.hotBooks = this.rankList.slice(0, 4);
      }
    } catch (_e) {
      this.rankList = [];
    }
    if (this.mainTab === 1) {
      await this.loadCatBooks();
    }
    this.loading = false;
  }

  private async loadCatBooks(): Promise<void> {
    try {
      const page = await this.repo.list('', this.catId, 1);
      this.catBooks = page.records !== undefined ? page.records : [];
    } catch (_e) {
      this.catBooks = [];
    }
  }

  private switchTab(i: number): void {
    this.mainTab = i;
    if (i === 1 && this.catBooks.length === 0) {
      this.loadCatBooks();
    }
  }

  private selectCat(id: string): void {
    this.catId = id;
    this.loadCatBooks();
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/search/SearchPage' });
  }

  private openReader(item: BookItem): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({ url: 'pages/book/BookReaderPage', params: { 'id': id } });
  }

  private openCatPage(cat: BookCategory): void {
    const id = mallStr(cat.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/book/BookCategoryPage',
      params: {
        'categoryId': id,
        'title': mallStr(cat.name),
        'intro': mallStr(cat.intro),
        'icon': mallStr(cat.icon)
      }
    });
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

  private emptyBook(): BookItem {
    const item: BookItem = { id: '' };
    return item;
  }

  private hotPairs(): BookPair[] {
    const pairs: BookPair[] = [];
    const list = this.hotBooks;
    for (let i = 0; i < list.length; i += 2) {
      const empty: BookItem = this.emptyBook();
      const pair: BookPair = {
        a: list[i],
        b: i + 1 < list.length ? list[i + 1] : empty,
        hasB: i + 1 < list.length,
        key: mallStr(list[i].id)
      };
      pairs.push(pair);
    }
    return pairs;
  }

  private gridCats(): BookCategory[] {
    if (this.cats.length <= 8) {
      return this.cats;
    }
    const out: BookCategory[] = [];
    for (let i = 0; i < 8; i++) {
      out.push(this.cats[i]);
    }
    return out;
  }

  private catIcon(cat: BookCategory): string {
    const icon = mallStr(cat.icon);
    return icon.length > 0 ? icon : '📘';
  }

  private catBg(index: number): string {
    const colors: string[] = ['#DBEAFE', '#DCFCE7', '#EDE9FE', '#FFEDD5', '#FCE7F3', '#E0F2FE', '#FEF3C7', '#E2E8F0'];
    return colors[index % colors.length];
  }

  @Builder
  sectionTitle(icon: string, titleKey: string) {
    Text(`${icon} ${I18n.t(titleKey, this.lang)}`)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor('#0F172A')
      .width('100%')
  }

  @Builder
  recommendBody() {
    Column({ space: 16 }) {
      Stack({ alignContent: Alignment.End }) {
        Column({ space: 10 }) {
          Text(I18n.t('book_hero_title', this.lang))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(I18n.t('book_hero_sub', this.lang))
            .fontSize(12)
            .fontColor('#DBEAFE')
          Row() {
            Text(I18n.t('book_hero_btn', this.lang))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2563EB')
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
          }
          .onClick(() => this.switchTab(1))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 18, right: 90, top: 18, bottom: 18 })
        Text('📚').fontSize(48).margin({ right: 14 })
      }
      .width('100%')
      .borderRadius(16)
      .linearGradient({
        angle: 135,
        colors: [['#3B82F6', 0], ['#1D4ED8', 1]]
      })

      Column({ space: 12 }) {
        this.sectionTitle('🔥', 'book_sec_hot')
        ForEach(this.hotPairs(), (pair: BookPair) => {
          Row({ space: 12 }) {
            this.bookCell(pair.a)
            if (pair.hasB) {
              this.bookCell(pair.b)
            } else {
              Blank().layoutWeight(1)
            }
          }
          .width('100%')
        }, (pair: BookPair) => pair.key)
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)

      Column({ space: 12 }) {
        this.sectionTitle('🏷️', 'book_sec_cats')
        Grid() {
          ForEach(this.gridCats(), (cat: BookCategory, index: number) => {
            GridItem() {
              Column({ space: 4 }) {
                Text(this.catIcon(cat)).fontSize(20)
                Text(mallStr(cat.name))
                  .fontSize(12)
                  .fontColor('#0F172A')
                  .maxLines(1)
                Text(I18n.tf('book_count_n', `${mallNum(cat.bookCount)}`, this.lang))
                  .fontSize(10)
                  .fontColor('#94A3B8')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor(this.catBg(index))
              .borderRadius(12)
              .onClick(() => this.openCatPage(cat))
            }
          }, (cat: BookCategory) => mallStr(cat.id))
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(10)
        .columnsGap(10)
        .width('100%')
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)

      Column({ space: 12 }) {
        this.sectionTitle('✨', 'book_sec_new')
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.newBooks, (b: BookItem) => {
              Column({ space: 6 }) {
                BookCover({ item: b, coverWidth: 88, coverHeight: 118 })
                Text(mallStr(b.title))
                  .fontSize(12)
                  .fontColor('#0F172A')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(88)
                Text(I18n.tf('book_readers', this.formatCount(mallNum(b.viewCount)), this.lang))
                  .fontSize(10)
                  .fontColor('#94A3B8')
                  .width(88)
              }
              .width(88)
              .alignItems(HorizontalAlign.Start)
              .onClick(() => this.openReader(b))
            }, (b: BookItem) => mallStr(b.id))
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)

      if (mallStr(this.featured.id).length > 0) {
        Column({ space: 12 }) {
          this.sectionTitle('✍️', 'book_sec_editor')
          Row({ space: 12 }) {
            BookCover({ item: this.featured, coverWidth: 72, coverHeight: 96 })
            Column({ space: 6 }) {
              Text(mallStr(this.featured.title))
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')
                .maxLines(2)
              Text(mallStr(this.featured.subtitle).length > 0 ? mallStr(this.featured.subtitle) :
                mallStr(this.featured.quoteText))
                .fontSize(12)
                .fontColor('#64748B')
                .maxLines(2)
              Text(I18n.tf('book_readers', this.formatCount(mallNum(this.featured.viewCount)), this.lang))
                .fontSize(11)
                .fontColor('#94A3B8')
              Row() {
                Text(I18n.t('book_view_detail', this.lang))
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#2563EB')
                  .borderRadius(14)
              }
              .onClick(() => this.openReader(this.featured))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 24 })
  }

  @Builder
  bookCell(item: BookItem) {
    Row({ space: 10 }) {
      BookCover({ item: item, coverWidth: 56, coverHeight: 74 })
      Column({ space: 4 }) {
        Text(mallStr(item.title))
          .fontSize(13)
          .fontColor('#0F172A')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(I18n.tf('book_readers', this.formatCount(mallNum(item.viewCount)), this.lang))
          .fontSize(10)
          .fontColor('#94A3B8')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .onClick(() => this.openReader(item))
  }

  @Builder
  categoryBody() {
    Row() {
      List() {
        ForEach(this.cats, (cat: BookCategory) => {
          ListItem() {
            Text(mallStr(cat.name))
              .fontSize(13)
              .fontColor(this.catId === mallStr(cat.id) ? '#2563EB' : '#64748B')
              .fontWeight(this.catId === mallStr(cat.id) ? FontWeight.Medium : FontWeight.Regular)
              .width('100%')
              .padding({ left: 10, right: 10, top: 12, bottom: 12 })
              .backgroundColor(this.catId === mallStr(cat.id) ? '#EFF6FF' : '#00000000')
              .onClick(() => this.selectCat(mallStr(cat.id)))
          }
        }, (cat: BookCategory) => mallStr(cat.id))
      }
      .width(96)
      .height('100%')
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Start)
      .backgroundColor('#FFFFFF')

      List() {
        ForEach(this.catBooks, (b: BookItem) => {
          ListItem() {
            Row({ space: 12 }) {
              BookCover({ item: b, coverWidth: 56, coverHeight: 74 })
              Column({ space: 4 }) {
                Text(mallStr(b.title))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#0F172A')
                  .maxLines(2)
                Text(mallStr(b.authorName))
                  .fontSize(12)
                  .fontColor('#94A3B8')
                Text(I18n.tf('book_readers', this.formatCount(mallNum(b.viewCount)), this.lang))
                  .fontSize(11)
                  .fontColor('#94A3B8')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .onClick(() => this.openReader(b))
          }
        }, (b: BookItem) => mallStr(b.id))
      }
      .layoutWeight(1)
      .height('100%')
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  rankBody() {
    Column({ space: 8 }) {
      ForEach(this.rankList, (b: BookItem, index: number) => {
        Row({ space: 12 }) {
          Text(`${index + 1}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(index < 3 ? '#EF4444' : '#94A3B8')
            .width(28)
          BookCover({ item: b, coverWidth: 48, coverHeight: 64 })
          Column({ space: 4 }) {
            Text(mallStr(b.title))
              .fontSize(14)
              .fontColor('#0F172A')
              .maxLines(2)
            Text(I18n.tf('book_readers', this.formatCount(mallNum(b.viewCount)), this.lang))
              .fontSize(11)
              .fontColor('#94A3B8')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .onClick(() => this.openReader(b))
      }, (b: BookItem) => mallStr(b.id))
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 24 })
  }

  @Builder
  shelfBody() {
    Column({ space: 12 }) {
      if (this.shelfList.length === 0) {
        Text(I18n.t('book_shelf_empty', this.lang))
          .fontSize(13)
          .fontColor('#94A3B8')
          .padding({ top: 40 })
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        ForEach(this.shelfList, (b: BookItem) => {
          Row({ space: 12 }) {
            BookCover({ item: b, coverWidth: 56, coverHeight: 74 })
            Column({ space: 6 }) {
              Text(mallStr(b.title))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#0F172A')
              Text(I18n.t('book_continue', this.lang))
                .fontSize(12)
                .fontColor('#2563EB')
              if (mallNum(b.percent) > 0) {
                Text(`${mallNum(b.percent)}%`)
                  .fontSize(11)
                  .fontColor('#94A3B8')
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => this.openReader(b))
        }, (b: BookItem) => mallStr(b.id))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 24 })
  }

  @Builder
  bookTab(i: number, titleKey: string) {
    Column({ space: 4 }) {
      Text(I18n.t(titleKey, this.lang))
        .fontSize(14)
        .fontWeight(this.mainTab === i ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.mainTab === i ? '#2563EB' : '#64748B')
      Row()
        .width(20)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.mainTab === i ? '#2563EB' : '#00000000')
    }
    .layoutWeight(1)
    .padding({ top: 4, bottom: 4 })
    .onClick(() => this.switchTab(i))
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Row() {
          Text(I18n.t('tab_book', this.lang))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
            .layoutWeight(1)
          Text('🔍')
            .fontSize(20)
            .onClick(() => this.openSearch())
        }
        .width('100%')

        Row({ space: 8 }) {
          Text('🔍').fontSize(14)
          Text(I18n.t('book_search_ph', this.lang))
            .fontSize(13)
            .fontColor('#94A3B8')
            .layoutWeight(1)
        }
        .width('100%')
        .height(42)
        .padding({ left: 14, right: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(21)
        .onClick(() => this.openSearch())

        Row() {
          this.bookTab(0, 'book_tab_rec')
          this.bookTab(1, 'book_tab_cat')
          this.bookTab(2, 'book_tab_rank')
          // this.bookTab(3, 'book_tab_shelf')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36).color('#2563EB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.mainTab === 1) {
        this.categoryBody()
      } else {
        Scroll() {
          if (this.mainTab === 0) {
            this.recommendBody()
          } else if (this.mainTab === 2) {
            this.rankBody()
          } else {
            this.shelfBody()
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F6FB')
  }
}
