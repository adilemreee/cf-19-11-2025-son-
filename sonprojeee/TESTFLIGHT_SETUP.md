# TestFlight için Cloudflared Kurulum Rehberi

## Sorun
TestFlight veya Archive build'lerde cloudflared yürütme dosyasına erişim sorunu yaşanıyordu. Normal debug build'lerde çalışıyor ancak release build'lerde dosya bulunamıyordu.

## Çözüm
1. **Bundle İçine Ekleme**: cloudflared binary'sini Xcode projesine kaynak olarak ekleyin
2. **Application Support'a Kopyalama**: İlk çalıştırmada bundle'dan Application Support dizinine kopyalama
3. **İzin Yönetimi**: Otomatik olarak executable izinleri ayarlama
4. **Entitlements**: Gerekli sandbox izinlerini ekleme

## Adımlar

### 1. Cloudflared Binary'sini İndirin
```bash
# Intel Mac için
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz | tar -xz

# Apple Silicon (M1/M2) için
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz | tar -xz

# Universal binary oluşturmak için (opsiyonel)
lipo -create cloudflared-amd64 cloudflared-arm64 -output cloudflared
```

### 2. Xcode Projesine Ekleyin

1. Xcode'da projenizi açın
2. İndirdiğiniz `cloudflared` dosyasını projeye sürükleyin
3. **Copy items if needed** seçeneğini işaretleyin
4. **Add to targets** kısmında ana app target'ınızı seçin
5. Dosyanın **Resources** klasörüne eklendiğinden emin olun

### 3. Build Phases Kontrolü

1. Xcode'da Target'ınızı seçin
2. **Build Phases** sekmesine gidin
3. **Copy Bundle Resources** bölümünde `cloudflared` dosyasının listelendiğini doğrulayın

### 4. File Inspector'da Ayarlar

1. Project Navigator'da `cloudflared` dosyasını seçin
2. Sağdaki **File Inspector**'da (⌥⌘1):
   - **Target Membership**: Ana app target'ınız işaretli olmalı
   - **Type**: "Default - Resource" olmalı

### 5. Archive & Export

1. **Product > Archive** ile build alın
2. Archive tamamlandığında **Distribute App** > **TestFlight & App Store** seçin
3. Normal şekilde devam edin

## Yapılan Kod Değişiklikleri

### TunnelManager.swift
- `setupBundledCloudflared()`: Bundle içinden cloudflared'i bulur ve Application Support'a kopyalar
- `resolveInitialCloudflaredPath()`: Öncelik sırasını günceller (Bundle > Stored Path > System Paths)

### sonprojeee.entitlements
- Sandbox izinleri eklendi:
  - `com.apple.security.app-sandbox`: Sandbox aktif
  - `com.apple.security.files.user-selected.read-write`: Dosya erişimi
  - `com.apple.security.network.client`: İstemci bağlantıları
  - `com.apple.security.network.server`: Sunucu dinleme

## Doğrulama

### Debug Build
```bash
# Uygulamayı çalıştırın ve console loglarını kontrol edin:
✅ Bundle'da cloudflared bulundu: /path/to/app/cloudflared
✅ cloudflared Application Support'a kopyalandı: ~/Library/Application Support/CloudflaredManager/cloudflared
✅ cloudflared için yürütme izinleri ayarlandı
```

### TestFlight Build
1. TestFlight'a yükleyin
2. Test cihazınızda indirin ve çalıştırın
3. Dashboard'da "cloudflared hazır" durumunu görmelisiniz
4. Quick Tunnel veya Managed Tunnel başlatmayı deneyin

## Sorun Giderme

### "cloudflared bulunamadı" Hatası
- Xcode'da `cloudflared` dosyasının **Copy Bundle Resources** listesinde olduğunu kontrol edin
- Archive build yaparken "Include app symbols" seçeneğini işaretleyin

### "İzin hatası" (Permission Denied)
- Application Support dizinine kopyalama otomatik olarak izinleri düzeltmelidir
- Manuel kontrol: 
  ```bash
  ls -la ~/Library/Application\ Support/CloudflaredManager/
  chmod +x ~/Library/Application\ Support/CloudflaredManager/cloudflared
  ```

### "Network error" Hatası
- `sonprojeee.entitlements` dosyasının network izinlerini içerdiğinden emin olun
- Xcode'da Signing & Capabilities sekmesinde Entitlements dosyasının tanımlı olduğunu kontrol edin

## Notlar

- **Universal Binary**: Hem Intel hem Apple Silicon Mac'lerde çalışması için universal binary kullanın
- **Güncelleme**: Cloudflared güncellemek için bundle içindeki dosyayı değiştirin ve yeni build alın
- **Boyut**: cloudflared ~50MB civarındadır, bu uygulama boyutunu artıracaktır
- **Sandbox**: Sandbox'lı ortamda çalışmak için Application Support kullanımı zorunludur

## Alternatif Yaklaşım (İleri Seviye)

Eğer uygulama boyutunu küçük tutmak isterseniz:
1. Cloudflared'i ilk açılışta otomatik indirin
2. SHA256 doğrulaması yapın
3. Application Support'a kaydedin

Bu yaklaşım için internet bağlantısı gerekir ve daha karmaşıktır.
