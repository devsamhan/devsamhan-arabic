from devsamhan_arabic_text import (
    to_search_key,
    to_loose_search_key,
    to_slug,
    sort_arabic,
)

names = ['فَاطِمَةُ العلي', 'مُحَمَّد أحمد', 'إبراهيم السالم']
query = 'فاطمه'

results = [
    name
    for name in names
    if to_loose_search_key(query) in to_loose_search_key(name)
]

print('نتائج البحث:', results)
print('مفتاح البحث:', to_search_key('مُحَمَّدٌ'))
print('slug:', to_slug('مدرسة الأمل'))
print('مرتبة:', sort_arabic(names))
