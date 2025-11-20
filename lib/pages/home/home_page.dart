import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_2x/video_2x.dart';
import 'package:myapp_flt_02/pages/video_capture/video_capture.dart';
import 'package:myapp_flt_02/pages/video_merge/video_merge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          VideoMergePage(),
          Video2xPage(),
          VideoCaptureWidget(),
          _EmptyTab(label: ''),
          _EmptyTab(label: ''),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'video_merge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.slow_motion_video),
            label: 'video_2x',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_outlined),
            label: 'capture',
          ),
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
