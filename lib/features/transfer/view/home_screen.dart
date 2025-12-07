import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_transfer/features/transfer/view/download_screen.dart';
import 'package:flutter_pos_transfer/features/transfer/view/transfer_dashboard.dart';
import 'package:flutter_pos_transfer/features/transfer/view/upload_screen.dart';
import '../cubit/transfer_cubit.dart';
import '../cubit/transfer_state.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    UploadScreen(),
    DownloadScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS File Transfer'),
        elevation: 2,
        actions: [
          BlocBuilder<TransferCubit, TransferState>(
            builder: (context, state) {
              final activeCount = state.activeTransfers.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.dashboard),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransferDashboard(),
                        ),
                      );
                    },
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.download),
            label: 'Download',
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<TransferCubit, TransferState>(
        builder: (context, state) {
          final activeTransfers = state.activeTransfers;

          if (activeTransfers.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransferDashboard(),
                ),
              );
            },
            icon: const Icon(Icons.sync),
            label: Text('${activeTransfers.length} Active'),
          );
        },
      ),
    );
  }
}