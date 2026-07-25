# 🛠 V-Dock "DevTools" Edition: Detailed Implementation Plan

Dokumen ini berisi cetak biru (blueprint) teknis untuk mengevolusi V-Dock dari sekadar "Device Manager" menjadi "Universal Mobile DevTools" yang bekerja di level OS dan mendukung *framework* apa pun (Flutter, React Native, KMP, Swift, Kotlin).

---

## 1. 🌐 V-Dock Network Sniffer (Mini Proxyman)
Mencegat dan menampilkan lalu lintas HTTP/HTTPS dari emulator ke dalam UI V-Dock.

### **Fase 1: Local HTTP Proxy Server**
- **Konsep:** Membuat server proksi lokal HTTP ringan di macOS (berjalan di *background* `localhost:8080`).
- **Implementasi:**
  - Menggunakan *library* bawaan `Network` framework (NWListener) milik Apple atau SwiftNIO.
  - Proxy akan membaca *Request* yang masuk, meneruskannya ke internet, lalu mengembalikan *Response* ke emulator sembari mencatat datanya ke dalam memori V-Dock.

### **Fase 2: Emulator Traffic Routing**
- **Android:** Menyuntikkan konfigurasi via ADB saat perangkat *boot* atau via *shell*:
  `adb shell settings put global http_proxy 10.0.2.2:8080` (10.0.2.2 adalah localhost Mac dari sudut pandang emulator).
- **iOS:** Sedikit lebih rumit. Bisa menggunakan konfigurasi proksi via `.mobileconfig` yang di-*install* otomatis via `simctl`.

### **Fase 3: Network UI View**
- Membuat `NetworkInspectorView.swift`.
- Memiliki desain tiga panel:
  - *Kiri:* Daftar URL API (berwarna Hijau 200, Merah 500).
  - *Kanan Atas:* Detail Request (Headers, Params, Body JSON).
  - *Kanan Bawah:* Detail Response (Headers, Body JSON yang sudah di-*format* rapi).

---

## 2. 🗄️ Sandbox Data Explorer (Inspektur File Lokal)
Mengekstrak dan melihat isi *file* lokal aplikasi (`.sqlite`, JSON, SharedPreferences).

### **Fase 1: Ekstraksi Data Otomatis**
- Menggunakan `Target Bundle ID / Package Name` dari *Settings*.
- **Android:** Menggunakan perintah `adb shell run-as com.target.app tar -cf - /data/data/com.target.app | tar -xvf - -C ~/Desktop/VDockSandbox` untuk mengekstrak folder terlindungi.
- **iOS:** Menggunakan `xcrun simctl get_app_container <device_id> <bundle_id> data` untuk mendapatkan alamat absolut folder di Finder.

### **Fase 2: File Tree UI View**
- Membuat `SandboxExplorerView.swift`.
- Membangun hierarki folder secara visual layaknya Finder menggunakan `OutlineGroup` di SwiftUI.
- Jika pengguna mengklik file berakhiran `.json` atau `.xml`, V-Dock otomatis membacanya sebagai teks di panel kanan.

---

## 3. 📉 Universal UI Jank Profiler (Pemantau FPS Layar)
Melacak performa animasi UI secara *real-time* untuk mendeteksi *lag*.

### **Fase 1: Data Gathering (Polling)**
- **Android:** Menjalankan perintah `adb shell dumpsys gfxinfo <package_name>` secara berulang setiap 2 detik di *background task*. Membaca nilai *Janky frames* dan *99th percentile*.
- **iOS:** Memerlukan intervensi via Instruments CLI, atau secara alternatif menggunakan pemantauan CPU spesifik aplikasi via `xcrun simctl spawn`.

### **Fase 2: Visualisasi Grafik**
- Membuat `PerformanceJankView.swift`.
- Menggunakan **SwiftUI Charts** (diperkenalkan di macOS 13) untuk membuat grafik batang hijau (lancar) dan batang merah (jank/drop frame) yang bergerak dinamis.

---

## 4. 🧲 Intent & Deep Link Tester
Uji tautan cepat dari Menu Bar.

### **Fase 1: Eksekusi Shell**
- Membuat UI `DeepLinkPopoverView.swift` dengan sebuah `TextField` dan tombol "Send".
- **Eksekusi iOS:** `xcrun simctl openurl <device_id> "myapp://promo/123"`
- **Eksekusi Android:** `adb -s <device_id> shell am start -W -a android.intent.action.VIEW -d "myapp://promo/123"`

### **Fase 2: History & Favorites**
- Menyimpan riwayat tautan (URL) yang pernah diketikkan pengguna di `UserDefaults` sehingga *developer* tidak perlu mengetik ulang *deep link* yang sangat panjang setiap hari.

---

## 5. 🛠 Unified Smart Console (Evolusi Logcat)
Meningkatkan Logcat saat ini agar mengenali format struktur data.

### **Fase 1: Regex & JSON Parser**
- Mencegat keluaran dari `ShellExecutor.stream`.
- Memasang algoritma *Regular Expression* (Regex) untuk mendeteksi string yang diawali dengan `{` dan diakhiri dengan `}` pada setiap baris log.
- Jika baris tersebut adalah JSON yang sah (valid), ubah baris tersebut menjadi tipe data objek.

### **Fase 2: Collapsible JSON UI**
- Di `LogcatView.swift`, jika log berjenis JSON, tampilkan ikon panah kecil (▶).
- Saat diklik, rentangkan JSON tersebut ke bawah (berformat *pretty-print* warna-warni) agar mudah dibaca, alih-alih berdesak-desakan dalam satu baris.

---
**Rekomendasi Urutan Eksekusi:**
Disarankan untuk mengeksekusi **Deep Link Tester** terlebih dahulu (paling cepat diimplementasikan dan bernilai tinggi), lalu disusul oleh perombakan **Unified Smart Console**, dan diakhiri dengan **Network Sniffer** sebagai proyek *masterpiece*.
