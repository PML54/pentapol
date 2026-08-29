// Modified: 2026-08-29 08:55 — 6×10 dans Pentoscope (temps 2, étape 1) : le nom d'asset
//           devient paramètre (défaut 6×10, appelant historique inchangé). Format 45 o/
//           solution indépendant de la forme du rectangle.
// lib/services/pentapol_solutions_loader.dart
// Historique: 2025-11-15 06:45:00

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

const int _boardCells = 60;
const int _bytesPerSolution = 45;

/// Charge les solutions normalisées d'un rectangle de 60 cases depuis [asset].
///
/// [asset] par défaut : la table 6×10 (comportement historique inchangé). Le
/// format (60 cases × 6 bits = 45 octets/solution) ne dépend pas de la forme du
/// rectangle, seul le nom du fichier change — voir PLAN_6X10_DANS_PENTOSCOPE.md §4.3.
Future<List<BigInt>> loadNormalizedSolutionsAsBigInt([
  String asset = 'assets/data/solutions_6x10_normalisees.bin',
]) async {
  // Le chemin doit être déclaré dans pubspec.yaml (section assets).
  final data = await rootBundle.load(asset);
  final bytes = data.buffer.asUint8List();

  if (bytes.length % _bytesPerSolution != 0) {
    throw StateError(
      'Taille de fichier invalide: ${bytes.length} octets, '
          'pas multiple de $_bytesPerSolution.',
    );
  }

  final solutionCount = bytes.length ~/ _bytesPerSolution;
  final solutions = <BigInt>[];

  int offset = 0;
  for (int i = 0; i < solutionCount; i++) {
    final boardBit6 = _bytesToBit6Board(bytes, offset);
    offset += _bytesPerSolution;
    final big = _bit6BoardToBigInt(boardBit6);
    solutions.add(big);
  }

  return solutions;
}

List<int> _bytesToBit6Board(Uint8List bytes, int offset) {
  final board = List<int>.filled(_boardCells, 0);

  int byteIndex = offset;
  int currentByte = 0;
  int bitsLeft = 0;

  for (int cell = 0; cell < _boardCells; cell++) {
    int code = 0;
    for (int i = 0; i < 6; i++) {
      if (bitsLeft == 0) {
        currentByte = bytes[byteIndex++];
        bitsLeft = 8;
      }
      final bit = (currentByte >> (bitsLeft - 1)) & 1;
      bitsLeft--;
      code = (code << 1) | bit;
    }
    board[cell] = code;
  }

  return board;
}

BigInt _bit6BoardToBigInt(List<int> boardBit6) {
  BigInt acc = BigInt.zero;
  for (final code in boardBit6) {
    acc = (acc << 6) | BigInt.from(code);
  }
  return acc;
}
