-- WheelLauncher ayarları. Kaydedince kendiliğinden yenilenir.
-- İlk öğe çarkın tepesinde durur, diğerleri saat yönünde dizilir. Sayı sınırı yok.
return {
  trigger = { "cmd", "alt" }, -- çarkı açan tuşlar: cmd, alt, ctrl, shift
  doublePress = true,         -- true: iki kez bas, ikincisinde basılı tut · false: sadece basılı tut
  size = "medium",            -- tiny | small | medium | large | xlarge
  hideOthers = false,         -- true: uygulama açınca diğerlerini gizle

  items = {
    { app = "Claude" },
    { app = "Brave Browser" },
    { app = "Mail" },
    { app = "Google Chrome" },

    -- Web sitesi (browser = "com.brave.Browser" yazarsan o tarayıcıda açılır)
    { url = "https://github.com", name = "GitHub", emoji = "🐙" },

    -- Klasör veya dosya
    { path = "~/Downloads", name = "İndirilenler" },

    -- Mac "Kısayollar" uygulamasındaki bir kısayol
    -- { shortcut = "Odak Modu", emoji = "🎯" },

    -- Terminal komutu
    -- { cmd = "pmset displaysleepnow", name = "Ekranı kapat", emoji = "🌙" },

    -- Tuş kombinasyonu gönder (örnek: ekran görüntüsü aracı)
    -- { keys = { { "cmd", "shift" }, "5" }, name = "Ekran görüntüsü", emoji = "📸" },

    -- Alt çark: imleci dilimin dışına doğru itince açılır
    {
      name = "Siteler", emoji = "📂",
      items = {
        { url = "https://youtube.com", name = "YouTube", emoji = "▶️" },
        { url = "https://mail.google.com", name = "Gmail", emoji = "✉️" },
        { url = "https://calendar.google.com", name = "Takvim", emoji = "📅" },
      },
    },
  },
}
