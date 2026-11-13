import 'package:flutter/material.dart';
import '../core/state/game_session_state.dart';
import '../game/emberlight_game.dart';

class RunSummaryModal extends StatelessWidget {
  const RunSummaryModal({
    super.key,
    required this.game,
    required this.state,
  });

  final EmberlightGame game;
  final GameSessionState state;

  @override
  Widget build(BuildContext context) {
    final outcome = state.lastOutcome;
    if (outcome == null) return const SizedBox.shrink();

    final isExtracted = state.runStatus == RunStatus.extracted;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF182028),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExtracted
                  ? const Color(0xFF80CBC4)
                  : const Color(0xFFEF5350),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isExtracted
                    ? 'EKSTRAKSI BERHASIL!'
                    : 'TUMBANG DI HVISKEROT...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isExtracted
                      ? const Color(0xFF80CBC4)
                      : const Color(0xFFEF5350),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isExtracted
                    ? 'Semua loot berhasil dibawa pulang ke Eldvik.'
                    : 'Hanya item di Safe Pocket yang selamat.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Text(
                'Loot Tersimpan (${outcome.keptItems.length}):',
                style: const TextStyle(
                  color: Color(0xFFFFB74D),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (outcome.keptItems.isEmpty)
                const Text(
                  '- Tidak ada -',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                )
              else
                ...outcome.keptItems.map(
                  (item) => Text(
                    '• ${item.name} (+${item.silverValue} Ag)${item.isSafePocket ? ' [Safe Pocket]' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              if (outcome.lostItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Loot Hilang (${outcome.lostItems.length}):',
                  style: const TextStyle(
                    color: Color(0xFFEF9A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...outcome.lostItems.map(
                  (item) => Text(
                    '• ${item.name}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Total Silver Didapat: +${outcome.totalSilverEarned} Ag',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: game.returnToCampFromOverlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D8B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Kembali ke Desa Eldvik'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
