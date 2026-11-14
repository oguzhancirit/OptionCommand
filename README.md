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

Dosya: `~/.hammerspoon/wheel.lua`. Kaydedince kendiliğinden yenilenir.

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

Uygulama çalışıyorsa simgesinin altında küçük nokta görünür.

## Benzerleriyle karşılaştırma

| | Launchy | Kando | **Bu proje** |
|---|---|---|---|
| Ücret | Ücretsizde 4 öğe | Ücretsiz, açık kaynak | **Ücretsiz, açık kaynak** |
| Öğe sayısı | Sınırlı | Sınırsız | **Sınırsız** |
| Kurulan şey | Ayrı uygulama | Ayrı uygulama (Electron) | **Hammerspoon + 2 küçük dosya** |
| Alt menü | — | Var | **Var** |
| Ayar şekli | Pencere | Pencere | Tek metin dosyası |

Alınan fikirler: tuşu bırakınca açma, çalışan uygulama noktası ve çark türü değiştirme (Launchy); alt çarklar (Kando); sayı tuşuyla hızlı seçim ve ortada iptal bölgesi (klasik pie menü tasarımı).

Eksik olan: ayar penceresi yok, öğeler metin dosyasından düzenlenir.

## Geliştirme

```bash
lua5.4 tests/run.lua
```

Lisans: MIT.
