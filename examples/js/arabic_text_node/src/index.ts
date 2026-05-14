import {
  toSearchKey,
  toLooseSearchKey,
  toSlug,
  sort,
} from '@devsamhan/arabic-text';

const names = ['فَاطِمَةُ العلي', 'مُحَمَّد أحمد', 'إبراهيم السالم'];
const query = 'فاطمه';

const results = names.filter((name) =>
  toLooseSearchKey(name).includes(toLooseSearchKey(query)),
);

console.log('نتائج البحث:', results);
console.log('مفتاح البحث:', toSearchKey('مُحَمَّدٌ'));
console.log('slug:', toSlug('مدرسة الأمل'));
console.log('مرتبة:', sort(names));
