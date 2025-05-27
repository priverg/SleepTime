import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import 'add_sleep_screen.dart';

class SleepListScreen extends StatelessWidget {
  const SleepListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 기록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SleepProvider>(
        builder: (context, sleepProvider, child) {
          final records = sleepProvider.sleepRecords;

          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bedtime, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('아직 수면 기록이 없습니다'),
                  Text('+ 버튼을 눌러 첫 기록을 추가해보세요'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getQualityColor(record.quality),
                    child: Text(
                      '${record.quality}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${record.sleepDuration.inHours}시간 ${record.sleepDuration.inMinutes % 60}분',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.sleepTime.month}/${record.sleepTime.day} ${record.sleepTime.hour}:${record.sleepTime.minute.toString().padLeft(2, '0')} - ${record.wakeTime.hour}:${record.wakeTime.minute.toString().padLeft(2, '0')}',
                      ),
                      if (record.factors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 4.0,
                            children: record.factors
                                .map((factor) => Chip(
                                      label: Text(
                                        factor,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          ),
                        ),
                      if (record.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            record.note,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSleepScreen(
                          existingRecord: record,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddSleepScreen(
                              existingRecord: record,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, sleepProvider, record.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getQualityColor(int quality) {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteDialog(
      BuildContext context, SleepProvider provider, String recordId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: const Text('이 수면 기록을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await provider.deleteSleepRecord(recordId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('수면 기록이 삭제되었습니다.'),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 중 오류가 발생했습니다: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
