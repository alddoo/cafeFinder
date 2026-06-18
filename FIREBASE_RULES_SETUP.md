# Cara Fix Firebase Rules

## LANGKAH 1 — Buka Firebase Console

Buka browser, masuk ke:
https://console.firebase.google.com/project/palembang-5f717/firestore/rules

## LANGKAH 2 — Ganti Rules Firestore

Hapus semua rules yang ada, paste ini:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

Klik **Publish** / **Publikasikan**

## LANGKAH 3 — Ganti Rules Storage (jika ada foto)

Buka:
https://console.firebase.google.com/project/palembang-5f717/storage/rules

Paste ini:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

Klik **Publish**

## LANGKAH 4 — Test lagi di app
