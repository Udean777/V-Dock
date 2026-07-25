# 🌐 V-Dock Network Sniffer: Full Implementation Plan

Dokumen ini berisi panduan teknis yang sangat mendalam (arsitektur, dependensi, dan *step-by-step* kode) untuk mengimplementasikan fitur **Mini Proxyman (Network Sniffer)** di dalam V-Dock.

---

## 🏗️ 1. Arsitektur & Teknologi

Kita akan menghindari penggunaan *third-party proxy server* (seperti *mitmproxy* atau *charles*) yang mengharuskan pengguna menginstal dependensi luar. Semuanya harus berjalan secara *native* di dalam proses V-Dock.

- **Bahasa:** Swift & Swift Concurrency (async/await).
- **Core Library:** Apple's `Network` framework (`NWListener`, `NWConnection`) atau secara alternatif `SwiftNIO` untuk performa *high-throughput*.
- **Konsep:**
  1. V-Dock menjalankan sebuah *Local HTTP Proxy Server* pada *port* tertentu (misalnya `8080`).
  2. Saat pengguna mengaktifkan "Network Sniffer" pada sebuah *Emulator/Simulator*, V-Dock menjalankan perintah *shell* (`adb shell` / `simctl`) untuk memaksa *device* tersebut menggunakan `localhost:8080` sebagai proksinya.
  3. Semua *Request* HTTP/HTTPS dari emulator akan masuk ke `NWListener` V-Dock.
  4. V-Dock mencatat (sniff) data tersebut ke dalam memori, lalu meneruskannya (forward) ke *server* tujuan yang asli.
  5. *Response* dari *server* asli kembali ke V-Dock, dicatat lagi, lalu diteruskan kembali ke emulator.

---

## 🛠️ 2. Langkah Implementasi (Tahap per Tahap)

### Step 1: Membuat Layer Domain (`NetworkSnifferUseCase.swift`)
- Definisikan model data untuk lalu lintas jaringan:
  ```swift
  struct NetworkTraffic: Identifiable, Sendable {
      let id: UUID
      let method: String // GET, POST
      let url: String
      let requestHeaders: [String: String]
      let requestBody: Data?
      var responseCode: Int?
      var responseHeaders: [String: String]?
      var responseBody: Data?
      var timestamp: Date
  }
  ```
- Buat sebuah `Protocol` dan implementasi `UseCase` untuk memulai dan menghentikan *server proxy* lokal, serta menyiarkan `AsyncStream<NetworkTraffic>` ke UI.

### Step 2: Membuat Layer Data (`LocalProxyServer.swift`)
- Gunakan `NWListener` dari Apple:
  ```swift
  import Network

  final class LocalProxyServer {
      private var listener: NWListener?
      // Logika untuk menerima koneksi masuk (NWConnection)
      // Logika untuk mengekstrak URL dari koneksi HTTP CONNECT (untuk HTTPS) atau host header.
      // Logika untuk membuat koneksi keluar (outbound) ke server asli.
  }
  ```
- **Tantangan Utama (HTTPS/SSL Pinning):** 
  - Jika aplikasi menggunakan HTTPS, lalu lintasnya dienkripsi (*encrypted*).
  - V-Dock tidak bisa membaca isinya kecuali V-Dock bertindak sebagai *Man-In-The-Middle* (MITM) yang *generate* sertifikat SSL palsu (Root Certificate), yang kemudian harus di-*install* paksa ke dalam emulator pengguna.
  - *Untuk Fase 1 (MVP):* Kita mulai dengan mencegat HTTP biasa, atau hanya melihat *Host/Domain* yang dituju tanpa membaca *body* dari HTTPS.
  - *Untuk Fase 2:* Men- *generate* sertifikat Root CA lokal dengan `Security` framework Mac, menaruhnya di desktop, dan menjalankan `adb push` untuk menginstal sertifikat tersebut ke emulator agar HTTPS bisa dibaca.

### Step 3: Manipulasi Proxy di Device (`ShellExecutor.swift`)
Kita perlu merutekan lalu lintas *emulator* yang aktif ke *port* V-Dock.

**Untuk Android:**
```swift
// Mengaktifkan Proxy
try await shellExecutor.runDetached("adb", args: ["-s", deviceId, "shell", "settings", "put", "global", "http_proxy", "10.0.2.2:8080"])

// Mematikan Proxy (Reset)
try await shellExecutor.runDetached("adb", args: ["-s", deviceId, "shell", "settings", "put", "global", "http_proxy", ":0"])
```
*(Catatan: `10.0.2.2` adalah alamat IP khusus di Android Emulator yang merujuk ke mesin Host/Mac).*

**Untuk iOS:**
iOS Simulator tidak memiliki perintah `simctl` yang semudah Android untuk mengganti proxy secara instan.
- **Alternatif 1:** Menggunakan Apple Configurator CLI untuk memasang file `ProxyProfile.mobileconfig`.
- **Alternatif 2:** Memerintahkan pengguna untuk menyetel *HTTP Proxy* secara manual di menu *Settings -> Wi-Fi* pada Simulator iOS mereka (diarahkan ke `127.0.0.1:8080`), namun V-Dock akan mendeteksi lalu lintasnya secara otomatis.

### Step 4: Membangun Antarmuka UI (`NetworkSnifferView.swift`)
- Karena data jaringan bisa sangat masif, kita perlu membuat UI terpisah, bukan di dalam Menu Bar.
- **Desain Layout (Mirip Proxyman / Postman):**
  - **Sidebar (Kiri):** `List` dari `NetworkTraffic`. Setiap baris menunjukkan *Method* (GET/POST berwarna), Status Code (Hijau 200, Merah 500, Kuning 404), dan *Path URL*.
  - **Main Area (Kanan):** Terbagi dua (Atas dan Bawah).
    - **Top (Request):** Tab untuk melihat *Headers*, *Query Parameters*, dan *Body* (dengan JSON *syntax highlighter*).
    - **Bottom (Response):** Tab untuk melihat *Headers* balasan dan *Body Response* JSON.
- **Fitur Tambahan UI:**
  - *Search bar* untuk memfilter *URL endpoint* tertentu.
  - Tombol "Clear" sampah.
  - Tombol "Copy as cURL" untuk kemudahan *developer*.

### Step 5: Integrasi Context Menu di Menu Bar
- Di `DeviceCardView.swift`, tambahkan opsi baru: `🌐 Start Network Sniffer`.
- Saat diklik:
  1. V-Dock menjalankan `LocalProxyServer` di latar belakang (jika belum menyala).
  2. V-Dock menjalankan perintah Shell untuk mengubah setelan proksi di OS *emulator* (berdasarkan OS-nya).
  3. Membuka jendela `NetworkSnifferView` di Mac (mirip cara kita membuka `LogcatView`).

---

## ⚠️ Tantangan & Risiko Teknis
1. **SSL Decryption (MITM):** Jika *developer* hanya mengetes ke API dengan `https://`, kita akan mendapat data terenkripsi. Kita wajib mengembangkan fitur *Auto-Install Root Certificate* via `adb push` agar dekripsinya berjalan mulus tanpa intervensi manual pengguna.
2. **Kinerja Memori:** Mencegat file raksasa (misal: *download* video via emulator) bisa membuat V-Dock kehabisan memori. Kita harus membatasi perekaman *body response* (misalnya maksimal 2MB per *request*, sisanya ditandai *"Too large to display"*).
