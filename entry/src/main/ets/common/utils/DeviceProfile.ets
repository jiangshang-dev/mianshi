import { deviceInfo } from '@kit.BasicServicesKit';

export class DeviceProfile {
  static loginDevice(): string {
    try {
      const market = deviceInfo.marketName;
      if (market !== undefined && market.length > 0) {
        return market;
      }
      const model = deviceInfo.productModel;
      if (model !== undefined && model.length > 0) {
        return model;
      }
      const brand = deviceInfo.brand;
      if (brand !== undefined && brand.length > 0) {
        return brand;
      }
    } catch (_e) {
    }
    return 'HarmonyOS';
  }
}
