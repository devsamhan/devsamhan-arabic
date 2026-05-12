// @devsamhan/arabic-text — public API
// devsamhan-arabic spec v1.0.0

export { specVersion } from './normalize';
export {
  removeTashkeel,
  removeTatweel,
  normalizeAlef,
  normalizeHamza,
  normalizeYa,
  normalizeTaMarbouta,
  normalizePresentationForms,
  normalizeDigits,
  isArabic,
  arabicRatio,
} from './normalize';
export {
  toSearchKey,
  toLooseSearchKey,
  toDisplayKey,
  toSlug,
  normalizeName,
  toSortKey,
  sort,
  compare,
} from './presets';
