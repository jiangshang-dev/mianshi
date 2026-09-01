import { promptAction, router } from '@kit.ArkUI';
import { ChinaRegion } from '../../common/data/ChinaRegion';
import { I18n } from '../../common/i18n/I18n';
import {
  MallAddress,
  MallAddressBody,
  mallAddressLine,
  mallStr
} from '../../common/models/MallTypes';
import { MallRepository } from '../../data/repository/MallRepository';

interface MallAddressNav {
  pick?: string;
}

interface DialogResult {
  index: number;
}

@Entry
@Component
struct MallAddressPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private showForm: boolean = false;
  @State private saving: boolean = false;
  @State private list: MallAddress[] = [];
  @State private editId: string = '';
  @State private receiverName: string = '';
  @State private receiverPhone: string = '';
  @State private province: string = '';
  @State private city: string = '';
  @State private district: string = '';
  @State private detail: string = '';
  @State private isDefault: number = 0;
  @State private defaultOn: boolean = false;
  @State private provinceIndex: number = 0;
  @State private cityIndex: number = 0;
  @State private districtIndex: number = 0;
  @State private provinceOptions: SelectOption[] = [];
  @State private cityOptions: SelectOption[] = [];
  @State private districtOptions: SelectOption[] = [];
  private repo: MallRepository = MallRepository.getInstance();
  private pickMode: boolean = false;

  aboutToAppear(): void {
    const nav = router.getParams() as MallAddressNav;
    this.pickMode = nav !== undefined && nav.pick === '1';
    this.reload();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    try {
      this.list = await this.repo.addresses();
    } catch (err) {
      this.list = [];
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_load_fail', this.lang) });
    } finally {
      this.loading = false;
    }
  }

  private startAdd(): void {
    this.editId = '';
    this.receiverName = '';
    this.receiverPhone = '';
    this.province = '';
    this.city = '';
    this.district = '';
    this.detail = '';
    this.isDefault = this.list.length === 0 ? 1 : 0;
    this.defaultOn = this.isDefault === 1;
    this.refreshRegionOptions();
    this.showForm = true;
  }

  private startEdit(item: MallAddress): void {
    this.editId = mallStr(item.id);
    this.receiverName = mallStr(item.receiverName);
    this.receiverPhone = mallStr(item.receiverPhone);
    this.province = mallStr(item.province);
    this.city = mallStr(item.city);
    this.district = mallStr(item.district);
    this.detail = mallStr(item.detail);
    this.isDefault = item.isDefault === 1 ? 1 : 0;
    this.defaultOn = this.isDefault === 1;
    this.refreshRegionOptions();
    this.showForm = true;
  }

  private pick(item: MallAddress): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    MallRepository.setPickAddressId(id);
    if (this.pickMode) {
      router.back();
    }
  }

  private optionValue(options: SelectOption[], index: number): string {
    if (index <= 0 || index >= options.length) {
      return '';
    }
    return `${options[index].value}`;
  }

  private toSelectOptions(names: string[], current: string): SelectOption[] {
    const list: SelectOption[] = [];
    const placeholder: SelectOption = { value: I18n.t('mall_please_select', this.lang) };
    list.push(placeholder);
    let hasCurrent: boolean = current.length === 0;
    for (let i = 0; i < names.length; i++) {
      if (names[i] === current) {
        hasCurrent = true;
      }
    }
    if (current.length > 0 && !hasCurrent) {
      const extra: SelectOption = { value: current };
      list.push(extra);
    }
    for (let i = 0; i < names.length; i++) {
      const opt: SelectOption = { value: names[i] };
      list.push(opt);
    }
    return list;
  }

  private selectedIndex(options: SelectOption[], current: string): number {
    if (current.length === 0) {
      return 0;
    }
    for (let i = 0; i < options.length; i++) {
      if (`${options[i].value}` === current) {
        return i;
      }
    }
    return 0;
  }

  private refreshRegionOptions(): void {
    this.provinceOptions = this.toSelectOptions(ChinaRegion.provinces(), this.province);
    this.provinceIndex = this.selectedIndex(this.provinceOptions, this.province);
    this.cityOptions = this.toSelectOptions(ChinaRegion.cities(this.province), this.city);
    this.cityIndex = this.selectedIndex(this.cityOptions, this.city);
    this.districtOptions = this.toSelectOptions(ChinaRegion.districts(this.province, this.city), this.district);
    this.districtIndex = this.selectedIndex(this.districtOptions, this.district);
  }

  private onProvinceSelect(index: number): void {
    this.province = this.optionValue(this.provinceOptions, index);
    this.city = '';
    this.district = '';
    this.refreshRegionOptions();
  }

  private onCitySelect(index: number): void {
    this.city = this.optionValue(this.cityOptions, index);
    this.district = '';
    this.refreshRegionOptions();
  }

  private onDistrictSelect(index: number): void {
    this.district = this.optionValue(this.districtOptions, index);
    this.districtIndex = index;
  }

  private regionReady(): boolean {
    if (this.province.length === 0 || this.city.length === 0) {
      return false;
    }
    const districts: string[] = ChinaRegion.districts(this.province, this.city);
    if (districts.length === 0) {
      return true;
    }
    return this.district.length > 0;
  }

  private async save(): Promise<void> {
    if (this.receiverName.trim().length === 0 || this.receiverPhone.trim().length === 0 || this.detail.trim().length === 0
      || !this.regionReady()) {
      promptAction.showToast({ message: I18n.t('mall_addr_required', this.lang) });
      return;
    }
    this.saving = true;
    try {
      const body: MallAddressBody = {
        id: this.editId,
        receiverName: this.receiverName.trim(),
        receiverPhone: this.receiverPhone.trim(),
        province: this.province.trim(),
        city: this.city.trim(),
        district: this.district.trim(),
        detail: this.detail.trim(),
        isDefault: this.isDefault
      };
      const saved = await this.repo.saveAddress(body);
      MallRepository.setPickAddressId(mallStr(saved.id));
      this.showForm = false;
      await this.reload();
      promptAction.showToast({ message: I18n.t('mall_addr_saved', this.lang) });
    } catch (err) {
      promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_addr_fail', this.lang) });
    } finally {
      this.saving = false;
    }
  }

  private async remove(item: MallAddress): Promise<void> {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    promptAction.showDialog({
      title: I18n.t('mall_addr_del', this.lang),
      message: I18n.t('mall_addr_del_msg', this.lang),
      buttons: [
        { text: I18n.t('cancel', this.lang), color: '#6B7280' },
        { text: I18n.t('delete', this.lang), color: '#DC2626' }
      ]
    }).then(async (res: DialogResult) => {
      if (res.index !== 1) {
        return;
      }
      try {
        await this.repo.deleteAddress(id);
        await this.reload();
      } catch (err) {
        promptAction.showToast({ message: err instanceof Error ? err.message : I18n.t('mall_addr_fail', this.lang) });
      }
    }).catch(() => {
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => {
            if (this.showForm) {
              this.showForm = false;
            } else {
              router.back();
            }
          })
        Text(this.showForm ? I18n.t('mall_addr_edit', this.lang) : I18n.t('mall_address', this.lang))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (!this.showForm) {
          Text(I18n.t('mall_addr_add', this.lang))
            .fontSize(13)
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              this.startAdd();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading && !this.showForm) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.showForm) {
        Scroll() {
          Column({ space: 10 }) {
            this.field(I18n.t('mall_recv_name', this.lang), this.receiverName, (v: string) => {
              this.receiverName = v;
            })
            this.field(I18n.t('mall_recv_phone', this.lang), this.receiverPhone, (v: string) => {
              this.receiverPhone = v;
            })
            this.selectField(I18n.t('mall_province', this.lang), this.provinceOptions, this.provinceIndex, (index: number) => {
              this.onProvinceSelect(index);
            })
            this.selectField(I18n.t('mall_city', this.lang), this.cityOptions, this.cityIndex, (index: number) => {
              this.onCitySelect(index);
            })
            this.selectField(I18n.t('mall_district', this.lang), this.districtOptions, this.districtIndex, (index: number) => {
              this.onDistrictSelect(index);
            })
            this.field(I18n.t('mall_detail_addr', this.lang), this.detail, (v: string) => {
              this.detail = v;
            })
            Row() {
              Text(I18n.t('mall_default_addr', this.lang))
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.defaultOn })
                .selectedColor('#2563EB')
                .onChange((on: boolean) => {
                  this.defaultOn = on;
                  this.isDefault = on ? 1 : 0;
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            Button(this.saving ? I18n.t('mall_submitting', this.lang) : I18n.t('mall_save', this.lang))
              .width('100%')
              .height(44)
              .backgroundColor('#2563EB')
              .enabled(!this.saving)
              .onClick(() => {
                this.save();
              })
          }
          .padding({ left: 16, right: 16, bottom: 32 })
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
      } else if (this.list.length === 0) {
        Column({ space: 12 }) {
          Text(I18n.t('mall_addr_empty', this.lang)).fontSize(14).fontColor($r('app.color.text_muted'))
          Button(I18n.t('mall_addr_add', this.lang))
            .width(140)
            .height(40)
            .backgroundColor('#2563EB')
            .onClick(() => {
              this.startAdd();
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.list, (item: MallAddress) => {
            ListItem() {
              Column({ space: 6 }) {
                Row() {
                  Text(`${mallStr(item.receiverName)}  ${mallStr(item.receiverPhone)}`)
                    .fontSize(15)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  if (item.isDefault === 1) {
                    Text(I18n.t('mall_default', this.lang))
                      .fontSize(11)
                      .fontColor('#CF0A2C')
                  }
                }
                .width('100%')
                Text(mallAddressLine(item))
                  .fontSize(13)
                  .fontColor($r('app.color.text_muted'))
                  .width('100%')
                Row({ space: 16 }) {
                  Text(I18n.t('mall_edit', this.lang))
                    .fontSize(13)
                    .fontColor($r('app.color.accent'))
                    .onClick(() => {
                      this.startEdit(item);
                    })
                  Text(I18n.t('delete', this.lang))
                    .fontSize(13)
                    .fontColor('#DC2626')
                    .onClick(() => {
                      this.remove(item);
                    })
                  if (this.pickMode) {
                    Text(I18n.t('mall_use_addr', this.lang))
                      .fontSize(13)
                      .fontColor($r('app.color.accent'))
                      .onClick(() => {
                        this.pick(item);
                      })
                  }
                }
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .onClick(() => {
                if (this.pickMode) {
                  this.pick(item);
                }
              })
            }
          }, (item: MallAddress) => mallStr(item.id))
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  field(label: string, value: string, onChange: (v: string) => void) {
    Column({ space: 4 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
      TextInput({ text: value, placeholder: label })
        .height(44)
        .backgroundColor($r('app.color.card_bg'))
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_muted'))
        .onChange((v: string) => {
          onChange(v);
        })
    }
    .width('100%')
  }

  @Builder
  selectField(label: string, options: SelectOption[], selected: number, onSelect: (index: number) => void) {
    Column({ space: 4 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_muted')).width('100%')
      Select(options)
        .selected(selected)
        .value(this.optionValue(options, selected).length > 0 ? this.optionValue(options, selected) : I18n.t('mall_please_select', this.lang))
        .font({ size: 16 })
        .fontColor($r('app.color.text_primary'))
        .selectedOptionFont({ size: 16 })
        .optionFont({ size: 16 })
        .width('100%')
        .height(44)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(8)
        .onSelect((index: number) => {
          onSelect(index);
        })
    }
    .width('100%')
  }
}
