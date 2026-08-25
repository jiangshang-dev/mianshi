import { AppConfig } from '../common/constants/AppConfig';

@Component
export struct CategoryIcon {
  @Prop icon: string = '📘';
  @Prop iconSize: number = 28;

  private isImageIcon(): boolean {
    const value = this.icon;
    if (!value) {
      return false;
    }
    return value.indexOf('/') >= 0
      || value.indexOf('http://') === 0
      || value.indexOf('https://') === 0
      || value.indexOf('.png') >= 0
      || value.indexOf('.jpg') >= 0
      || value.indexOf('.jpeg') >= 0
      || value.indexOf('.gif') >= 0
      || value.indexOf('.webp') >= 0
      || value.indexOf('.svg') >= 0;
  }

  private iconSrc(): string {
    if (this.icon.indexOf('http://') === 0 || this.icon.indexOf('https://') === 0) {
      return this.icon;
    }
    let path = this.icon;
    if (path.indexOf('/') === 0) {
      path = path.substring(1);
    }
    return `${AppConfig.REMOTE_API_BASE}/sys/common/static/${path}`;
  }

  build() {
    if (this.isImageIcon()) {
      Image(this.iconSrc())
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain)
        .borderRadius(4)
    } else {
      Text(this.icon || '📘')
        .fontSize(this.iconSize)
    }
  }
}
