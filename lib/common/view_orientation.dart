// Modified: 2026-08-27 20:29 — création : ViewOrientation était déclaré deux fois, dans
//           classical/pentomino_game_state.dart et pentoscope/pentoscope_provider.dart.
//           Deux enums homonymes sont deux types distincts pour Dart, ce qui interdisait
//           tout partage de code manipulant l'orientation. Définition unique ici.
// lib/common/view_orientation.dart

/// Orientation "vue" (repère écran).
///
/// Ne change pas la logique de jeu : sert à interpréter certaines actions
/// (notamment l'échange des symétries H et V) selon l'orientation de l'écran.
enum ViewOrientation { portrait, landscape }
