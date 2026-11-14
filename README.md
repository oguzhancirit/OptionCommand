# optioncommand — WheelLauncher

Mac için **ücretsiz, sınırsız** çark (pie) başlatıcı. `⌘ + ⌥` tuşlarına iki kez bas, ikincisinde basılı tut → imlecin altında çark açılır → imleci bir dilime götür → tuşları bırak. Bitti.

Ayrı bir uygulama değil: ücretsiz ve açık kaynak [Hammerspoon](https://www.hammerspoon.org) üzerinde çalışan küçük bir ayar dosyası (Spoon). Hesap yok, internet bağlantısı yok, veri toplamıyor.

*English: a free radial launcher for macOS built as a Hammerspoon Spoon. Hold modifiers, point, release. Unlimited items, nested wheels, apps / URLs / files / Shortcuts / shell commands.*

## Kurulum

1. Hammerspoon'u kur:

```bash
brew install --cask hammerspoon
```

2. Hammerspoon'u aç, **Erişilebilirlik (Accessibility)** iznini ver.
3. Bu repoyu indir ve kur:

```bash
git clone https://github.com/oguzhancirit/optioncommand.git
```

```bash
./optioncommand/install.sh
```

4. Menü çubuğundaki Hammerspoon simgesi → **Reload Config**.

Launchy hâlâ açıksa aynı tuşu o da yakalar; onu kapat.

## Ayarlar

**Kolay yol — ayar sayfası:** menü çubuğundaki `◎` simgesi → **Ayarlar…** (ya da çark açıkken `,` tuşu). Buradan kısayol ekler, siler, sırasını değiştirir, alt çark kurar, boyutu ve açma tuşlarını seçersin. **Kaydet**'e basınca çark hemen güncellenir.

Sayfanın tasarımı şu örneklerden esinlenip sıfırdan, düz HTML/CSS/JS ile yazıldı (onların kodu kullanılmadı): dallanan menü, ışık tüneli arka planı ve dönen yazı için [React Bits](https://reactbits.dev); kayan sayfalar ve yuvarlak seçim düğmeleri için [Animate UI](https://animate-ui.com).

**Simgeler:**
- Uygulama, klasör ve dosyaların simgesi kendiliğinden gelir.
- Web sitelerinin simgesi (YouTube, ChatGPT…) ilk seferde indirilir ve `~/.hammerspoon/wheel-icons/` içinde saklanır.
- Simgeyi değiştirmek için ayar sayfasında simgeye tıkla: içinde arama olan bir emoji kütüphanesi açılır (ör. "video", "yapay zeka", "müzik"). Oradan bilgisayarındaki bir resmi de seçebilir ya da "Otomatik simge" ile başa dönebilirsin.
- Web sitesi eklerken sadece adını yazman yeterli (`chatgpt.com`); `https://` kendiliğinden eklenir.

**Gizlilik:** Tek internet bağlantısı site simgesi indirmektir: önce sitenin kendisinden, bulunamazsa Google'ın simge servisinden (sadece site adı gider). İstemezsen ayar sayfasından kapat ya da `favicons = false` yaz.

**Dosyadan ayar (isteğe bağlı):** `~/.hammerspoon/wheel.lua`. Ayar sayfasından kaydettiklerin `wheel.json` dosyasına yazılır ve Lua dosyasının önüne geçer. Sadece Lua dosyasını kullanmak istersen `wheel.json`'u sil.

```lua
items = {
  { app = "Google Chrome" },                                   -- uygulama
  { url = "https://github.com", name = "GitHub", emoji = "🐙" }, -- web sitesi
  { path = "~/Downloads" },                                    -- klasör / dosya
  { shortcut = "Odak Modu" },                                  -- Mac Kısayolları
  { cmd = "pmset displaysleepnow", name = "Ekranı kapat" },    -- komut
  { keys = { { "cmd", "shift" }, "5" }, name = "Ekran görüntüsü" }, -- tuş gönder
  { name = "Siteler", items = { ... } },                       -- alt çark
}
```

Her öğeye `name`, `emoji` veya `icon = "~/resim.png"` eklenebilir. Web sitesinde `browser = "com.brave.Browser"` o tarayıcıyı kullanır.

| Ayar | Varsayılan | Ne yapar |
|---|---|---|
| `trigger` | `{"cmd","alt"}` | Çarkı açan tuşlar |
| `doublePress` | `true` | `true`: iki kez bas-tut · `false`: sadece basılı tut |
| `size` | `"medium"` | `tiny` `small` `medium` `large` `xlarge` |
| `centerOnMouse` | `true` | `false`: çark hep ekranın ortasında açılır |
| `hideOthers` | `false` | Uygulama açınca diğerlerini gizler |
| `favicons` | `true` | Site simgelerini indirir |
| `openDots` | `true` | Açık sekme ve klasörlerin altında nokta |
| `menubar` | `true` | Menü çubuğunda `◎` simgesi |
| `modes` | `{"items","running"}` | Çark türleri: kendi listen / açık uygulamalar |
| `theme` | koyu | `ring`, `hub`, `accent`, `text`, `dot` renkleri |

## Çark açıkken

| Hareket | Sonuç |
|---|---|
| Tuşları bırak | Seçili dilimi aç |
| Ortada bırak / `Esc` | Vazgeç |
| `1`–`9` | O sıradaki öğeyi hemen aç |
| İmleci klasör diliminden dışarı it | Alt çarkı aç (`⌫` geri) |
| `]` `[` | Çark türünü değiştir (açık uygulamalar) |
| `H` / `Q` | Seçili uygulamayı gizle / kapat |
| `,` | Ayar sayfasını aç |

Açık olan şeyin simgesinin altında küçük beyaz nokta görünür: çalışan uygulama, tarayıcıda açık sekmesi olan site (Safari, Chrome, Brave, Edge, Arc, Vivaldi, Opera), Finder'da açık klasör, içinde açık bir şey olan alt çark. Siteler ve klasörler için macOS ilk seferde "Hammerspoon, Chrome'u denetlemek istiyor" diye izin sorar; izin vermezsen sadece o tarayıcı için nokta çıkmaz. İstemezsen `openDots = false`.

## Benzerleriyle karşılaştırma

| | Launchy | Kando | **Bu proje** |
|---|---|---|---|
| Ücret | Ücretsizde 4 öğe | Ücretsiz, açık kaynak | **Ücretsiz, açık kaynak** |
| Öğe sayısı | Sınırlı | Sınırsız | **Sınırsız** |
| Kurulan şey | Ayrı uygulama | Ayrı uygulama (Electron) | **Hammerspoon + küçük bir eklenti** |
| Alt menü | — | Var | **Var** |
| Ayar şekli | Pencere | Pencere | **Pencere veya metin dosyası** |

Alınan fikirler: tuşu bırakınca açma, çalışan uygulama noktası ve çark türü değiştirme (Launchy); alt çarklar (Kando); sayı tuşuyla hızlı seçim ve ortada iptal bölgesi (klasik pie menü tasarımı).

## Geliştirme

Güncellemek için:

```bash
cd ~/optioncommand && git pull && ./install.sh
```

Testler:

```bash
lua5.4 tests/run.lua
```

Lisans: MIT.
