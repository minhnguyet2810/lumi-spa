require('dotenv').config();
const db = require('../firebase');
(async () => {
  for (const collection of ['products', 'services']) {
    const snapshot = await db.collection(collection).get();
    const rows = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const values = [data.imageUrl, data.imageUrls, data.images, data.image, data.thumbnailUrl, data.thumbnail, data.coverImageUrl, data.photoUrl];
      function hasUrl(value) {
        if (typeof value === 'string') return /^(https?:)?\/\//i.test(value.trim());
        if (Array.isArray(value)) return value.some(hasUrl);
        if (value && typeof value === 'object') return ['url','downloadUrl','imageUrl','src'].some(key => hasUrl(value[key]));
        return false;
      }
      if (!values.some(hasUrl)) rows.push({id: doc.id, name: data.name || '(no name)', issue: 'No usable image URL'});
    }
    console.log(collection + ': ' + rows.length + ' items missing image URLs');
    console.table(rows);
  }
  process.exit(0);
})().catch(error => { console.error(error.message); process.exit(1); });
