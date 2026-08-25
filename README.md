# PayTrack App

PayTrack App, kullanıcının kredi kartlarını, kredilerini, aboneliklerini, faturalarını ve diğer düzenli ödemelerini tek uygulamadan takip etmesini sağlayan Flutter tabanlı mobil istemcidir.

## Proje Amacı

Kullanıcının farklı banka uygulamaları, abonelik servisleri ve faturalar arasında gezinmeden yaklaşan tüm ödemelerini tek yerde görebilmesini ve zamanında bildirim almasını sağlamak.

Uygulama özellikle şu sorulara hızlı cevap vermeyi hedefler:

- Bu ay toplam ne kadar ödeme var?
- Önümüzdeki 7 gün ne kadar para çıkacak?
- Bugün hangi ödemeler var?
- Maaşa kadar ne kadar para ayırmam gerekiyor?
- Kredi kartlarımın son ödeme tarihleri ne zaman?
- Kredilerimin kaç taksiti kaldı?
- Aboneliklerim aylık ve yıllık toplam ne kadar tutuyor?

## Teknoloji

- Flutter
- Dart
- Riverpod
- go_router
- REST API
- Local notifications / push notifications

## Ana Ekranlar

### Dashboard

- Bu ay ödenecek toplam
- Önümüzdeki 7 gün
- Bugünkü ödemeler
- Yaklaşan ödemeler listesi
- Geciken ödeme uyarıları
- Maaşa kadar gerekli tahmini tutar

### Takvim

- Günlük ödeme yoğunluğu
- Tarihe göre ödeme listesi
- Kredi kartı son ödeme tarihleri
- Abonelik yenileme günleri

### Ödemeler

Filtreler:

- Tümü
- Kredi kartı
- Kredi
- Abonelik
- Fatura
- Diğer

### Varlıklar

- Kredi kartları
- Krediler
- Abonelikler
- Faturalar
- Diğer düzenli ödemeler

### İstatistikler

- Aylık sabit gider
- Yıllık abonelik maliyeti
- Borç ödeme takvimi
- Aylık ödeme trendi

### Ayarlar

- Maaş günü
- Bildirim tercihleri
- Reminder zamanları
- Para birimi
- Hesap / güvenlik

## Tasarım İlkeleri

- Temiz ve finans uygulamasına uygun görünüm
- Tek bakışta anlaşılabilir dashboard
- Gereksiz detaydan uzak kartlar
- Kritik tarihler için net görsel hiyerarşi
- Hızlı ödeme ekleme
- Minimum manuel veri girişi

## Backend

Backend ayrı repository'de tutulmaktadır:

`yuceloper/paytrack-backend`

## Yol Haritası

Detaylı mobil geliştirme planı için [ROADMAP.md](ROADMAP.md) dosyasına bakın.

## Yapılacaklar

Aktif işler için [TODO.md](TODO.md) dosyasına bakın.

## Durum

Proje erken geliştirme aşamasındadır. İlk hedef mock veriden çıkıp gerçek backend API'sine bağlı çalışan dashboard ve ödeme yönetimi MVP'sidir.
