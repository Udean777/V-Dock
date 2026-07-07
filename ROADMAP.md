# 🚀 V-Dock: Future Features Roadmap

Dokumen ini berisi daftar ide dan rencana pengembangan fitur lanjutan untuk aplikasi **V-Dock**, yang dirancang untuk menjadikannya "Killer App" bagi para *Mobile Developer*.

---

## 1. 🧹 "Factory Reset" & Cold Boot (Pembersih Instan)
Seringkali *simulator* atau *emulator* mengalami *bug*, memori penuh, atau butuh pengujian dari layar *login* awal.
- **Konsep:** Menambahkan tombol "Erase Data & Settings" (untuk iOS) dan "Wipe Data / Cold Boot" (untuk Android) langsung di Dashboard.
- **Benefit:** Developer tidak perlu lagi membuka Xcode atau Android Studio hanya untuk mereset perangkat. Menghemat waktu secara signifikan.

## 2. 📸 Quick Screenshot & Screen Record
Mengambil aset gambar/video dari *emulator* biasanya cukup merepotkan jika harus menggunakan *shortcut* bawaan yang panjang.
- **Konsep:** Menambahkan ikon 📷 dan ⏺ di Menu Bar dan Dashboard. Sekali klik, *screenshot* atau rekaman layar dari *emulator* yang aktif akan langsung terambil dan otomatis tersimpan ke *Desktop* atau *Clipboard*.
- **Implementasi:** Menggunakan perintah shell `xcrun simctl io booted screenshot` dan `adb exec-out screencap`.

## 3. 🌙 Quick Toggles (Dark Mode & Network Throttling)
Developer sering perlu menguji UI aplikasi mereka dalam keadaan Mode Gelap atau koneksi internet lambat.
- **Konsep:** *Switch* (sakelar) cepat di samping nama *device* untuk langsung memaksakan status OS menjadi **Dark Mode** atau **Light Mode**, serta opsi *throttling* internet (misal: simulasi sinyal 3G atau EDGE).
- **Benefit:** Pengujian UI dan UX yang jauh lebih praktis tanpa harus mengobrak-abrik menu *Settings* di dalam OS simulator.

## 4. 📦 Drag & Drop APK / APP Installer
- **Konsep:** Modifikasi UI baris perangkat di Dashboard agar mendukung *DropTarget*. Jika developer menyeret *file* `.apk` (Android) atau `.app` (iOS) ke atas nama perangkat, V-Dock akan otomatis meng- *install* aplikasi tersebut di latar belakang.
- **Implementasi:** Menerapkan `.onDrop` di SwiftUI yang memanggil perintah `adb install` atau `xcrun simctl install`.

## 5. 🛠 Dedicated Logcat / Console Viewer View (Mini Logcat)
Menganalisis *crash* dan perilaku aplikasi seringkali mengharuskan developer membuka IDE raksasa.
- **Konsep:** Membuat sebuah *View* (jendela) baru dan terpisah yang dirancang dan didedikasikan 100% untuk membaca log terminal. 
- **Detail Implementasi Tambahan:**
  - **New Window:** Tidak menyatu dengan Dashboard, melainkan dibuka sebagai jendela terpisah (misalnya melalui jalan pintas `Cmd + L` atau tombol *Logs* di Menu Bar).
  - **Tail & Stream:** Menjalankan perintah `adb logcat` (Android) atau `xcrun simctl spawn log stream` (iOS) di latar belakang secara berkelanjutan (*continuous streaming*).
  - **Syntax Highlighting & Filtering:** Tampilan log yang dirancang khusus dengan warna berbeda (Merah untuk *Error*, Kuning untuk *Warning*) dan sebuah bilah pencarian (*search bar*) *real-time* di bagian atas untuk menyaring nama paket (*package name*) aplikasi tertentu.
  - **Auto-Scroll:** Otomatis bergulir ke bawah saat log baru masuk, dengan tombol "Clear" untuk membersihkan layar.
