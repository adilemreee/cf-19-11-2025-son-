# 🌥️ Cloudflared Manager

<div align="center">

![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-red.svg)

**Modern, kullanıcı dostu Cloudflare Tunnel yönetim uygulaması**

*Cloudflare tünellerinizi kolayca oluşturun, yönetin ve izleyin*

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Kullanım](#-kullanım) • [Katkıda Bulunma](#-katkıda-bulunma)

</div>

---

## 📖 **İçindekiler**

- [Genel Bakış](#-genel-bakış)
- [Özellikler](#-özellikler)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Kurulum](#-kurulum)
- [İlk Kurulum](#-ilk-kurulum)
- [Kullanım Kılavuzu](#-kullanım-kılavuzu)
- [Gelişmiş Özellikler](#-gelişmiş-özellikler)
- [Tema ve Kişiselleştirme](#-tema-ve-kişiselleştirme)
- [Sorun Giderme](#-sorun-giderme)
- [Sık Sorulan Sorular](#-sık-sorulan-sorular)
- [Teknik Detaylar](#-teknik-detaylar)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)
- [Teşekkürler](#-teşekkürler)

---

## 🎯 **Genel Bakış**

**Cloudflared Manager**, macOS için tasarlanmış modern bir Cloudflare Tunnel yönetim uygulamasıdır. SwiftUI ile geliştirilmiş bu uygulama, karmaşık tünel işlemlerini basit ve görsel bir arayüzle yönetmenizi sağlar.

### **Ne Yapar?**

- 🚀 **Hızlı Tünel Oluşturma**: Tek tıkla yeni tüneller oluşturun
- 🔧 **MAMP Entegrasyonu**: MAMP projelerinizi anında internete açın  
- ⚡ **Quick Tunnels**: Geçici tüneller için hızlı başlatma
- 🎨 **Modern UI**: Glassmorphism tasarım ve smooth animasyonlar
- 🌙 **Dark Mode**: Sistem teması ile otomatik uyum
- 📊 **Durum İzleme**: Tünel durumlarını gerçek zamanlı takip

---

## ✨ **Özellikler**

### 🎨 **Modern Kullanıcı Arayüzü**
- **Glassmorphism Design**: Şeffaf, modern cam efektli tasarım
- **Smooth Animations**: Yumuşak geçiş animasyonları
- **Interactive Elements**: 3D hover efektleri ve micro-interactions
- **Responsive Layout**: Farklı ekran boyutlarına uyumlu

### 🌙 **Tema Sistemi**
- **3 Tema Seçeneği**: Sistem, Açık, Koyu
- **11 Accent Color**: Mavi, Mor, Pembe, Kırmızı, Turuncu, Sarı, Yeşil, Nane, Deniz Yeşili, Cyan, İndigo
- **Gerçek Zamanlı Değişim**: Sistem tema değişikliklerini otomatik algılar
- **Persistent Settings**: Tema tercihleri otomatik kaydedilir

### 🔧 **Tünel Yönetimi**
- **Yönetilen Tüneller**: Cloudflare hesabınızda kalıcı tüneller
- **Hızlı Tüneller**: Geçici URL'ler için anlık tüneller
- **MAMP Entegrasyonu**: MAMP projelerinizi otomatik yapılandırma
- **Durum İzleme**: Tünellerin çalışma durumunu canlı takip

### ⚙️ **Gelişmiş Yapılandırma**
- **Custom Hostnames**: Özel domain isimleri
- **Port Management**: Esnek port yapılandırması
- **vHost Integration**: Apache sanal host otomatik güncellemesi
- **Config File Management**: YAML yapılandırma dosyası yönetimi

### 🎯 **Kullanıcı Deneyimi**
- **Menu Bar Integration**: Sistem menü çubuğundan hızlı erişim
- **Keyboard Shortcuts**: Hızlı işlemler için klavye kısayolları
- **Smart Notifications**: Akıllı bildirim sistemi
- **Error Handling**: Kullanıcı dostu hata yönetimi

---

## 💻 **Sistem Gereksinimleri**

### **Minimum Gereksinimler**
- **İşletim Sistemi**: macOS 12.0 (Monterey) veya üzeri
- **İşlemci**: Intel x64 veya Apple Silicon (M1/M2/M3)
- **RAM**: 4 GB (8 GB önerilen)
- **Disk Alanı**: 100 MB boş alan
- **İnternet**: Cloudflare API erişimi için aktif bağlantı

### **Önerilen Gereksinimler**
- **İşletim Sistemi**: macOS 13.0 (Ventura) veya üzeri
- **İşlemci**: Apple Silicon (M1/M2/M3)
- **RAM**: 8 GB veya üzeri
- **Disk Alanı**: 500 MB boş alan

### **Bağımlılıklar**
- **Cloudflared**: Cloudflare tünel client'ı
- **MAMP** (Opsiyonel): Web development stack
- **Cloudflare Account**: Tünel oluşturma için gerekli

---

## 🚀 **Kurulum**

### **Yöntem 1: Binary İndirme (Önerilen)**

1. **Release sayfasından indirin**:
   ```
   GitHub Releases → En son sürüm → Cloudflared-Manager.dmg
   ```

2. **DMG dosyasını açın** ve uygulamayı Applications klasörüne sürükleyin

3. **İlk çalıştırma**:
   - Applications → Cloudflared Manager
   - "Tanımlanamayan geliştirici" uyarısı alırsanız:
     - System Preferences → Security & Privacy → "Open Anyway"

### **Yöntem 2: Source Code'dan Derleme**

1. **Repository'yi klonlayın**:
   ```bash
   git clone https://github.com/yourusername/cloudflared-manager.git
   cd cloudflared-manager
   ```

2. **Xcode ile açın**:
   ```bash
   open sonprojeee.xcodeproj
   ```

3. **Derleyin ve çalıştırın**:
   - Xcode → Product → Run (⌘+R)

### **Yöntem 3: Homebrew (Gelecek sürümlerde)**
```bash
# Yakında eklenecek
brew install --cask cloudflared-manager
```

---

## ⚡ **İlk Kurulum**

### **1. Cloudflared Kurulumu**

Uygulama ilk çalıştırıldığında cloudflared binary'sinin yolunu belirtmeniz gerekir.

#### **Otomatik Kurulum (Önerilen)**:
```bash
# Homebrew ile
brew install cloudflare/cloudflare/cloudflared

# Manuel indirme
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz | tar -xzf -
sudo mv cloudflared /usr/local/bin/
```

#### **Yol Belirtme**:
1. Uygulama → Ayarlar → Genel
2. "Cloudflared Yürütülebilir Dosya Yolu" → Gözat
3. `/usr/local/bin/cloudflared` veya kurulum yolunu seçin

### **2. Cloudflare Hesabı Bağlantısı**

1. **Terminal'de giriş yapın**:
   ```bash
   cloudflared login
   ```

2. **Browser'da açılan sayfadan** domain'i seçin ve yetkilendirin

3. **Credentials dosyası** otomatik olarak `~/.cloudflared/` klasörüne kaydedilir

### **3. MAMP Kurulumu (Opsiyonel)**

MAMP entegrasyonu için:

1. **MAMP'ı indirin**: https://www.mamp.info/
2. **Varsayılan yola kurun**: `/Applications/MAMP`
3. **Uygulama ayarlarında** MAMP yolunu doğrulayın

---

## 📚 **Kullanım Kılavuzu**

### **🏠 Ana Ekran**

Uygulama açıldığında karşınıza çıkan ana ekran:

- **🌟 Logo ve Başlık**: Animasyonlu uygulama logosu
- **🎯 Özellik Kartları**: Ana işlevlere hızlı erişim
  - **Tünel Yönetimi**: Mevcut tünelleri görüntüle/yönet
  - **MAMP Entegrasyonu**: MAMP projelerini hızlıca paylaş
  - **Otomatik Yapılandırma**: Karmaşık ayarları otomatikleştir
- **✅ Durum Göstergesi**: Uygulama çalışma durumu

### **🔧 Yönetilen Tünel Oluşturma**

Kalıcı, yönetilen tüneller için:

1. **Menü Bar** → **Yeni Yönetilen Tünel**
2. **Tünel Bilgileri**:
   - **Tünel Adı**: Cloudflare'de görünecek benzersiz ad
   - **Config Dosya Adı**: Yerel yapılandırma dosyası adı
   - **Hostname**: Erişim URL'i (örn: myapp.example.com)
   - **Yerel Port**: Uygulamanızın çalıştığı port

3. **MAMP Entegrasyonu** (Opsiyonel):
   - **Proje Kök Dizini**: MAMP site klasörü
   - **vHost Güncellemesi**: Apache yapılandırmasını otomatik güncelle

4. **Tünel Oluştur** → Cloudflare'da tünel oluşturulur ve yapılandırma dosyası hazırlanır

### **⚡ Hızlı Tünel Başlatma**

Geçici URL'ler için:

1. **Menü Bar** → **Hızlı Tünel Başlat**
2. **URL Seçimi**:
   - **Hızlı Seçim**: Popüler development server'ları
     - React (localhost:3000)
     - Vue.js (localhost:8080)
     - Angular (localhost:4200)
     - Next.js (localhost:3000)
     - MAMP (localhost:8888)
   - **Özel URL**: Manuel URL girişi

3. **Tüneli Başlat** → Geçici URL oluşturulur ve menü barında görüntülenir

### **🌐 MAMP'tan Tünel Oluşturma**

MAMP projelerinizi hızlıca paylaşmak için:

1. **Menü Bar** → **MAMP'tan Tünel Oluştur**
2. **Site Seçimi**: MAMP sites klasöründeki projeler otomatik listelenir
3. **Otomatik Doldurma**: Site adına göre tünel bilgileri otomatik doldurulur
4. **Apache Entegrasyonu**: vHost dosyası otomatik güncellenir
5. **Tünel Oluştur** → Proje anında erişilebilir hale gelir

⚠️ **Önemli**: MAMP sunucularını yeniden başlatmayı unutmayın!

---

## 🎛️ **Gelişmiş Özellikler**

### **⚙️ Ayarlar Paneli**

Kapsamlı ayarlar paneline erişim:

#### **🔧 Genel Ayarlar**
- **Cloudflared Yapılandırması**:
  - Yürütülebilir dosya yolu
  - Durum kontrol aralığı (5-300 saniye)
- **Sistem Davranışı**:
  - Otomatik tünel başlatma
  - Sistem tepsisine küçültme
  - Durum çubuğunda gösterme
  - Oturum açıldığında başlatma

#### **📁 Yol Ayarları**
- **MAMP Yapılandırması**:
  - MAMP ana dizini
  - Apache config yolu
  - Sites dizini
  - vHost config dosyası
- **Python Proje Ayarları**:
  - Proje ana dizini
- **Hızlı Erişim**:
  - ~/.cloudflared dizini
  - Yapılandırma dosyaları

#### **🎨 Görünüm Ayarları**
- **Tema Seçimi**: Sistem / Açık / Koyu
- **Vurgu Rengi**: 11 farklı renk seçeneği
- **Arayüz Seçenekleri**: Gelecek güncellemelerde

#### **🔔 Bildirim Ayarları**
- **Bildirim Türleri**:
  - Tünel durumu bildirimleri
  - Hata bildirimleri
  - Başarı bildirimleri
- **Bildirim Yönetimi**: Etkinleştirme/devre dışı bırakma

#### **🔬 Gelişmiş Ayarlar**
- **Cloudflare İşlemleri**:
  - Hesap girişi
  - Tünel durumu kontrolü
- **Toplu İşlemler**:
  - Tümünü tara
  - Tümünü başlat/durdur
  - Ayarları sıfırla

#### **ℹ️ Hakkında**
- **Uygulama Bilgileri**:
  - Sürüm bilgisi
  - Geliştirici bilgileri
  - Sistem gereksinimleri
  - Son güncelleme tarihi

### **📊 Durum İzleme**

#### **Menü Bar Widget**
- **Tünel Durumları**: Çalışan tünellerin listesi
- **Hızlı İşlemler**: Başlat/durdur butonları
- **Durum İkonları**: Görsel durum göstergeleri
- **URL Kopyalama**: Tek tıkla URL kopyalama

#### **Durum Göstergeleri**
- 🟢 **Çalışıyor**: Tünel aktif ve erişilebilir
- 🔴 **Durduruldu**: Tünel kapalı
- 🟡 **Başlatılıyor**: Başlatma işlemi devam ediyor
- 🟠 **Durduruluyor**: Kapatma işlemi devam ediyor
- ❌ **Hata**: Tünelde sorun var

---

## 🎨 **Tema ve Kişiselleştirme**

### **🌙 Tema Sistemi**

#### **Tema Seçenekleri**
1. **Sistem**: macOS sistem temasını takip eder
2. **Açık**: Her zaman açık tema
3. **Koyu**: Her zaman koyu tema

#### **Otomatik Tema Değişimi**
- Sistem tema değişikliklerini otomatik algılar
- Uygulama yeniden başlatılmadan tema değişir
- Tüm pencereler tutarlı tema kullanır

### **🎨 Renk Kişiselleştirmesi**

#### **11 Accent Color Seçeneği**
- 🔵 **Mavi**: Varsayılan, güvenilir
- 🟣 **Mor**: Yaratıcı, modern
- 🩷 **Pembe**: Enerjik, canlı
- 🔴 **Kırmızı**: Güçlü, dikkat çekici
- 🟠 **Turuncu**: Sıcak, arkadaşça
- 🟡 **Sarı**: Neşeli, optimist
- 🟢 **Yeşil**: Doğal, sakin
- 🌿 **Nane**: Ferah, modern
- 🟦 **Deniz Yeşili**: Profesyonel, sakin
- 🔷 **Cyan**: Teknolojik, futuristik
- 🟦 **İndigo**: Derin, sofistike

#### **Tema Uygulama Alanları**
- Button'lar ve interactive elementler
- Progress bar'lar ve loading göstergeleri
- Icon'lar ve vurgu renkleri
- Border'lar ve outline'lar
- Shadow'lar ve glow efektleri

---

## 🔧 **Sorun Giderme**

### **❌ Yaygın Sorunlar ve Çözümleri**

#### **1. "Cloudflared bulunamadı" Hatası**
```
Sorun: Cloudflared binary dosyası bulunamıyor
Çözüm:
1. Terminal'de cloudflared kurulumunu kontrol edin:
   which cloudflared
2. Ayarlar → Genel → Cloudflared yolunu doğru ayarlayın
3. Gerekirse cloudflared'i yeniden kurun:
   brew install cloudflare/cloudflare/cloudflared
```

#### **2. "Login Required" Hatası**
```
Sorun: Cloudflare hesabına giriş yapılmamış
Çözüm:
1. Terminal'de giriş yapın:
   cloudflared login
2. Browser'da domain'i yetkilendirin
3. ~/.cloudflared/cert.pem dosyasının var olduğunu kontrol edin
```

#### **3. MAMP Entegrasyonu Çalışmıyor**
```
Sorun: MAMP yapılandırması güncellenmiyor
Çözüm:
1. MAMP yolunu kontrol edin: /Applications/MAMP
2. vHost dosyası yazma izinlerini kontrol edin
3. MAMP sunucularını yeniden başlatın
4. Apache error log'unu kontrol edin
```

#### **4. Tünel Oluşturulamıyor**
```
Sorun: Yeni tünel oluşturma başarısız
Çözüm:
1. İnternet bağlantısını kontrol edin
2. Cloudflare hesap limitlerini kontrol edin
3. Tünel adının benzersiz olduğundan emin olun
4. DNS ayarlarını kontrol edin
```

#### **5. Port Already in Use**
```
Sorun: Belirtilen port zaten kullanımda
Çözüm:
1. Farklı bir port deneyin
2. Çakışan uygulamayı kapatın:
   lsof -i :PORT_NUMBER
3. Process'i sonlandırın:
   kill -9 PID
```

### **🔍 Debug Modları**

#### **Verbose Logging**
```bash
# Detaylı log'lar için
cloudflared tunnel --loglevel debug run TUNNEL_NAME
```

#### **Config File Validation**
```bash
# Yapılandırma dosyasını kontrol et
cloudflared tunnel ingress validate ~/.cloudflared/CONFIG_NAME.yml
```

#### **Network Diagnostics**
```bash
# Ağ bağlantısını test et
cloudflared tunnel --loglevel debug login
```

---

## ❓ **Sık Sorulan Sorular**

### **🔧 Kurulum ve Yapılandırma**

**S: Cloudflared Manager'ı nasıl güncellerim?**
> A: Uygulama otomatik güncelleme kontrolü yapar. Yeni sürüm mevcut olduğunda bildirim alırsınız. Manuel kontrol için: Menü Bar → Hakkında → Güncellemeleri Kontrol Et

**S: Ayarlarım nerede saklanıyor?**
> A: Tüm ayarlar macOS UserDefaults sisteminde saklanır:
> - Tema tercihleri
> - Cloudflared yolu
> - MAMP ayarları
> - Bildirim tercihleri

**S: Uygulamayı tamamen kaldırmak istiyorum**
> A: 
> 1. Applications klasöründen uygulamayı silin
> 2. Terminal'de: `defaults delete com.yourcompany.CloudflaredManager`
> 3. ~/.cloudflared klasörünü kontrol edin (isteğe bağlı)

### **🌐 Tünel Yönetimi**

**S: Kaç tane tünel oluşturabilirim?**
> A: Cloudflare Free plan'da sınırsız tünel oluşturabilirsiniz, ancak eşzamanlı aktif tünel sayısında limitler olabilir.

**S: Tünelim çalışmıyor, nasıl test ederim?**
> A:
> 1. Menü Bar → Tünel Durumları → Durum kontrolü
> 2. Terminal'de: `cloudflared tunnel info TUNNEL_NAME`
> 3. Browser'da URL'i test edin
> 4. Local service'in çalıştığını kontrol edin

**S: Custom domain kullanabilir miyim?**
> A: Evet! Cloudflare'da domain'inizi ekledikten sonra, tünel oluştururken custom hostname belirtebilirsiniz.

**S: SSL sertifikası otomatik mı?**
> A: Evet, Cloudflare otomatik olarak SSL sertifikası sağlar. HTTPS bağlantıları varsayılan olarak güvenlidir.

### **🔧 MAMP Entegrasyonu**

**S: MAMP olmadan kullanabilir miyim?**
> A: Evet! MAMP entegrasyonu tamamen opsiyoneldir. Herhangi bir local web server'ı tünelleyebilirsiniz.

**S: MAMP vHost dosyası bozuldu**
> A: Backup'tan geri yükleyin:
> 1. MAMP → conf → apache → extra → httpd-vhosts.conf
> 2. .backup uzantılı dosyayı .conf olarak yeniden adlandırın

**S: Birden fazla MAMP sitesini aynı anda tünelleyebilir miyim?**
> A: Evet! Her site için ayrı tünel oluşturabilirsiniz. Farklı port'lar veya subdomain'ler kullanın.

### **🎨 Tema ve Görünüm**

**S: Kendi temamı oluşturabilir miyim?**
> A: Şu anda önceden tanımlı temalar mevcut. Custom tema desteği gelecek güncellemelerde eklenecek.

**S: Dark mode otomatik geçiş yapmıyor**
> A: Sistem Preferences → General → Appearance ayarını kontrol edin. Uygulama ayarlarında "Sistem" teması seçili olduğundan emin olun.

### **🔒 Güvenlik**

**S: Tünellerim güvenli mi?**
> A: Evet! Cloudflare Tunnel:
> - End-to-end şifreleme kullanır
> - Firewall port'larını açmanız gerekmez
> - DDoS koruması sağlar
> - Traffic Cloudflare ağı üzerinden geçer

**S: Hangi verilerim Cloudflare'a gönderiliyor?**
> A: Sadece tünel trafiği Cloudflare üzerinden geçer. Uygulama ayarları ve kişisel veriler local'de kalır.

---

## 🔬 **Teknik Detaylar**

### **🏗️ Mimari**

#### **Uygulama Yapısı**
```
CloudflaredManager/
├── 📱 App Layer
│   ├── CloudflaredManagerApp.swift      # Ana uygulama
│   ├── AppDelegate.swift                # Menu bar yönetimi
│   └── AppDelegateModernMenu.swift      # Modern menu bar
│
├── 🎨 UI Layer
│   ├── ContentView.swift                # Ana ekran
│   ├── SettingsView.swift               # Ayarlar paneli
│   ├── CreateManagedTunnelView.swift    # Tünel oluşturma
│   ├── CreateFromMampView.swift         # MAMP entegrasyonu
│   └── QuickTunnelView.swift            # Hızlı tünel
│
├── 🎭 Design System
│   ├── ModernDesignSystem.swift         # Tasarım sistemi
│   ├── ThemeManager.swift               # Tema yönetimi
│   ├── AnimationLibrary.swift           # Animasyon kütüphanesi
│   └── ModernComponents.swift           # UI bileşenleri
│
├── 🔧 Business Logic
│   ├── TunnelManager.swift              # Tünel yönetimi
│   └── Models.swift                     # Veri modelleri
│
└── 📦 Resources
    ├── Assets.xcassets/                 # Görsel varlıklar
    ├── Info.plist                      # Uygulama bilgileri
    └── sonprojeee.entitlements         # macOS izinleri
```

#### **Tasarım Desenleri**
- **MVVM**: Model-View-ViewModel mimarisi
- **ObservableObject**: Reactive state management
- **Environment Objects**: Dependency injection
- **Combine Framework**: Asynchronous programming
- **Publisher-Subscriber**: Event handling

### **🛠️ Kullanılan Teknolojiler**

#### **Apple Frameworks**
- **SwiftUI 4.0**: Declarative UI framework
- **Combine**: Reactive programming
- **AppKit**: macOS native integration
- **Foundation**: Core functionality
- **UserDefaults**: Settings persistence
- **NSWorkspace**: System integration

#### **Third-Party Dependencies**
- **Cloudflared Binary**: Cloudflare tunnel client
- **System Dependencies**: MAMP (optional)

#### **Modern SwiftUI Features**
- **@StateObject**: Object lifecycle management
- **@EnvironmentObject**: Shared state
- **@Published**: Reactive properties
- **Animation API**: Smooth transitions
- **ViewModifier**: Reusable UI logic

### **📊 Performance Optimizations**

#### **Memory Management**
- **Weak References**: Prevent retain cycles
- **Lazy Loading**: On-demand resource loading
- **State Cleanup**: Proper object disposal
- **Background Tasks**: Non-blocking operations

#### **UI Performance**
- **View Caching**: Reusable view components
- **Animation Optimization**: Hardware acceleration
- **Lazy Stacks**: Efficient list rendering
- **Image Optimization**: Asset compression

#### **Network Efficiency**
- **Connection Pooling**: Reuse HTTP connections
- **Request Debouncing**: Prevent excessive API calls
- **Background Processing**: Non-UI blocking tasks
- **Error Handling**: Graceful failure recovery

### **🔒 Güvenlik Önlemleri**

#### **Data Protection**
- **Keychain Integration**: Secure credential storage
- **Sandbox Compliance**: macOS security model
- **Input Validation**: XSS/injection prevention
- **Secure Defaults**: Safe configuration options

#### **Network Security**
- **HTTPS Only**: Encrypted communication
- **Certificate Validation**: SSL/TLS verification
- **API Authentication**: Secure Cloudflare API access
- **Local Network Isolation**: Prevent unauthorized access

---

## 🤝 **Katkıda Bulunma**

### **🎯 Katkı Türleri**

#### **🐛 Bug Reports**
Hata bildirimi için:
1. **Issue Template** kullanın
2. **Detaylı açıklama** yapın
3. **Reproduction steps** ekleyin
4. **System information** belirtin
5. **Screenshots/logs** ekleyin

#### **✨ Feature Requests**
Yeni özellik önerisi için:
1. **Use case** açıklayın
2. **Mockup/wireframe** ekleyin
3. **Priority level** belirtin
4. **Implementation ideas** paylaşın

#### **🔧 Code Contributions**
Kod katkısı için:
1. **Fork** repository'yi
2. **Feature branch** oluşturun
3. **Clean commits** yapın
4. **Tests** ekleyin
5. **Pull Request** gönderin

### **📋 Development Setup**

#### **Prerequisites**
- macOS 12.0+
- Xcode 14.0+
- Swift 5.9+
- Git 2.30+

#### **Setup Steps**
```bash
# 1. Repository'yi klonlayın
git clone https://github.com/yourusername/cloudflared-manager.git
cd cloudflared-manager

# 2. Dependencies'leri kontrol edin
# (Şu anda external dependency yok)

# 3. Xcode'da açın
open sonprojeee.xcodeproj

# 4. Build ve test edin
# Xcode → Product → Test (⌘+U)
```

#### **Code Style**
- **SwiftLint**: Kod standardı kontrolü
- **Swift Style Guide**: Apple conventions
- **Documentation**: Inline comments
- **Naming**: Descriptive, camelCase
- **Architecture**: MVVM pattern

### **🧪 Testing Guidelines**

#### **Unit Tests**
```swift
// Model testing
func testTunnelStatusValidation() {
    let tunnel = TunnelInfo(name: "test", configPath: nil)
    XCTAssertEqual(tunnel.status, .stopped)
}

// Business logic testing
func testTunnelManagerCreation() {
    let manager = TunnelManager()
    XCTAssertNotNil(manager.cloudflaredExecutablePath)
}
```

#### **UI Tests**
```swift
// SwiftUI testing
func testSettingsViewRendering() {
    let view = SettingsView()
    let hosting = UIHostingController(rootView: view)
    XCTAssertNotNil(hosting.view)
}
```

#### **Integration Tests**
- API connectivity tests
- File system operations
- Process management
- Error handling scenarios

### **📝 Documentation**

#### **Code Documentation**
```swift
/// Manages Cloudflare tunnel operations
/// 
/// This class handles:
/// - Tunnel creation and deletion
/// - Status monitoring
/// - Configuration file management
/// - MAMP integration
class TunnelManager: ObservableObject {
    // Implementation
}
```

#### **README Updates**
- Keep feature list current
- Update screenshots
- Maintain installation guides
- Document breaking changes

---

## 📄 **Lisans**

```
MIT License

Copyright (c) 2024 Adil Emre Karayürek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 **Teşekkürler**

### **🌟 Özel Teşekkürler**

- **Cloudflare Team**: Cloudflare Tunnel teknolojisi için
- **Apple**: SwiftUI ve macOS development tools için
- **MAMP Team**: Local development environment için
- **Open Source Community**: İlham veren projeler için

### **🎨 Design Inspiration**

- **Apple Human Interface Guidelines**: macOS tasarım prensipleri
- **Glassmorphism Trend**: Modern UI tasarım yaklaşımı
- **Microinteractions**: Kullanıcı deneyimi iyileştirmeleri

### **📚 Resources & References**

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [MAMP Documentation](https://documentation.mamp.info/)

---

## 📞 **İletişim & Destek**

### **🐛 Bug Reports & Feature Requests**
- **GitHub Issues**: [Repository Issues](https://github.com/yourusername/cloudflared-manager/issues)
- **Email**: support@cloudflaredmanager.com

### **💬 Community**
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/cloudflared-manager/discussions)
- **Discord**: [Community Server](https://discord.gg/cloudflaredmanager)
- **Twitter**: [@CloudflaredMgr](https://twitter.com/CloudflaredMgr)

### **📚 Documentation**
- **Wiki**: [GitHub Wiki](https://github.com/yourusername/cloudflared-manager/wiki)
- **API Docs**: [Documentation Site](https://docs.cloudflaredmanager.com)
- **Video Tutorials**: [YouTube Channel](https://youtube.com/cloudflaredmanager)

---

<div align="center">

### **⭐ Projeyi Beğendiyseniz Star Vermeyi Unutmayın!**

**Made with ❤️ in Turkey**

[🏠 Ana Sayfa](https://github.com/yourusername/cloudflared-manager) • 
[📖 Dokümantasyon](https://docs.cloudflaredmanager.com) • 
[🐛 Issues](https://github.com/yourusername/cloudflared-manager/issues) • 
[💬 Discussions](https://github.com/yourusername/cloudflared-manager/discussions)

</div>
