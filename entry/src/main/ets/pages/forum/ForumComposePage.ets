import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { ForumCategory, ForumDraftImage } from '../../common/models/ForumTypes';
import { mallStr } from '../../common/models/MallTypes';
import { ForumRepository } from '../../data/repository/ForumRepository';

interface ForumComposeParams {
  categoryId?: string;
}

@Entry
@Component
struct ForumComposePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private catId: string = '';
  @State private cats: ForumCategory[] = [];
  @State private content: string = '';
  @State private images: ForumDraftImage[] = [];
  @State private sending: boolean = false;
  @State private picking: boolean = false;
  private repo: ForumRepository = ForumRepository.getInstance();
  private seq: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ForumComposeParams;
    if (params !== undefined && params.categoryId !== undefined && params.categoryId !== 'all') {
      this.catId = params.categoryId;
    }
    this.loadCats();
  }

  private async loadCats(): Promise<void> {
    try {
      const cats = await this.repo.categories();
      this.cats = cats;
      this.ensureCat(cats);
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('forum_load_fail', this.lang) });
    }
  }

  private ensureCat(cats: ForumCategory[]): void {
    if (this.catId.length > 0) {
      for (let i = 0; i < cats.length; i++) {
        if (mallStr(cats[i].id) === this.catId) {
          return;
        }
      }
    }
    if (cats.length > 0) {
      this.catId = mallStr(cats[0].id);
    }
  }

  private selectCat(id: string): void {
    if (this.sending) {
      return;
    }
    this.catId = id;
  }

  private pickImages(): void {
    if (this.picking || this.sending) {
      return;
    }
    const remain = 9 - this.images.length;
    if (remain <= 0) {
      promptAction.showToast({ message: I18n.t('forum_img_max', this.lang) });
      return;
    }
    this.picking = true;
    this.doPick(remain).catch((err: Error) => {
      promptAction.showToast({ message: err.message });
    }).then(() => {
      this.picking = false;
    });
  }

  private async doPick(remain: number): Promise<void> {
    const options = new picker.PhotoSelectOptions();
    options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = remain;
    const photoPicker = new picker.PhotoViewPicker();
    const result = await photoPicker.select(options);
    const uris = result.photoUris;
    if (uris === undefined || uris.length === 0) {
      return;
    }
    const ctx = getContext(this) as common.UIAbilityContext;
    for (let i = 0; i < uris.length; i++) {
      if (this.images.length >= 9) {
        break;
      }
      const uri = uris[i];
      this.seq = this.seq + 1;
      const key = `img-${this.seq}`;
      const dest = `${ctx.cacheDir}/forum_${this.seq}.jpg`;
      const copied = this.copyUri(uri, dest);
      const local = copied ? dest : uri;
      const draft: ForumDraftImage = { key: key, preview: uri, url: '' };
      const next: ForumDraftImage[] = [];
      for (let j = 0; j < this.images.length; j++) {
        next.push(this.images[j]);
      }
      next.push(draft);
      this.images = next;
      try {
        const url = await this.repo.uploadImage(local, `forum_${this.seq}.jpg`);
        this.patchImage(key, url);
      } catch (err) {
        this.removeImage(key);
        promptAction.showToast({
          message: err instanceof Error ? err.message : I18n.t('forum_pick_fail', this.lang)
        });
      }
    }
  }

  private copyUri(uri: string, dest: string): boolean {
    try {
      const srcFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      try {
        const stat = fileIo.statSync(srcFile.fd);
        if (stat.size <= 0 || stat.size > 8 * 1024 * 1024) {
          return false;
        }
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(srcFile.fd, buffer);
        const destFile = fileIo.openSync(dest,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(destFile.fd, buffer);
        } finally {
          fileIo.closeSync(destFile);
        }
      } finally {
        fileIo.closeSync(srcFile);
      }
      return true;
    } catch (_e) {
      return false;
    }
  }

  private patchImage(key: string, url: string): void {
    const next: ForumDraftImage[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const row = this.images[i];
      if (row.key === key) {
        const updated: ForumDraftImage = { key: row.key, preview: row.preview, url: url };
        next.push(updated);
      } else {
        next.push(row);
      }
    }
    this.images = next;
  }

  private removeImage(key: string): void {
    const next: ForumDraftImage[] = [];
    for (let i = 0; i < this.images.length; i++) {
      if (this.images[i].key !== key) {
        next.push(this.images[i]);
      }
    }
    this.images = next;
  }

  private pendingUpload(): boolean {
    for (let i = 0; i < this.images.length; i++) {
      if (mallStr(this.images[i].url).length === 0) {
        return true;
      }
    }
    return false;
  }

  private imageUrls(): string[] {
    const urls: string[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const url = mallStr(this.images[i].url);
      if (url.length > 0) {
        urls.push(url);
      }
    }
    return urls;
  }

  private publish(): void {
    if (this.sending) {
      return;
    }
    const text = this.content.trim();
    if (text.length === 0) {
      promptAction.showToast({ message: I18n.t('forum_need_content', this.lang) });
      return;
    }
    if (this.catId.length === 0) {
      promptAction.showToast({ message: I18n.t('forum_load_fail', this.lang) });
      return;
    }
    if (this.pendingUpload()) {
      promptAction.showToast({ message: I18n.t('forum_uploading', this.lang) });
      return;
    }
    this.sending = true;
    this.repo.createPost(this.catId, '', text, this.imageUrls()).then((post) => {
      const hint = mallStr(post.rejectHint);
      const pts = post.postPoints !== undefined ? post.postPoints : 0;
      if (hint.length > 0) {
        promptAction.showToast({ message: hint });
      } else if (pts > 0) {
        promptAction.showToast({ message: I18n.tf('blog_read_pts', `${pts}`, this.lang) });
      }
      const id = mallStr(post.id);
      ForumRepository.bumpList();
      router.replaceUrl({
        url: 'pages/forum/ForumDetailPage',
        params: { 'postId': id }
      });
    }).catch((err: Error) => {
      promptAction.showToast({ message: err.message });
    }).then(() => {
      this.sending = false;
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .width(36)
          .onClick(() => router.back())
        Text(I18n.t('forum_compose_title', this.lang))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Column() {
          if (this.sending) {
            Row({ space: 4 }) {
              LoadingProgress().width(14).height(14).color(Color.White)
              Text(I18n.t('forum_publishing', this.lang))
                .fontSize(14)
                .fontColor(Color.White)
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#93C5FD')
            .borderRadius(16)
          } else {
            Text(I18n.t('forum_publish', this.lang))
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.accent'))
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .borderRadius(16)
              .onClick(() => this.publish())
          }
        }
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 10, bottom: 8 })

      if (this.cats.length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.cats, (cat: ForumCategory) => {
              Text(mallStr(cat.name))
                .fontSize(13)
                .fontColor(this.catId === mallStr(cat.id) ? $r('app.color.text_on_color') : $r('app.color.text_primary'))
                .backgroundColor(this.catId === mallStr(cat.id) ? $r('app.color.accent') : $r('app.color.chip_idle_bg'))
                .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                .borderRadius(14)
                .onClick(() => this.selectCat(mallStr(cat.id)))
            }, (cat: ForumCategory) => mallStr(cat.id))
          }
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .width('100%')
        .height(36)
      }

      TextArea({ placeholder: I18n.t('forum_content_ph', this.lang), text: this.content })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .padding({ left: 16, right: 16 })
        .onChange((v: string) => {
          this.content = v;
        })

      Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
        ForEach(this.images, (item: ForumDraftImage) => {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(item.preview)
              .width(96)
              .height(96)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
            if (mallStr(item.url).length === 0) {
              Column() {
                LoadingProgress().width(22).height(22)
              }
              .width(96)
              .height(96)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#66000000')
              .borderRadius(10)
            }
            Text('×')
              .fontSize(13)
              .fontColor(Color.White)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .backgroundColor('#99000000')
              .borderRadius(10)
              .margin({ top: 4, right: 4 })
              .onClick(() => this.removeImage(item.key))
          }
          .width(96)
          .height(96)
          .margin({ right: 10, bottom: 10 })
        }, (item: ForumDraftImage) => `${item.key}-${mallStr(item.url)}`)

        if (this.images.length < 9) {
          Column({ space: 6 }) {
            Text('🖼').fontSize(26)
            Text(I18n.t('forum_add_image', this.lang))
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
          }
          .width(96)
          .height(96)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.chip_idle_bg'))
          .borderRadius(10)
          .border({ width: 1, color: $r('app.color.divider'), style: BorderStyle.Dashed })
          .margin({ right: 10, bottom: 10 })
          .onClick(() => this.pickImages())
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
