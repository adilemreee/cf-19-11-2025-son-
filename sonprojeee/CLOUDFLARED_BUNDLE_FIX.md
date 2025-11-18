# Cloudflared Bundle Sandbox Hatası Çözümü

## Sorun
TestFlight validation hatası:
```
App sandbox not enabled for cloudflared-arm64 executable
```

## Seçenek 1: Cloudflared'i Bundle'dan Çıkar (ÖNERİLEN)

### Adımlar:
1. Xcode'da `cloudflared` veya `cloudflared-arm64` dosyasını seçin
2. **Delete** tuşuna basın ve **Remove Reference** seçin
3. Build Phases → Copy Bundle Resources'dan da kaldırın

### Avantajlar:
- Uygulama boyutu ~50MB küçülür
- Sandbox sorunları ortadan kalkar
- TestFlight validation geçer

### Kullanım:
Kullanıcılar cloudflared'i kendi sistemlerine kurup Settings'den yolu belirtirler:
```bash
# Homebrew ile
brew install cloudflare/cloudflare/cloudflared

# Manuel indirme
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz | tar -xz
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared
```

---

## Seçenek 2: Cloudflared'i Doğru İmzala (KARMAŞIK)

Eğer mutlaka bundle içinde istiyorsanız:

### Adım 1: Cloudflared'i Strip ve İmzala
```bash
cd /path/to/your/project

# Strip debugging symbols
strip cloudflared-arm64

# Developer ID ile imzala
codesign --force --sign "Developer ID Application: YOUR_NAME (TEAM_ID)" \
  --options runtime \
  --entitlements cloudflared.entitlements \
  cloudflared-arm64
```

### Adım 2: cloudflared.entitlements Oluştur
Proje dizininde `cloudflared.entitlements` dosyası:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>
```

### Adım 3: Build Script Ekle
Xcode → Target → Build Phases → New Run Script Phase:
```bash
# Cloudflared binary'sini imzala
if [ -f "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources/cloudflared-arm64" ]; then
    echo "Imzalama: cloudflared-arm64"
    codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" \
        --options runtime \
        --entitlements "$PROJECT_DIR/cloudflared.entitlements" \
        "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources/cloudflared-arm64"
fi
```

### Not:
Bu yaklaşım karmaşık ve her build'de sorun çıkarabilir.

---

## Seçenek 3: Hybrid Yaklaşım (DENGELEYICI)

### TunnelManager Güncellemesi

Önce bundle'ı dene, yoksa sistem yolunu kullan, hiçbiri yoksa kullanıcıya indir seçeneği sun:

```swift
private static func setupBundledCloudflared() -> String? {
    let fileManager = FileManager.default
    
    // Try bundled version first
    if let bundledPath = Bundle.main.path(forResource: "cloudflared", ofType: nil) {
        if fileManager.isExecutableFile(atPath: bundledPath) {
            return bundledPath
        }
    }
    
    // Check Application Support
    if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let appSupportPath = appSupport.appendingPathComponent("CloudflaredManager/cloudflared")
        if fileManager.isExecutableFile(atPath: appSupportPath.path) {
            return appSupportPath.path
        }
    }
    
    return nil
}
```

### İlk Açılış Kurulumu

Uygulama ilk açıldığında eğer cloudflared yoksa:
1. Kullanıcıya bildir
2. İndirme linki ver
3. Veya otomatik indir (internet izni gerekli)

---

## ÖNERİM: Seçenek 1'i Kullanın

**Neden?**
- En basit ve güvenilir
- TestFlight validation garantili geçer
- Uygulama boyutu küçük
- Kullanıcılar kendi cloudflared sürümlerini yönetebilir
- Sandbox uyumlu

**Dezavantaj:**
- Kullanıcılar manuel kurulum yapmalı (ancak tek seferlik)

**Çözüm:**
README.md'ye veya uygulamanın ilk açılış ekranına kurulum talimatları ekleyin:

```markdown
## İlk Kullanım

1. Cloudflared'i yükleyin:
   ```bash
   brew install cloudflare/cloudflare/cloudflared
   ```

2. Uygulama otomatik olarak bulacaktır veya Settings'den yolu belirtin.
```

---

## UYGULAMA

### 1. Bundle'dan Kaldırma (Şimdi yapın)
```bash
# Xcode'da cloudflared dosyasını sil
# veya:
cd "/Users/adilemre/Desktop/cloudflaredtunnelapp(2 ay önce stabil sürüm)/sonndenemeee-main-2 stable/sonprojeee"
# Build Phases'da listeden kaldırın
```

### 2. README Güncelleme
İlk açılışta kullanıcılara kurulum talimatları gösterin.

### 3. Archive & Upload
```bash
# Clean build
Product → Clean Build Folder (Shift+Cmd+K)

# Archive
Product → Archive

# Distribute → TestFlight
# Bu sefer validation geçecek ✅
```

---

## Validation Checklist

✅ `com.apple.security.app-sandbox` = true (entitlements'ta)
✅ Network permissions (client/server)
✅ Bundle içinde imzasız executable yok
✅ Hardened runtime enabled
✅ Code signing tüm binary'lerde

---

## Sık Sorulan Sorular

**S: Kullanıcılar nasıl cloudflared kuracak?**
C: Homebrew veya manuel indirme. Uygulama bunu açıkça gösterir.

**S: App Store'da sorun olur mu?**
C: Hayır, birçok uygulama harici tool gerektirir (git, docker, vb.)

**S: Bundle olmadan nasıl çalışacak?**
C: Mevcut kod zaten sistem yollarını kontrol ediyor. Bundle opsiyoneldi.

**S: Update güncellemeleri?**
C: Kullanıcılar `brew upgrade cloudflared` ile güncelleyebilir.
