import 'package:flutter/material.dart';

// 🎯 DE64 Tournament Bracket - Clean & Simple Version
class DE64Bracket extends StatefulWidget {
  const DE64Bracket({super.key});

  @override
  State<DE64Bracket> createState() => _DE64BracketState();
}

class _DE64BracketState extends State<DE64Bracket>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 4 groups + 1 cross-bracket
    _pageController = PageController();

    // Sync tab and page controller
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepOrange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.grid_view, color: Colors.deepOrange[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DE64 SABO Format',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange[700],
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '64 người • 111 trận đấu\n4 bảng (26 trận/bảng) + Chung kết liên bảng (7 trận)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Text(
                  'Bảng A',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Tab(
                child: Text(
                  'Bảng B',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Tab(
                child: Text(
                  'Bảng C',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Tab(
                child: Text(
                  'Bảng D',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Tab(
                child: Text(
                  'Chung kết',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            indicator: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            dividerColor: Colors.transparent,
          ),
        ),

        const SizedBox(height: 16),

        // Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            children: [
              _buildGroupView('A', Colors.red),
              _buildGroupView('B', Colors.blue),
              _buildGroupView('C', Colors.green),
              _buildGroupView('D', Colors.purple),
              _buildCrossBracketView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupView(String groupName, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Group Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.group, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Bảng $groupName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '16 người • Modified DE16\n26 trận → 2 đại diện',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Group Structure
          _buildGroupStructure(groupName, color),
        ],
      ),
    );
  }

  Widget _buildGroupStructure(String groupName, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Winners Bracket
        _buildBracketSection(
          title: '🏆 Winners Bracket',
          subtitle: '15 trận (8→4→2→1)',
          color: color,
          matches: [
            'Round 1: 8 trận (16→8)',
            'Round 2: 4 trận (8→4)',
            'Round 3: 2 trận (4→2)',
            'Winners Final: 1 trận → Đại diện 1',
          ],
        ),

        const SizedBox(height: 16),

        // Losers Bracket
        _buildBracketSection(
          title: '📉 Losers Bracket',
          subtitle: '11 trận (4+4+2+1)',
          color: color.withValues(alpha: 0.7),
          matches: [
            'LB Round 1: 4 trận (thua WB R1)',
            'LB Round 2: 4 trận (vs thua WB R2)',
            'LB Round 3: 2 trận (consolidation)',
            'Losers Final: 1 trận → Đại diện 2',
          ],
        ),
      ],
    );
  }

  Widget _buildBracketSection({
    required String title,
    required String subtitle,
    required Color color,
    required List<String> matches,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 6,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCrossBracketView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cross-Bracket Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                const SizedBox(height: 8),
                Text(
                  'Chung kết liên bảng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[700],
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '8 đại diện từ 4 bảng\n7 trận → 1 vô địch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cross-Bracket Structure
          _buildCrossBracketStructure(),
        ],
      ),
    );
  }

  Widget _buildCrossBracketStructure() {
    return Column(
      children: [
        // Quarter-Finals
        _buildBracketSection(
          title: '🎯 Tứ kết',
          subtitle: '4 trận (8→4)',
          color: Colors.red,
          matches: [
            'QF1: A1 vs B2',
            'QF2: B1 vs A2',
            'QF3: C1 vs D2',
            'QF4: D1 vs C2',
          ],
        ),

        const SizedBox(height: 16),

        // Semi-Finals
        _buildBracketSection(
          title: '🚀 Bán kết',
          subtitle: '2 trận (4→2)',
          color: Colors.blue,
          matches: [
            'SF1: QF1 Winner vs QF2 Winner',
            'SF2: QF3 Winner vs QF4 Winner',
          ],
        ),

        const SizedBox(height: 16),

        // Final
        _buildBracketSection(
          title: '👑 Chung kết',
          subtitle: '1 trận (2→1)',
          color: Colors.amber,
          matches: [
            'Final: SF1 Winner vs SF2 Winner',
            '🏆 Winner = DE64 Champion',
          ],
        ),

        const SizedBox(height: 20),

        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Text(
                '📊 Tổng kết DE64',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Bảng', '4'),
                  _buildStat('Người', '64'),
                  _buildStat('Trận', '111'),
                  _buildStat('Đại diện', '8'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.deepOrange[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}