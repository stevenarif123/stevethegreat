# Technical & Development Plan
**Project:** `stevethegreat` (Working Title: *Emberlight: Saga of Eldvik*)  
**Engine:** Flutter + Flame Engine  
**Target:** Mobile (Android / iOS) — **Dev & Playtest:** PC (Windows / Chrome)  

---

## 1. Arsitektur Project (AI-Agent Friendly)

Karena pengembangan dijalankan bareng AI Agent, kode dipisahkan secara tegas antara **Pure Dart Logic** (bisa dites otomatis via `flutter test`), **Flame Game World** (rendering 2D, hitbox, animasi, kamera), dan **Flutter UI Overlays** (HUD, Inventory, Shop, Cooking, Dialog).

```text
lib/
├── main.dart
├── core/
│   ├── constants/        # Balance numbers (stamina, dash i-frames, lantern decay)
│   ├── input/            # HybridInputController (Virtual Joystick + Keyboard/Mouse)
│   ├── models/           # Item, Recipe, Crop, EnemyConfig, Quest, SaveData
│   ├── services/         # InventoryService, FarmingService, CookingService,
│   │                     # EconomyService, CombatCalculator, SaveLoadService
│   └── state/            # Central GameState (ChangeNotifier / Riverpod)
├── game/
│   ├── emberlight_game.dart    # Root FlameGame + Camera + World switching
│   ├── worlds/
│   │   ├── village_world.dart  # Safe Area: Homestead, Kebun, Kios, NPC
│   │   └── dungeon_world.dart  # Procedural / Room-based Dungeon + Extraction
│   ├── components/
│   │   ├── player_component.dart      # Movement, Combo, Dash i-frames, Stamina
│   │   ├── enemy_component.dart       # State machine + Telegraph rendering
│   │   ├── telegraph_component.dart   # Circle/Line/Cone warning indicators
│   │   ├── crop_plot_component.dart   # Interaksi petak tanah kebun
│   │   ├── npc_component.dart         # Interaksi & trigger dialog/shop
│   │   └── lantern_overlay.dart       # Dynamic darkness radius sesuai Lantern
│   └── combat/
│       └── hitbox_hurtbox.dart
└── ui/
    ├── hud_overlay.dart        # HP, Stamina, Lantern meter, Buff icons, Virtual Controls
    ├── inventory_modal.dart    # Tas + 2 Safe Pocket + Equipment
    ├── cooking_modal.dart      # Pilih resep, lihat buff, masak
    ├── shop_modal.dart         # Skålstall: taruh loot, atur harga, jual
    ├── upgrade_modal.dart      # Torsten's Runesmith (upgrade senjata & kapasitas tas)
    └── dialogue_overlay.dart   # Kotak dialog NPC & Quest tracker

assets/
├── data/
│   ├── items.json
│   ├── recipes.json
│   ├── crops.json
│   ├── enemies.json
│   └── chapter1_dialogue.json
└── images/                     # Placeholder geometric/pixel sprites -> final art
```

### Prinsip Teknis Penting
1. **Placeholder Art First:** Di Milestone 1–3, kita pakai *procedural/pixel placeholder sprites* (atau bentuk geometris rapi dengan warna jelas) supaya mekanik, combat feel, dan loop bisa langsung dites sebelum sibuk mengurus aset gambar final.
2. **Data-Driven Balance:** Semua angka damage, stamina cost, durasi telegraph, harga jual, dan pertumbuhan tanaman ditaruh di JSON/konstanta terpusat agar mudah di-tuning.
3. **Unit Test Wajib:** Setiap service di `lib/core/services/` wajib punya unit test agar perubahan fitur tidak merusak sistem lama.

---

## 2. Roadmap Pengembangan (Fokus ke Chapter 1 Playable)

### Milestone 0: Environment & Bootstrap
* **Tugas:**
  1. Install & verifikasi Flutter SDK di mesin dev.
  2. Inisialisasi project Flutter (`stevethegreat`) + tambah dependency `flame` (dan `flame_audio` saat dibutuhkan).
  3. Setup **Hybrid Input System** (Keyboard WASD/Space/J/K + Touch Virtual Joystick/Buttons).
  4. Jalankan smoke test awal di PC (`flutter run -d chrome` atau `windows`) + `flutter test`.
* **Definition of Done:** Layar game terbuka di PC dengan karakter placeholder bisa digerakkan mulus pakai keyboard maupun virtual joystick.

### Milestone 1: Combat & Dungeon Vertical Slice *(Inti Keseruan)*
* **Tugas:**
  1. **Player Controller:** Gerak 8 arah, **3-hit Combo Attack**, **Dodge Dash** (25 Stamina, `0.25s` i-frames, attack-cancel), Stamina regen + cooldown weapon skill.
  2. **Enemy & Telegraphing:**
     * *Bramble Slime:* Lompat area dengan **Circle Telegraph** merah sebelum mendarat.
     * *Frost-Thorn Hound:* Charge lurus dengan **Line Telegraph** sebelum menerjang.
  3. **Game Feel:** Hit flash putih, knockback, damage numbers, light screen shake, dan *hitstop* singkat.
  4. **Dungeon Flow & Survival:** 3 ruangan terhubung → *Extraction Gate* (keluar bawa loot) + **Lantern Darkness Overlay** (cahaya meredup perlahan, <25% musuh jadi lebih agresif tapi drop bonus naik).
* **Definition of Done:** Kamu bisa playtest di PC: bertarung menghindari serangan musuh dengan dash, mengelola stamina, memungut drop, dan keluar lewat portal ekstraksi.

### Milestone 2: Cozy Homestead, Light Farming & Cooking
* **Tugas:**
  1. **Village World (Safe Area):** Transisi mulus antara Desa **Eldvik** ↔ Gerbang **Rotheim**.
  2. **Light Farming (6 Petak Awal):** Interaksi cangkul/tanam bibit (*Solgrain*, *Honeyroot*, *Muspelberry*), siram air, dan sistem ganti hari saat **Tidur di Pondok**.
  3. **Cooking Pot & Buff System:** Masak 3 resep awal (*Hearth-Broth*, *Vind-Tea*, *Spiced Ember Stew*). Buff terbawa aktif ke dalam Dungeon dan terlihat di HUD.
* **Definition of Done:** Siklus *"Tanam → Tidur/Panen → Masak Buff → Masuk Dungeon dengan stamina/HP lebih kuat"* berjalan utuh.

### Milestone 3: Inventory, Skålstall Shop & Progression
* **Tugas:**
  1. **Backpack & Safe Pocket:** 12 slot tas + **2 Safe Pocket** yang aman saat kalah di dungeon. Storage chest di pondok.
  2. **Skålstall Shop (Moonlighter Loop):** Taruh relic di rak, tentukan harga (indikator reaksi pembeli: Murah / Pas / Mahal), jual untuk dapat Silver.
  3. **Torsten's Runesmith (Upgrade):** Upgrade pedang Tier 1 → Tier 2 (*Hearthsteel Sword* + skill *Ember Cleave*) dan perluas kapasitas tas.
  4. **Save/Load System:** Auto-save saat tidur & setelah kembali dari dungeon (JSON lokal).
* **Definition of Done:** Loot dari dungeon bisa dijual jadi Silver atau ditempa jadi senjata lebih kuat; progress tersimpan saat aplikasi ditutup dan dibuka lagi.

### Milestone 4: Chapter 1 Content, NPCs & Boss Fight
* **Tugas:**
  1. **5 NPC Desa:** Steinar ("Steve"), Torsten, Astrid, Elder Eirik, Snorri dengan dialog harian & interaksi quest Cap 1.
  2. **Questline Chapter 1:** 3 quest pembuka hingga klimaks penyelamatan **Solpyre**.
  3. **Zone 1 Complete (Hviskerot — 3 Lantai + Boss Room):**
     * **Boss: Rotvakt, Ratu Akar** (Fase 1 cone swipe + summon; Fase 2 <50% HP multi-circle spike telegraph + redupkan lentera).
  4. **Ending Chapter 1:** Mendapat *First Hearthstone*, menyalakan kembali Solpyre desa, unlock 4 petak kebun tambahan, dan menampilkan **Halaman Jurnal Torvald (Hook ke Cap 2)**.
* **Definition of Done:** Chapter 1 bisa dimainkan dari awal prolog sampai kredit/transisi Chapter 2.

### Milestone 5: Mobile Playtest, Tuning & Polish
* **Tugas:**
  1. Tuning ukuran & posisi Virtual Joystick/tombol di layar HP (16:9 & 20:9).
  2. Audio feedback (SFX ayunan pedang, dash, hit, masak, musik cozy desa vs tegang dungeon).
  3. Balancing harga item, drop rate, damage boss, dan build test APK Android (`flutter build apk --debug`).

---

## 3. Langkah Berikutnya
Begitu pembersihan disk-mu selesai dan **Flutter SDK** sudah siap dipasang, kita langsung eksekusi **Milestone 0 & Milestone 1** agar kamu bisa secepatnya pegang dan tes sendiri *combat feel*-nya di PC.
