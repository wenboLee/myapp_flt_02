import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_2x/video_2x.dart';
import 'package:myapp_flt_02/pages/video_merge/video_merge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    VideoMergePage(),
    Video2xPage(),
    _EmptyTab(label: ''),
    _EmptyTab(label: ''),
    _EmptyTab(label: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'video_merge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.slow_motion_video),
            label: 'video_2x',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.circle_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.circle_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.circle_outlined), label: ''),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label.isEmpty ? 'Empty Tab' : label));
  }
}
