import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BookCategory, BookItem } from '../../common/models/BookTypes';
import { mallStr } from '../../common/models/MallTypes';
import { BookCover } from '../../components/BookCover';
import { BookRepository } from '../../data/repository/BookRepository';

interface BookRow {
  a: BookItem;
  b: BookItem;
  hasB: boolean;
  key: string;
}

@Component
export struct BookPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private cats: BookCategory[] = [];
  @State private catId: string = '';
  @State private list: BookItem[] = [];
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
      this.cats = await this.repo.categories();
      if (this.catId.length === 0 && this.cats.length > 0) {
        this.catId = mallStr(this.cats[0].id);
      }
      await this.loadBooks();
    } catch (_e) {
      this.cats = [];
      this.list = [];
    } finally {
      this.loading = false;
    }
  }

  private async loadBooks(): Promise<void> {
    const page = await this.repo.list('', this.catId, 1);
    this.list = page.records !== undefined ? page.records : [];
  }

  private selectCat(id: string): void {
    this.catId = id;
    this.loadBooks();
  }

  private openReader(item: BookItem): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/book/BookReaderPage',
      params: { 'id': id }
    });
  }

  private currentCat(): BookCategory {
    for (let i = 0; i < this.cats.length; i++) {
      if (mallStr(this.cats[i].id) === this.catId) {
        return this.cats[i];
      }
    }
    const empty: BookCategory = {};
    return empty;
  }

  private catName(): string {
    const name = mallStr(this.currentCat().name);
    return name.length > 0 ? name : '…';
  }

  private catIntro(): string {
    const intro = mallStr(this.currentCat().intro);
    if (intro.length > 0) {
      return intro;
    }
    return I18n.t('book_lib_intro', this.lang);
  }

  private catIcon(cat: BookCategory): string {
    const icon = mallStr(cat.icon);
    return icon.length > 0 ? icon : '📘';
  }

  private authorText(item: BookItem): string {
    const name = mallStr(item.authorName);
    if (name.length === 0) {
      return '';
    }
    return I18n.tf('book_author_suf', name, this.lang);
  }

  private rows(): BookRow[] {
    const rows: BookRow[] = [];
    for (let i = 0; i < this.list.length; i += 2) {
      const row: BookRow = {
        a: this.list[i],
        b: i + 1 < this.list.length ? this.list[i + 1] : {},
        hasB: i + 1 < this.list.length,
        key: mallStr(this.list[i].id)
      };
      rows.push(row);
    }
    return rows;
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Row() {
          Column({ space: 4 }) {
            Text(I18n.t('tab_book', this.lang))
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')
            Text(I18n.t('book_lib_sub', this.lang))
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(I18n.t('book_lib_tip', this.lang))
            .fontSize(10)
            .fontColor('#93C5FD')
            .constraintSize({ maxWidth: 120 })
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })
      .backgroundColor('#F8FAFC')

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36).color('#2563EB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Scroll() {
            Column() {
              ForEach(this.cats, (cat: BookCategory) => {
                Column({ space: 4 }) {
                  Text(this.catIcon(cat)).fontSize(18)
                  Text(mallStr(cat.name))
                    .fontSize(11)
                    .fontColor(this.catId === mallStr(cat.id) ? '#2563EB' : '#64748B')
                    .fontWeight(this.catId === mallStr(cat.id) ? FontWeight.Medium : FontWeight.Regular)
                    .maxLines(1)
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
                .backgroundColor(this.catId === mallStr(cat.id) ? '#EFF6FF' : Color.Transparent)
                .border({
                  width: { left: this.catId === mallStr(cat.id) ? 3 : 0 },
                  color: '#2563EB'
                })
                .onClick(() => this.selectCat(mallStr(cat.id)))
              }, (cat: BookCategory) => mallStr(cat.id))
            }
            .width('100%')
          }
          .width(72)
          .height('100%')
          .scrollBar(BarState.Off)
          .backgroundColor('#FFFFFF')

          Column({ space: 10 }) {
            Column({ space: 4 }) {
              Text(`${this.catName()}${I18n.t('book_lib_books', this.lang)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')
              Text(this.catIntro())
                .fontSize(12)
                .fontColor('#94A3B8')
                .maxLines(2)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.list.length === 0) {
              Text(I18n.t('book_empty', this.lang))
                .fontSize(13)
                .fontColor('#94A3B8')
                .padding({ top: 40 })
                .width('100%')
                .textAlign(TextAlign.Center)
            } else {
              List({ space: 10 }) {
                ForEach(this.rows(), (row: BookRow) => {
                  ListItem() {
                    Row({ space: 8 }) {
                      this.bookCard(row.a)
                      if (row.hasB) {
                        this.bookCard(row.b)
                      } else {
                        Column().layoutWeight(1)
                      }
                    }
                    .width('100%')
                  }
                }, (row: BookRow) => row.key)
              }
              .layoutWeight(1)
              .width('100%')
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
            }
          }
          .layoutWeight(1)
          .height('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  bookCard(item: BookItem) {
    Column({ space: 6 }) {
      BookCover({ item: item, coverWidth: 72, coverHeight: 96 })
      Text(mallStr(item.title))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0F172A')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(this.authorText(item))
        .fontSize(10)
        .fontColor('#94A3B8')
        .maxLines(1)
        .width('100%')
      Row({ space: 4 }) {
        if (mallStr(item.tag).length > 0) {
          Text(mallStr(item.tag))
            .fontSize(9)
            .fontColor('#2563EB')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .backgroundColor('#DBEAFE')
            .borderRadius(6)
        }
        if (mallStr(item.categoryName).length > 0) {
          Text(mallStr(item.categoryName))
            .fontSize(9)
            .fontColor('#B45309')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .backgroundColor('#FEF3C7')
            .borderRadius(6)
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => this.openReader(item))
  }
}
