import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../widgets/banner_ad_widget.dart';

class LeaderboardView extends ConsumerWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final myFirebaseId = db.currentFirebaseId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        title: const Text('Liderlik Tablosu', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('registrationDate', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Henüz kimse kayıtlı değil.', style: TextStyle(color: Colors.grey)));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120), 
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String userId = data['id'] ?? '';
                
                final Timestamp? ts = data['registrationDate'] as Timestamp?;
                int daysFree = 0;
                if (ts != null) {
                  final date = ts.toDate();
                  daysFree = DateTime.now().difference(date).inDays;
                }

                final bool isMe = userId == myFirebaseId;
                final String displayName = isMe ? 'Sen' : 'Anonim';

                return FadeInSlide(
                  delay: Duration(milliseconds: 100 + (index * 100).clamp(0, 800)),
                  child: _buildLeaderboardCard(index, displayName, daysFree, isMe),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(int index, String displayName, int daysFree, bool isMe) {
    // 1., 2., 3. için Altın, Gümüş, Bronz temaları
    bool isTop3 = index < 3;
    
    LinearGradient? bgGradient;
    Color? shadowColor;
    Color textColor = isMe ? const Color(0xFF1B5E20) : Colors.grey.shade800;
    Widget avatarChild;

    if (index == 0) {
      bgGradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF57F17)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      shadowColor = const Color(0xFFFFD700).withOpacity(0.5);
      textColor = Colors.white;
      avatarChild = const Icon(Icons.emoji_events_rounded, color: Color(0xFFF57F17), size: 28);
    } else if (index == 1) {
      bgGradient = const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      shadowColor = const Color(0xFF9E9E9E).withOpacity(0.4);
      textColor = Colors.white;
      avatarChild = const Icon(Icons.emoji_events_rounded, color: Color(0xFF757575), size: 28);
    } else if (index == 2) {
      bgGradient = const LinearGradient(colors: [Color(0xFFBCAAA4), Color(0xFF8D6E63)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      shadowColor = const Color(0xFF8D6E63).withOpacity(0.4);
      textColor = Colors.white;
      avatarChild = const Icon(Icons.emoji_events_rounded, color: Color(0xFF5D4037), size: 28);
    } else {
      bgGradient = LinearGradient(colors: [isMe ? const Color(0xFFE8F5E9) : Colors.white, isMe ? const Color(0xFFC8E6C9) : Colors.white]);
      shadowColor = Colors.black.withOpacity(0.04);
      avatarChild = Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 16));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 8)),
        ],
        border: !isTop3 && isMe 
            ? Border.all(color: const Color(0xFF4CAF50), width: 2) 
            : Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: Center(child: avatarChild),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // İçerik kadar yer kaplasın
            children: [
              Text(
                '$daysFree',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1,
                  height: 1.1, // Satır yüksekliğini daraltarak taşmayı önle
                ),
              ),
              Text(
                'GÜN',
                style: TextStyle(
                  fontSize: 12,
                  color: isTop3 ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gelişmiş Giriş Animasyonu (Fade & Slide UP)
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInSlide({super.key, required this.child, required this.delay});

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

