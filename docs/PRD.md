# Product Requirements Document (PRD)
**Working Title:** Emberlight: Saga of Eldvik *(Project: `stevethegreat`)*  
**Genre:** 2D Top-Down Nordic Cozy Action-RPG / Dungeon-Extraction & Shopkeeping  
**Inspirasi Utama:** *Moonlighter* (Dungeon Risk-Reward & Shopkeeping) × *Stardew Valley* (Cozy Homestead, Light Farming, Cooking & NPC)  
**Engine:** Flutter + Flame Engine (2D)  
**Target Platform:** Mobile (Android / iOS) — **Playtest Workflow:** PC (Windows / Chrome) dengan Hybrid Input  

---

## 1. Visi & Pilar Desain
Game ini memadukan **kehangatan desa Nordik yang menenangkan (*koselig*)** dengan **ekspedisi dungeon kabut beku yang menantang dan berisiko tinggi**. Tidak ada sistem yang berdiri sendiri; setiap aktivitas di zona cozy memperkuat peluang bertahan hidup di dungeon, dan setiap loot dari dungeon menghidupkan kembali desa.

### 4 Pilar Utama
1. **Cozy Safe Zone (Pemulihan & Persiapan):** Desa **Eldvik** adalah tempat aman tanpa timer stres yang menghukum. Pemain menanam bahan penting, memasak makanan buff, meracik ramuan, mengobrol dengan NPC, dan menjual hasil jarahan.
2. **Skill-Based Action Combat (Bukan Adu Klik Statis):** Pertarungan menuntut membaca pola musuh (*telegraphing*), mengatur **Stamina**, memanfaatkan **Dodge/Dash (i-frames)**, dan mengelola cooldown skill.
3. **Risk-Reward Extraction Loop:** Makin dalam lantai atau makin redup cahaya lentera, musuh makin agresif tetapi drop material langka meningkat drastis. Pulang tepat waktu mengamankan semua loot; tumbang di dungeon membuat barang di tas biasa jatuh.
4. **Meaningful Progression:** Makanan dari kebun bukan sekadar pengisi HP pasif, melainkan penentu *build* sementara (stamina regen, elemental resist, dash cooldown). Upgrade dari pandai besi langsung terasa di *combat feel*.

---

## 2. Core Game Loop

```text
[1. COZY HOMESTEAD & VILLAGE (Safe Area)]
   ├── Panen / Tanam bahan kunci (Light Farming, 6-12 petak efisien)
   ├── Masak & Craft (Buff Run, Healing Brew, Lantern Oil)
   ├── Buka Kios / Jual Loot ke NPC (Cari Gold & Naikkan Relasi)
   └── Upgrade Gear & Tas di Pandai Besi
            │
            ▼ (Masuk Gerbang Rotheim)
[2. EXPEDITION / DUNGEON (Challenging Loop)]
   ├── Eksplorasi ruangan prosedural / semi-handcrafted per lantai
   ├── Combat aktif: Light/Heavy Attack + Dodge Dash + Skill + Telegraph
   ├── Risk-Reward: Lentera / Threat Meter naik seiring kedalaman
   └── Pilihan kritis: Lanjut ke lantai berikut (loot langka) vs Ekstraksi pulang?
            │
      ┌─────┴──────────────────┐
      ▼ (Ekstraksi Sukses)     ▼ (Tumbang / HP 0)
[Bawa semua loot + Gold]   [Safe Pocket selamat, tas utama hilang sebagian]
      └─────┬──────────────────┘
            ▼
  Kembali ke Safe Area → Proses loot → Push lebih dalam / Lanjut Cerita
```

---

## 3. Spesifikasi Sistem Utama

### 3.1. Safe Area & Cozy Mechanics
* **Homestead (Pondok & Halaman Pemain):**
  * **Pondok:** Tempat tidur (simpan progress, ganti hari, pulihkan HP/Stamina penuh), Peti Penyimpanan (*Storage Chest*), Meja Dapur (*Cooking Pot*), dan Meja Kerja (*Workbench*).
  * **Kios Dagang (*Skålstall*):** Rak display 4–8 slot (bisa di-upgrade). Pemain menaruh relic/material dari dungeon, menentukan harga wajar (indikator reaksi NPC: *Terlalu Murah / Pas / Kemahalan*), lalu melayani pembeli atau menjual cepat di akhir sesi.
* **Desa Eldvik (Hub NPC):**
  * Zona bebas monster dengan musik akustik hangat, lampu obor rune, dan jadwal sederhana NPC (pagi-siang di kios/bengkel, sore di alun-alun Solpyre).
  * Interaksi NPC: Dialog harian, *Gift* (hadiah favorit membuka resep/diskon), Quest papan pengumuman desa, dan layanan khusus (**Torsten** si Pandai Besi, **Astrid** si Herbalis/Koki, **Snorri** si Kolektor/Kurir).

### 3.2. Light Farming (Ringkas, Strategis, Tidak Menguras Waktu)
Agar tidak membosankan atau terasa seperti "kerja rodi", farming didesain **skala kecil & berdampak tinggi**:
* **Kapasitas:** Mulai dari **6 petak tanah** (maksimal 18 petak di late-game).
* **Siklus Tumbuh:** 1–3 hari in-game (1 hari = 1 kali tidur / selesai 1 ekspedisi penuh). Penyiraman bisa di-upgrade jadi *Rune Sprinkler* di Cap 2+.
* **Kategori Tanaman:**
  1. *Solgrain & Honeyroot* → Bahan dasar makanan pemulih HP & Stamina.
  2. *Muspelberry* → Buff Damage & Cold Resistance.
  3. *Frostmint* → Buff Stamina Regen & Cooldown Reduction.
  4. *Månesopp (Jamur Bulan)* → Bahan *Lantern Oil* (memperpanjang durasi cahaya di dungeon).

### 3.3. Survival, Cooking & Itemization
* **Sistem Lentera & Threat (Mekanik Survival Dungeon):**
  * Pemain membawa **Cracked Lantern** yang cahayanya perlahan meredup di dalam dungeon (atau saat terkena serangan kegelapan).
  * Jika lentera redup (<25%), jarak pandang menyempit dan musuh mendapat buff agresi (*Shadow Enrage*), namun peluang drop *Essence Langka* naik **+35%** (Risk-Reward!).
  * Pemain bisa mengisi ulang lentera dengan *Lantern Oil* hasil crafting atau obor di ruang istirahat dungeon.
* **Cooking & Buff System:**
  * Maksimal **2 slot Buff Aktif** sebelum/saat ekspedisi (1 *Meal Buff* durasi panjang + 1 *Elixir/Tea* taktis).
  * Contoh resep: *Hearth-Broth* (+25 Max HP, +15% Fire/Cold Resist), *Vind-Tea* (-20% Stamina cost untuk Dash).
* **Kategori Item:**
  1. **Equipment:** Senjata (Sword & Buckler, Twin Daggers, Heavy Lantern-Staff), Armor, Charm/Ring.
  2. **Consumables:** Makanan masakan, Potion instan, Lantern Oil, *Recall Feather* (item darurat untuk ekstraksi instan).
  3. **Dungeon Loot / Relics:** Item khusus untuk dijual di Kios atau bahan tempa.
  4. **Farming & Crafting Materials:** Bibit, hasil panen, bijih (*Iron/Ember Ore*), ekstrak monster.
* **Backpack & Safe Pocket:**
  * Tas punya kapasitas terbatas (misal awal 12 slot, 2 di antaranya **Safe Pocket** yang tidak akan hilang meski kalah di dungeon).

### 3.4. Combat System (Skill-Based & Tactile)
* **Kontrol Pemain:**
  * Gerak 8 arah (360° analog di HP / WASD di PC).
  * **Basic Combo (3-hit):** Ada *recovery frame* tipis di akhir combo supaya tidak asal spam.
  * **Weapon Skill (Cooldown):** Tiap senjata punya 1 skill unik (misal: *Shield Bash* stun, *Whirlwind Slash* area, *Ember Bolt* jarak jauh).
  * **Dodge / Dash:** Menggunakan **25 Stamina**, memberi *invincibility frames* (~0.25 detik), jarak dash tetap, bisa membatalkan animasi serangan (*attack cancel*) untuk menghindari bahaya mendadak.
* **Stamina Management:**
  * Stamina maksimal awal: `100`.
  * Regenerasi otomatis setelah jeda singkat (0.6 detik tidak pakai stamina).
  * Makanan dari kebun memengaruhi kecepatan regen & biaya stamina.
* **Enemy Design & Telegraphing:**
  * Setiap musuh **wajib** memiliki fase *Telegraph* (0.4–0.9 detik) sebelum hitbox serangan aktif:
    * *Melee rusher:* Garis merah/oranye arah seruduk + kilatan mata.
    * *Area slammer:* Lingkaran merah yang mengisi penuh sebelum hantaman jatuh.
    * *Ranged spitter:* Garis bidik tipis sebelum proyektil meluncur.
  * Efek feedback: *Hitstop* ringan (30–50ms), *screen shake* halus, flash putih pada musuh kena hit, angka damage, dan knockback.

### 3.5. Economy & Progression
* **Dual Currency / Value:**
  * **Silver / Skald-Coins:** Untuk beli bibit, upgrade kios, biaya tempa, dan ekspansi pondok.
  * **Ember Shards / Relic Materials:** Tidak bisa dibeli dengan koin—hanya didapat dari dungeon untuk membuka tier senjata baru & menyalakan **Solpyre**.
* **Siklus Waktu Sederhana:**
  * Tidak ada jam yang memaksa pemain pingsan di tengah jalan saat di desa.
  * Hari berganti hanya saat pemain memilih **Tidur di Pondok** atau **Pulang dari Ekspedisi** (membuat fase cozy benar-benar santai, sementara ketegangan terkonsentrasi di dungeon).

---

## 4. Spesifikasi Teknis & Kontrol (Mobile Target + PC Playtest)

### 4.1. Hybrid Input Layer
Agar development cepat di PC tapi terasa natural di HP:
* **Touch Mode (HP):** Virtual Floating Joystick (kiri), tombol Attack, Dash, Skill, Quick-Consumable, dan Interact kontekstual (kanan).
* **PC Playtest Mode:**
  * `WASD` / Arrow Keys = Gerak
  * `J` / `Left Click` = Attack
  * `Space` / `Shift` = Dodge Dash
  * `K` / `Right Click` = Weapon Skill
  * `E` = Interact (NPC, Kebun, Kios, Portal)
  * `1` / `2` = Quick Use Item / Oil
  * `Tab` / `I` = Inventory & Crafting UI
* Tombol virtual bisa di-toggle tampil/sembunyi otomatis berdasarkan input terakhir atau flag debug.

### 4.2. Arsitektur Data-Driven (Ramah AI Agent)
* Semua item, resep masakan, bibit tanaman, statistik musuh, dialog NPC, dan tabel loot disimpan dalam **JSON / Dart typed models** di `assets/data/`.
* UI menu (Inventory, Cooking, Shop, Dialog, HUD) dibangun memakai **Flutter Overlays** di atas `GameWidget` Flame agar layout responsif di berbagai rasio layar HP.
* Logika inti (Combat calculation, Inventory, Economy, Save/Load) dipisah menjadi pure Dart services agar bisa diuji otomatis via `flutter test`.

---

## 5. Kriteria Sukses Chapter 1 (Vertical Slice Target)
1. Pemain bisa berjalan di Desa **Eldvik**, berbicara dengan minimal 3 NPC, menanam & memanen 2 jenis tanaman di homestead.
2. Pemain bisa memasak minimal 3 resep makanan yang memberikan stat buff nyata saat masuk dungeon.
3. Pemain bisa masuk ke Dungeon 1 (**Hviskerot / Whispering Roots**, 3 lantai + 1 Boss Room) dengan combat responsif (Attack, Dash i-frames, Stamina, Telegraph musuh).
4. Sistem Lentera & Ekstraksi berjalan (termasuk penalti kalah vs safe pocket).
5. Pemain bisa menjual loot di Kios **Skålstall** dan meng-upgrade senjata/tas minimal 1 tier di tempat **Torsten**.
