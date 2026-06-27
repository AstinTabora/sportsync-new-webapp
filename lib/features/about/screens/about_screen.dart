import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/widgets/app_logo.dart';

const _primary = Color(0xFF005F02);
const _primaryExtralight = Color(0xFFE6F0E6);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);
const _slate700 = Color(0xFF334155);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            _SubPageHeader(),
            _TitleSlide(),
            _ProblemSolutionSlide(),
            _TeamSlide(),
            _AiSdgSlide(),
            _MarketPersonasSlide(),
            _KeyFeaturesSlide(),
            _StrategicGrowthSlide(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: _primary, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'HELP & SUPPORT',
                style: TextStyle(
                  color: _slate400,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ABOUT SPORTSYNC',
                style: TextStyle(
                  color: _primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 1. Title Slide ──────────────────────────────────────────────────────────

class _TitleSlide extends StatelessWidget {
  const _TitleSlide();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 48),
      decoration: const BoxDecoration(
        color: Color(0xFF001F12),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppLogo(size: 44),
          ),

          const SizedBox(height: 20),
          const Text(
            'SPORTSYNC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Seamless Booking for Active Lifestyles',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF86EFAC),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Text(
              'Team Venture  •  EST. 2026',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Problem & Solution ───────────────────────────────────────────────────

class _ProblemSolutionSlide extends StatelessWidget {
  const _ProblemSolutionSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('THE CHALLENGE'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _slate50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('PROBLEM', style: TextStyle(color: _slate400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text(
                        'Court booking in Davao is fragmented — phone calls, walk-ins, no real-time availability.',
                        style: TextStyle(color: _slate700, fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('SOLUTION', style: TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text(
                        'A unified platform for real-time slot booking, GCash payments, and digital receipts.',
                        style: TextStyle(color: _slate700, fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 3. Team ─────────────────────────────────────────────────────────────────

class _TeamSlide extends StatelessWidget {
  const _TeamSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('THE TEAM'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamCard(
                  initials: 'AT',
                  name: 'Astin Tabora',
                  role: 'Frontend Lead',
                  color: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeamCard(
                  initials: 'MJ',
                  name: 'Matthew Jariol',
                  role: 'Backend Architect',
                  color: Color(0xFF0369A1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeamCard(
                  initials: 'GS',
                  name: 'Gian Sambas',
                  role: 'Backend Architect',
                  color: Color(0xFF7E22CE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.initials, required this.name, required this.role, required this.color});
  final String initials, name, role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(color: _slate700, fontSize: 12, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 4),
          Text(role, textAlign: TextAlign.center, style: const TextStyle(color: _slate400, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2)),
        ],
      ),
    );
  }
}

// ─── 4. AI & SDG ─────────────────────────────────────────────────────────────

class _AiSdgSlide extends StatelessWidget {
  const _AiSdgSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('INNOVATION'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AI POWERED', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(height: 6),
                      Text(
                        'Designed with AI assistance for rapid UI prototyping and intelligent slot conflict resolution.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    children: const [
                      Text('SDG', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(height: 4),
                      Text('GOAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text('#3', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      SizedBox(height: 2),
                      Text('Good Health', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF86EFAC), fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5. Market & Personas ────────────────────────────────────────────────────

class _MarketPersonasSlide extends StatelessWidget {
  const _MarketPersonasSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('TARGET USERS'),
          const SizedBox(height: 16),
          _PersonaCard(
            icon: Icons.school,
            name: 'Alex, 22',
            label: 'THE STUDENT',
            description: 'Books badminton courts on weekends. Needs quick availability and cheap options. Pays via GCash.',
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFF4E6FF),
          ),
          const SizedBox(height: 12),
          _PersonaCard(
            icon: Icons.business_center,
            name: 'Mike, 34',
            label: 'THE MANAGER',
            description: 'Organizes weekly team pickleball. Values reliable scheduling and receipt records for expense reports.',
            color: const Color(0xFF0369A1),
            bg: const Color(0xFFE0F2FE),
          ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.icon,
    required this.name,
    required this.label,
    required this.description,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final String name, label, description;
  final Color color, bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(name, style: const TextStyle(color: _slate700, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w600, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 6. Key Features ─────────────────────────────────────────────────────────

class _KeyFeaturesSlide extends StatelessWidget {
  const _KeyFeaturesSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('KEY FEATURES'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _FeatureCard(icon: Icons.calendar_month, title: 'Smart Calendar', description: 'Real-time slot availability with conflict detection'),
                    const SizedBox(height: 12),
                    _FeatureCard(icon: Icons.payment, title: 'GCash Payments', description: 'Scan & pay instantly with QR code confirmation'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _FeatureCard(icon: Icons.map_outlined, title: 'Maps & Info', description: 'Find courts near you with directions and photos'),
                    const SizedBox(height: 12),
                    _FeatureCard(icon: Icons.people_outline, title: 'Community', description: 'Connect with players and join open-play sessions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title, description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _primaryExtralight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: _slate700, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: _slate400, fontSize: 11, fontWeight: FontWeight.w600, height: 1.4)),
        ],
      ),
    );
  }
}

// ─── 7. Strategic Growth ─────────────────────────────────────────────────────

class _StrategicGrowthSlide extends StatelessWidget {
  const _StrategicGrowthSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('STRATEGIC GROWTH'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryExtralight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('TARGET', style: TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(height: 6),
                Text(
                  'Digitize 50% of local courts\nin Davao by end of 2026.',
                  style: TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('RELEASE CRITERIA', style: TextStyle(color: _slate400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(height: 16),
                _CheckItem(done: true, label: 'Court listing & search'),
                _CheckItem(done: true, label: 'Real-time slot booking'),
                _CheckItem(done: true, label: 'GCash & cash payment flows'),
                _CheckItem(done: true, label: 'Email confirmation receipts'),
                _CheckItem(done: false, label: 'Facility admin dashboard'),
                _CheckItem(done: false, label: 'Push notifications'),
                _CheckItem(done: false, label: 'Community & open-play matching'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.done, required this.label});
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? _primary : _slate400,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: done ? _slate700 : _slate400,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: _slate400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }
}
