// Modified: 2026-10-08 07:20 — laisser swiper le tiroir sur une pièce déjà sélectionnée.
// Historique: 2026-10-08 07:06 — garder les pièces nettes et avancer d'un cran depuis la pièce centrale.
// Historique: 2026-10-08 07:00 — garder la flèche pour tout tiroir débordant, même à trois pièces.
// Historique: 2026-10-08 03:53 — enchaîner la dernière pièce et la première sans retour arrière.
// Historique: 2026-10-08 03:47 — parcourir le tiroir en boucle avec une seule grande flèche.
// Historique: 2026-10-08 03:36 — naviguer par pièce avec des flèches et protéger le drag.
// Historique: 2026-10-07 09:42 — terminer l'aperçu au milieu et préserver le swipe après les animations.
// Historique: 2026-10-07 09:26 — découvrir le tiroir pendant trois secondes et centrer les pièces sélectionnées.
// Historique: 2026-10-05 20:02 — compter les relâchements refusés comme tentatives de pose.
// Historique: 2026-10-05 19:46 — désélectionner la pièce du tiroir quand le tiroir défile.
// Historique: 2026-09-23 06:42 — rendre l'image selon le mode figé de la partie.
// Historique: 2026-09-23 05:32 — employer la solution-image propre à la partie.
// Historique: 2026-09-23 05:13 — afficher les fragments illustrés dans le tiroir 6×10.
// Historique: 2026-09-22 16:31 — afficher la pièce hors plateau pour supprimer la zone aveugle au-dessus du tiroir.
// Historique: 2026-09-22 06:06 — respecter le réglage de visibilité de la miniature de drag.
// Historique: 2026-09-10 10:13 — pièce visible dès la prise du rack, contour rouge tant que le dépôt est interdit.
// Historique: 2026-09-10 06:00 — ergonomie (bloc 3, C6) : fondu de bord du rack SENSIBLE au défilement.
//           Fondu de tête seulement si on a défilé (offset > 0) → la 1re pièce n'est jamais rognée
//           (C6) ; fondu de queue tant qu'il reste des pièces après → suggère au nouveau joueur (3×5)
//           que le rack défile, sans rétrécir les pièces (respecte l'invariant #3). ShaderMask dstIn.
// Historique: 2026-09-09 07:35 — drag rack, ancre à la bonne échelle : onGrab passe aussi grabLocal
//           (offset px du toucher) à selectPiece — le plateau reconstruit le doigt réel dans onMove.
// Historique: 2026-09-07 16:30 — glissé « suivi exact » : le feedback tiroir (image sous le doigt)
//           devient réactif — image RÉELLE si posable, TRANSPARENT si chevauchement (isPreviewValid).
// Historique: 2026-09-07 09:35 — halo de sélection lisible sur pièce jaune (N°3) : le halo ambré seul
//           ne contrastait pas ; ajout d'un contour sombre net par-dessus (visible quelle que soit
//           la couleur de la pièce, palettes perso incluses).
// Historique: 2026-09-03 07:10 — fix drag tiroir : onGrab calcule la cellule empoignée (_grabbedCell,
//           depuis l'offset du toucher, centrage + marge PieceRenderer, valable en paysage) et la
//           passe à selectPiece(grabbedCell:) → le placement colle au doigt comme sur le plateau.
// Historique: 2026-09-01 09:01 — zone tactile pleine boîte (hitBoxSize = fixedSize) pour attraper le
//           « I » aussi bien que les autres ; le halo de sélection passe dans childBuilder, collé à
//           la pièce et affiché au repos seulement (pas sur le feedback de drag).
// lib/pentoscope/widgets/pentoscope_piece_slider.dart
// Historique: 2026-08-30 13:35 — PLAN_ERGONOMIE §6 étape 2 : la barre reçoit pieceCellSize (défaut
//             22) ; la boîte de pièce et PieceRenderer en dérivent, au lieu de la taille figée 118.
// Historique: 2026-08-28 20:48 — suppression de la démonstration : retrait du champ et des
//             méthodes de surbrillance locale et du bloc lecteur ; l'enveloppe Container disparaît.
//             2512100457 — FIX _getDisplayPositionIndex() rotation paysage stable.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:pentapol/pentoscope/widgets/piece_drag_feedback.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/common/widgets/draggable_piece_widget.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/illustrated_piece_cells.dart';

class PentoscopePieceSlider extends ConsumerStatefulWidget {
  final bool isLandscape;

  /// Taille de case des pièces de la barre, ancrée sur le plateau (PLAN_ERGONOMIE §3).
  /// Défaut 22 : comportement d'avant l'ergonomie tablette pour tout appelant non modifié.
  final double pieceCellSize;

  const PentoscopePieceSlider({
    super.key,
    required this.isLandscape,
    this.pieceCellSize = 22.0,
  });

  @override
  ConsumerState<PentoscopePieceSlider> createState() =>
      _PentoscopePieceSliderState();

  // Méthode statique pour accéder au state depuis l'extérieur
  static _PentoscopePieceSliderState? of(BuildContext context) {
    return context.findAncestorStateOfType<_PentoscopePieceSliderState>();
  }
}

class _PentoscopePieceSliderState extends ConsumerState<PentoscopePieceSlider> {
  final ScrollController _scrollController = ScrollController();

  bool _navigationReady = false;
  bool _selectionCanceledForCurrentScroll = false;
  Object? _previewedPuzzle;
  int _animationGeneration = 0;
  double _leadingPadding = 16;
  bool _automaticScrollActive = false;
  int? _navigationTargetId;
  bool _pieceDragging = false;
  double? _viewport;
  double _cycleExtent = 0;
  bool _circular = false;
  double? _navigationTargetOffset;

  void _normalizeCycle() {
    if (!_circular ||
        _pieceDragging ||
        !_scrollController.hasClients ||
        _automaticScrollActive) {
      return;
    }
    final offset = _scrollController.offset;
    final normalized = _cycleExtent + (offset % _cycleExtent);
    if ((normalized - offset).abs() > 1) {
      _scrollController.jumpTo(normalized);
    }
  }

  void _interruptNavigation() {
    final hadTarget = _navigationTargetId != null;
    _navigationTargetId = null;
    _navigationTargetOffset = null;
    _stopAutomaticScroll();
    if (hadTarget && mounted) setState(() {});
  }

  Future<void> _navigate() async {
    if (_pieceDragging || !_scrollController.hasClients) return;
    final state = ref.read(pentoscopeProvider);
    if (state.availablePieces.isEmpty) return;
    _normalizeCycle();
    if (_circular && (_navigationTargetOffset ?? 0) >= _cycleExtent * 2) {
      _stopAutomaticScroll();
      _scrollController.jumpTo(_scrollController.offset - _cycleExtent);
      _navigationTargetOffset = _navigationTargetOffset! - _cycleExtent;
    }
    final position = _scrollController.position;
    final origin = _navigationTargetOffset ?? position.pixels;
    var currentIndex = 0;
    var currentOffset = origin;
    var nearestDistance = double.infinity;
    for (var index = 0; index < state.availablePieces.length; index++) {
      final offset = _pieceOffset(state.availablePieces[index].id, state);
      for (final cycle in (_circular ? [-1, 0, 1] : [0])) {
        final candidate = offset + cycle * _cycleExtent;
        final distance = (candidate - origin).abs();
        if (distance < nearestDistance) {
          nearestDistance = distance;
          currentIndex = index;
          currentOffset = candidate;
        }
      }
    }
    final current = state.availablePieces[currentIndex];
    final target = state
        .availablePieces[(currentIndex + 1) % state.availablePieces.length];
    final targetOffset =
        currentOffset +
        ((_pieceMaxDim(current) + _pieceMaxDim(target)) * widget.pieceCellSize +
                16) /
            2;
    _interruptNavigation();
    if (state.selectedPiece != null && state.selectedPlacedPiece == null) {
      ref.read(pentoscopeProvider.notifier).cancelSelection();
    }
    final generation = _animationGeneration;
    _navigationTargetId = target.id;
    _navigationTargetOffset = targetOffset;
    _automaticScrollActive = true;
    setState(() {});
    try {
      final offset = targetOffset;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(offset);
      } else {
        await _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted && generation == _animationGeneration) {
        _automaticScrollActive = false;
        setState(() {
          _navigationTargetId = null;
          _navigationTargetOffset = null;
        });
        _normalizeCycle();
      }
    }
  }

  Widget _navigationButton() {
    final enabled = _navigationReady && !_pieceDragging;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 64,
      height: 64,
      child: IconButton(
        key: const ValueKey('rack-next'),
        tooltip: l10n.next,
        iconSize: 48,
        onPressed: enabled ? _navigate : null,
        icon: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _stopAutomaticScroll() {
    _animationGeneration++;
    final wasActive = _automaticScrollActive;
    _automaticScrollActive = false;
    if (wasActive && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
  }

  void _schedulePreview(PentoscopeState state) {
    if (state.puzzle == null || identical(state.puzzle, _previewedPuzzle)) {
      return;
    }
    _previewedPuzzle = state.puzzle;
    final generation = ++_animationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          generation != _animationGeneration ||
          !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_circular ? _cycleExtent : 0);
      if (state.placedPieces.length > state.fixedPieceIds.length ||
          state.elapsedSeconds != 0 ||
          state.strategyActions.total != 0 ||
          state.selectedPiece != null ||
          MediaQuery.disableAnimationsOf(context)) {
        return;
      }
      final end = _pieceOffset(state.availablePieces.last.id, state);
      if (end > _scrollController.offset) {
        _automaticScrollActive = true;
        try {
          await _scrollController.animateTo(
            end,
            duration: const Duration(milliseconds: 2700),
            curve: Curves.linear,
          );
          if (!mounted ||
              generation != _animationGeneration ||
              !_scrollController.hasClients) {
            return;
          }
          final middle =
              state.availablePieces[state.availablePieces.length ~/ 2];
          await _scrollController.animateTo(
            _pieceOffset(middle.id, state),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } finally {
          if (generation == _animationGeneration) {
            _automaticScrollActive = false;
          }
        }
      }
    });
  }

  double _pieceOffset(int id, PentoscopeState state) {
    var center = _leadingPadding + (_circular ? _cycleExtent : 0);
    final position = _scrollController.position;
    for (final piece in state.availablePieces) {
      final extent = _pieceMaxDim(piece) * widget.pieceCellSize + 8;
      if (piece.id == id) {
        return (center + extent / 2 - position.viewportDimension / 2).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
      }
      center += extent;
    }
    return position.pixels;
  }

  void _centerPiece(int id) {
    _interruptNavigation();
    _normalizeCycle();
    final generation = _animationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          generation != _animationGeneration ||
          !_scrollController.hasClients) {
        return;
      }
      final state = ref.read(pentoscopeProvider);
      if (state.selectedPiece?.id != id || state.selectedPlacedPiece != null) {
        return;
      }
      _automaticScrollActive = true;
      try {
        if (MediaQuery.disableAnimationsOf(context)) {
          _scrollController.jumpTo(_pieceOffset(id, state));
        } else {
          await _scrollController.animateTo(
            _pieceOffset(id, state),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      } finally {
        if (generation == _animationGeneration) {
          _automaticScrollActive = false;
        }
      }
    });
  }

  void _refreshNavigation() {
    if (!mounted) return;
    final ready = _scrollController.hasClients;
    if (ready != _navigationReady) {
      setState(() => _navigationReady = ready);
    }
  }

  void selectPiece(int pieceIndex) {
    final state = ref.read(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);

    if (pieceIndex >= 0 && pieceIndex < state.availablePieces.length) {
      final piece = state.availablePieces[pieceIndex];
      notifier.selectPiece(piece);
      _centerPiece(piece.id);
    }
  }

  @override
  void didUpdateWidget(covariant PentoscopePieceSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLandscape != widget.isLandscape ||
        oldWidget.pieceCellSize != widget.pieceCellSize) {
      _interruptNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = context as WidgetRef;
    final state = ref.watch(pentoscopeProvider);
    ref.listen(
      pentoscopeProvider.select(
        (state) => (
          state.selectedPiece?.id,
          state.placedPieces.length,
          state.strategyActions.total,
        ),
      ),
      (_, _) => _interruptNavigation(),
    );
    ref.listen(pentoscopeProvider.select((state) => state.availablePieces), (
      _,
      _,
    ) {
      _interruptNavigation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final position = _scrollController.position;
        _scrollController.jumpTo(
          position.pixels.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        _refreshNavigation();
      });
    });
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final illustratedLayout =
        state.isIllustratedMode &&
            state.puzzle != null &&
            state.illustratedSolution != null
        ? IllustratedPuzzleLayout.fromSolution(
            state.illustratedSolution!,
            boardWidth: state.puzzle!.size.width,
            boardHeight: state.puzzle!.size.height,
          )
        : null;

    final pieces = state.availablePieces;
    _schedulePreview(state);

    if (pieces.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableExtent = widget.isLandscape
            ? constraints.maxHeight
            : constraints.maxWidth;
        final contentExtent = pieces.fold<double>(
          0,
          (sum, piece) => sum + _pieceMaxDim(piece) * widget.pieceCellSize + 8,
        );
        final showNavigation =
            pieces.length > 1 && contentExtent + 32 > availableExtent;
        final wasCircular = _circular;
        _circular = showNavigation;
        _cycleExtent = contentExtent;
        if (_circular && !wasCircular) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _normalizeCycle();
          });
        }

        final scrollDirection = widget.isLandscape
            ? Axis.vertical
            : Axis.horizontal;

        // Recalcul du débordement après ce layout (le nombre de pièces vient de changer, etc.).
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _refreshNavigation(),
        );

        final listView = LayoutBuilder(
          builder: (context, constraints) {
            final viewport = widget.isLandscape
                ? constraints.maxHeight
                : constraints.maxWidth;
            if (_viewport != viewport) {
              final hadViewport = _viewport != null;
              _viewport = viewport;
              final generation = _animationGeneration;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    hadViewport &&
                    generation == _animationGeneration) {
                  _interruptNavigation();
                  _refreshNavigation();
                }
              });
            }
            final fitsTogether = !showNavigation && pieces.length > 1;
            _leadingPadding = fitsTogether
                ? 16.0
                : math.max(
                    16.0,
                    (viewport -
                            (_pieceMaxDim(pieces.first) * widget.pieceCellSize +
                                8)) /
                        2,
                  );
            final trailing = fitsTogether
                ? 16.0
                : math.max(
                    16.0,
                    (viewport -
                            (_pieceMaxDim(pieces.last) * widget.pieceCellSize +
                                8)) /
                        2,
                  );
            final padding = widget.isLandscape
                ? EdgeInsets.fromLTRB(8, _leadingPadding, 8, trailing)
                : EdgeInsets.fromLTRB(_leadingPadding, 12, trailing, 12);
            return ListView(
              controller: _scrollController,
              // Trois copies visuelles permettent de reboucler sans déplacer les pièces du jeu.
              scrollCacheExtent: ScrollCacheExtent.pixels(contentExtent * 3),
              scrollDirection: scrollDirection,
              padding: padding,
              children: [
                for (final cycle in (_circular ? [0, 1, 2] : [1]))
                  for (final piece in pieces)
                    _buildDraggablePiece(
                      piece,
                      notifier,
                      state,
                      settings,
                      widget.isLandscape,
                      illustratedLayout,
                      cycle: cycle,
                    ),
              ],
            );
          },
        );

        final rack = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _selectionCanceledForCurrentScroll = false;
            }
            if (notification is ScrollUpdateNotification &&
                notification.dragDetails != null &&
                !_selectionCanceledForCurrentScroll) {
              final selection = ref.read(pentoscopeProvider);
              if (selection.selectedPiece != null &&
                  selection.selectedPlacedPiece == null) {
                ref.read(pentoscopeProvider.notifier).cancelSelection();
              }
              _selectionCanceledForCurrentScroll = true;
            }
            if (notification is ScrollEndNotification) {
              _selectionCanceledForCurrentScroll = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _normalizeCycle();
              });
            }
            _refreshNavigation();
            return false;
          },
          child: Listener(
            onPointerDown: (_) => _interruptNavigation(),
            onPointerSignal: (_) => _interruptNavigation(),
            child: listView,
          ),
        );
        if (!showNavigation) return rack;
        return Flex(
          direction: scrollDirection,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: rack),
            _navigationButton(),
          ],
        );
      },
    );
  }

  /// Convertit positionIndex interne en displayPositionIndex pour l'affichage
  int _getDisplayPositionIndex(
    int positionIndex,
    Pento piece,
    bool isLandscape,
  ) {
    return positionIndex; // ✅ plus de -1 / modulo
  }

  /// Dimension max de la pièce (en cases) sur **toutes** ses orientations : côté d'une boîte
  /// carrée qui contient n'importe quelle orientation. Constante par pièce → la boîte ne change
  /// pas quand on tourne la pièce (pas de reflow du rack). I = 5, L/N/Y = 4, les autres = 3.
  int _pieceMaxDim(Pento piece) {
    int maxDim = 1;
    for (int i = 0; i < piece.numOrientations; i++) {
      int minX = 5, minY = 5, maxX = 0, maxY = 0;
      for (final n in piece.orientations[i]) {
        final x = (n - 1) % 5;
        final y = (n - 1) ~/ 5;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
      final w = maxX - minX + 1;
      final h = maxY - minY + 1;
      if (w > maxDim) maxDim = w;
      if (h > maxDim) maxDim = h;
    }
    return maxDim;
  }

  /// Cellule (normalisée) de la pièce sous le doigt au départ du drag. [localGrab] est l'offset
  /// local dans la boîte du widget (côté [box.width] = fixedSize), la pièce étant centrée et rendue
  /// par PieceRenderer (case = pieceCellSize, +4 de marge interne). Renvoie la cellule réelle la
  /// plus proche (le toucher peut tomber sur un creux de la forme). null si la pièce n'a pas de case.
  Point? _grabbedCell(
    Pento piece,
    int positionIndex,
    Offset localGrab,
    Size box,
  ) {
    final cellSize = widget.pieceCellSize;
    final cells = piece.orientations[positionIndex]
        .map((n) => Point((n - 1) % 5, (n - 1) ~/ 5))
        .toList();
    if (cells.isEmpty) return null;
    final minX = cells.map((c) => c.x).reduce(math.min);
    final minY = cells.map((c) => c.y).reduce(math.min);
    final norm = cells.map((c) => Point(c.x - minX, c.y - minY)).toList();
    final wCells = norm.map((c) => c.x).reduce(math.max) + 1;
    final hCells = norm.map((c) => c.y).reduce(math.max) + 1;
    final pieceW = wCells * cellSize + 8;
    final pieceH = hCells * cellSize + 8;
    final topLeftX = (box.width - pieceW) / 2;
    final topLeftY = (box.height - pieceH) / 2;
    // Position du doigt en unités de case dans le repère normalisé de la pièce.
    final gx = (localGrab.dx - topLeftX - 4) / cellSize;
    final gy = (localGrab.dy - topLeftY - 4) / cellSize;
    Point? best;
    double bestD = double.infinity;
    for (final c in norm) {
      final dx = (c.x + 0.5) - gx;
      final dy = (c.y + 0.5) - gy;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  Widget _buildDraggablePiece(
    Pento piece,
    PentoscopeNotifier notifier,
    PentoscopeState state,
    settings,
    bool isLandscape,
    IllustratedPuzzleLayout? illustratedLayout, {
    int cycle = 1,
  }) {
    // Emplacement serré (C6, retour de Paul sur le 3×5) : au lieu d'une boîte carrée de 5 cases
    // pour tout le monde, la boîte fait la **dimension max de la pièce sur toutes ses orientations**
    // (3 à 5 cases). Carrée → n'importe quelle orientation y tient, donc **aucun reflow à la
    // rotation** ; côté = maxDim → les pièces se serrent (la plupart des 3×5 montrent leurs 3
    // pièces) sans jamais rétrécir la case (invariant #3). L'axe croisé garde la pleine épaisseur
    // de barre (5 cases) pour un centrage vertical stable.
    final double cell = widget.pieceCellSize;
    final double thickness = cell * 5 + 8;
    final double pieceBox = _pieceMaxDim(piece) * cell + 8;
    final double slotW = isLandscape ? thickness : pieceBox;
    final double slotH = isLandscape ? pieceBox : thickness;
    int positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    // Convertir pour l'affichage
    int displayPositionIndex = _getDisplayPositionIndex(
      positionIndex,
      piece,
      isLandscape,
    );

    final isSelected = state.selectedPiece?.id == piece.id;

    return SizedBox(
      key: ValueKey(
        cycle == 1 ? 'rack-piece-${piece.id}' : 'rack-copy-$cycle-${piece.id}',
      ),
      width: slotW,
      height: slotH,
      child: Center(
        child: Transform.rotate(
          angle: isLandscape ? -math.pi / 2 : 0.0,
          child: DraggablePieceWidget(
            dragAffinity: isLandscape ? Axis.horizontal : Axis.vertical,
            piece: piece,
            positionIndex: displayPositionIndex,
            isSelected: isSelected,
            selectedPositionIndex: isSelected
                ? displayPositionIndex
                : state.selectedPositionIndex,
            longPressDuration: Duration(
              milliseconds: settings.game.longPressDuration,
            ),
            // Le feedback existe toujours hors plateau, où aucun fantôme de pose ne prend le relais.
            // Le réglage décide seulement s'il reste visible une fois entré sur le plateau.
            showDragFeedback: true,
            // Toute la boîte de la case répond au doigt : le « I » (1 case) s'attrape comme le reste.
            // Carrée (côté = maxDim) → _grabbedCell centre correctement.
            hitBoxSize: pieceBox,
            onSelect: () {
              if (settings.game.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              notifier.selectPiece(piece);
              _centerPiece(piece.id);
            },
            // Départ de drag : ancrer la pièce sur la cellule réellement empoignée (comme le
            // plateau), pour que le placement colle au doigt (fix : viser une case dispo depuis
            // le tiroir).
            onGrab: (localGrab, box) {
              _interruptNavigation();
              setState(() => _pieceDragging = true);
              ref.read(dragOverBoardProvider.notifier).update(false);
              if (settings.game.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              final cell = _grabbedCell(
                piece,
                displayPositionIndex,
                localGrab,
                box,
              );
              // grabLocal (px du toucher dans la boîte) : le plateau reconstruit le doigt réel
              // (details.offset + localGrab) → ancre à la bonne échelle (fin de l'erreur ~1 case).
              notifier.selectPiece(
                piece,
                grabbedCell: cell,
                grabLocal: localGrab,
              );
            },
            onCycle: () {},
            onDragFinished: () {
              if (mounted) setState(() => _pieceDragging = false);
              _normalizeCycle();
            },
            onCancel: () {
              notifier.recordRejectedDrop();
              if (settings.game.enableHaptics) {
                HapticFeedback.lightImpact();
              }
              notifier.cancelSelection();
            },
            // Halo ambré de sélection collé à la pièce (auparavant un Container externe, qui serait
            // devenu un grand carré une fois la boîte tactile élargie).
            childBuilder: (isDragging) {
              final renderer = PieceRenderer(
                piece: piece,
                positionIndex: displayPositionIndex,
                isDragging: isDragging,
                cellSize: widget.pieceCellSize,
                getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
                cellBackgroundBuilder: illustratedLayout == null
                    ? null
                    : (index, size) => IllustratedPuzzleCell(
                        sourceCell: illustratedLayout.cellsForPiece(
                          piece.id,
                        )![index],
                        cellSize: size,
                        boardWidth: illustratedLayout.boardWidth,
                        boardHeight: illustratedLayout.boardHeight,
                      ),
              );
              // Visible dès la prise, rouge hors plateau ou si le placement est interdit.
              if (isDragging) {
                return PieceDragFeedback(
                  piece: piece,
                  positionIndex: displayPositionIndex,
                  cellSize: widget.pieceCellSize,
                  getPieceColor: (id) => settings.ui.getPieceColor(id),
                  showOverBoard: settings.game.showDragFeedback,
                  illustratedSourceCells: illustratedLayout?.cellsForPiece(
                    piece.id,
                  ),
                  illustratedBoardWidth: illustratedLayout?.boardWidth,
                  illustratedBoardHeight: illustratedLayout?.boardHeight,
                );
              }
              // Halo au repos seulement (pièce sélectionnée, immobile).
              if (!isSelected) return renderer;
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    // Halo ambré « sélection » (langage cohérent avec l'ampoule).
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.85),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                    // Contour sombre net PAR-DESSUS le halo : garantit une limite visible même quand
                    // la pièce est elle-même jaune/ambrée (ex. N°3), où l'ambre seul ne contraste pas.
                    // Dernier de la liste = peint au-dessus.
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 1.5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
                child: renderer,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationGeneration++;
    _scrollController.dispose();
    super.dispose();
  }
}
