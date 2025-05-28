import 'package:flutter/material.dart';
import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    // Simulate loading analytics data
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _analytics = _generateSampleAnalytics();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _generateSampleAnalytics() {
    final now = DateTime.now();
    return {
      'totalViews': 1234567,
      'totalLikes': 89012,
      'totalShares': 12345,
      'totalComments': 23456,
      'avgWatchTime': 25.6,
      'retentionRate': 0.78,
      'engagementRate': 0.156,
      'topPerformingReels': [
        {
          'id': 'reel_1',
          'title': 'Amazing sunset view',
          'views': 45000,
          'likes': 3200,
          'engagement': 0.185,
        },
        {
          'id': 'reel_2',
          'title': 'Cooking adventure',
          'views': 38000,
          'likes': 2800,
          'engagement': 0.174,
        },
        {
          'id': 'reel_3',
          'title': 'Travel memories',
          'views': 32000,
          'likes': 2400,
          'engagement': 0.162,
        },
      ],
      'viewsByDay': [
        {'day': 'Mon', 'views': 15000},
        {'day': 'Tue', 'views': 18000},
        {'day': 'Wed', 'views': 22000},
        {'day': 'Thu', 'views': 19000},
        {'day': 'Fri', 'views': 25000},
        {'day': 'Sat', 'views': 35000},
        {'day': 'Sun', 'views': 28000},
      ],
      'audienceData': {
        'demographics': {
          '18-24': 35,
          '25-34': 28,
          '35-44': 20,
          '45-54': 12,
          '55+': 5,
        },
        'topCountries': [
          {'country': 'United States', 'percentage': 32},
          {'country': 'India', 'percentage': 18},
          {'country': 'Brazil', 'percentage': 12},
          {'country': 'United Kingdom', 'percentage': 8},
          {'country': 'Germany', 'percentage': 6},
        ],
      },
      'performance': {
        'cacheHitRate': 0.87,
        'avgLoadTime': 1.2,
        'errorRate': 0.003,
        'bandwidthSaved': '45 GB',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading analytics...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: 20),
                  _buildPerformanceMetrics(),
                  const SizedBox(height: 20),
                  _buildTopPerformingReels(),
                  const SizedBox(height: 20),
                  _buildViewsChart(),
                  const SizedBox(height: 20),
                  _buildAudienceInsights(),
                  const SizedBox(height: 20),
                  _buildTechnicalMetrics(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Views',
                    _formatNumber(_analytics['totalViews']),
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Total Likes',
                    _formatNumber(_analytics['totalLikes']),
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Shares',
                    _formatNumber(_analytics['totalShares']),
                    Icons.share,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Total Comments',
                    _formatNumber(_analytics['totalComments']),
                    Icons.comment,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressMetric(
              'Avg Watch Time',
              '${_analytics['avgWatchTime']}s',
              0.85,
              Colors.purple,
            ),
            _buildProgressMetric(
              'Retention Rate',
              '${(_analytics['retentionRate'] * 100).toInt()}%',
              _analytics['retentionRate'],
              Colors.teal,
            ),
            _buildProgressMetric(
              'Engagement Rate',
              '${(_analytics['engagementRate'] * 100).toStringAsFixed(1)}%',
              _analytics['engagementRate'],
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetric(String title, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingReels() {
    final topReels = _analytics['topPerformingReels'] as List;
    
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performing Reels',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...topReels.map((reel) {
              final index = topReels.indexOf(reel);
              return _buildReelRankingItem(
                index + 1,
                reel['title'],
                '${_formatNumber(reel['views'])} views',
                '${_formatNumber(reel['likes'])} likes',
                reel['engagement'],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReelRankingItem(
    int rank,
    String title,
    String views,
    String likes,
    double engagement,
  ) {
    final rankColors = [Colors.amber, Colors.grey, Colors.brown];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : Colors.blue;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$views • $likes • ${(engagement * 100).toStringAsFixed(1)}% engagement',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewsChart() {
    final viewsByDay = _analytics['viewsByDay'] as List;
    final maxViews = viewsByDay.map((e) => e['views'] as int).reduce((a, b) => a > b ? a : b);
    
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Views by Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: viewsByDay.map((data) {
                  final height = (data['views'] / maxViews) * 150;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatNumber(data['views']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['day'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceInsights() {
    final audienceData = _analytics['audienceData'];
    final demographics = audienceData['demographics'] as Map<String, dynamic>;
    final topCountries = audienceData['topCountries'] as List;
    
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audience Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Age Demographics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...demographics.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text(
              'Top Countries',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...topCountries.take(3).map((country) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      country['country'],
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${country['percentage']}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalMetrics() {
    final performance = _analytics['performance'];
    
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTechMetricCard(
                    'Cache Hit Rate',
                    '${(performance['cacheHitRate'] * 100).toInt()}%',
                    Icons.storage,
                    Colors.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTechMetricCard(
                    'Avg Load Time',
                    '${performance['avgLoadTime']}s',
                    Icons.speed,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTechMetricCard(
                    'Error Rate',
                    '${(performance['errorRate'] * 100).toStringAsFixed(1)}%',
                    Icons.error_outline,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTechMetricCard(
                    'Bandwidth Saved',
                    performance['bandwidthSaved'],
                    Icons.data_usage,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
