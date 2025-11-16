// Modified: 2025-11-16 08:30:00
// lib/widgets/coach_message_widget.dart
// Widget pour afficher les messages du coach IA

import 'package:flutter/material.dart';
import '../services/ai_coach.dart';

/// Widget pour afficher un message du coach
class CoachMessageWidget extends StatefulWidget {
  final CoachMessage message;
  final VoidCallback? onDismiss;
  
  const CoachMessageWidget({
    super.key,
    required this.message,
    this.onDismiss,
  });
  
  @override
  State<CoachMessageWidget> createState() => _CoachMessageWidgetState();
}

class _CoachMessageWidgetState extends State<CoachMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
    
    // Auto-dismiss pour les messages de faible priorité
    if (widget.message.priority == MessagePriority.low) {
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) _dismiss();
      });
    } else if (widget.message.priority == MessagePriority.medium) {
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted) _dismiss();
      });
    }
  }
  
  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Color _getBackgroundColor() {
    switch (widget.message.type) {
      case MessageType.welcome:
        return Colors.blue.shade50;
      case MessageType.tutorial:
        return Colors.purple.shade50;
      case MessageType.encouragement:
        return Colors.green.shade50;
      case MessageType.hint:
        return Colors.orange.shade50;
      case MessageType.geometry:
        return Colors.indigo.shade50;
      case MessageType.milestone:
        return Colors.amber.shade50;
      case MessageType.victory:
        return Colors.pink.shade50;
    }
  }
  
  Color _getBorderColor() {
    switch (widget.message.type) {
      case MessageType.welcome:
        return Colors.blue.shade300;
      case MessageType.tutorial:
        return Colors.purple.shade300;
      case MessageType.encouragement:
        return Colors.green.shade300;
      case MessageType.hint:
        return Colors.orange.shade300;
      case MessageType.geometry:
        return Colors.indigo.shade300;
      case MessageType.milestone:
        return Colors.amber.shade300;
      case MessageType.victory:
        return Colors.pink.shade300;
    }
  }
  
  IconData _getIcon() {
    switch (widget.message.type) {
      case MessageType.welcome:
        return Icons.waving_hand;
      case MessageType.tutorial:
        return Icons.school;
      case MessageType.encouragement:
        return Icons.thumb_up;
      case MessageType.hint:
        return Icons.lightbulb_outline;
      case MessageType.geometry:
        return Icons.functions;
      case MessageType.milestone:
        return Icons.emoji_events;
      case MessageType.victory:
        return Icons.celebration;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getBorderColor(), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar du coach
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _getBorderColor(), width: 2),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getBorderColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getBorderColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message.text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bouton fermer
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay pour afficher les messages du coach
class CoachOverlay extends StatefulWidget {
  final Stream<CoachMessage> messageStream;
  final Widget child;
  
  const CoachOverlay({
    super.key,
    required this.messageStream,
    required this.child,
  });
  
  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  final List<CoachMessage> _messages = [];
  
  @override
  void initState() {
    super.initState();
    widget.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
        // Garder max 3 messages
        if (_messages.length > 3) {
          _messages.removeAt(0);
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Messages en haut de l'écran
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              children: _messages.map((message) {
                return CoachMessageWidget(
                  message: message,
                  onDismiss: () {
                    setState(() {
                      _messages.remove(message);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

