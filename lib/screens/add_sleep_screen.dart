import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sleep_record.dart';
import '../models/sleep_factor.dart';
import '../providers/sleep_provider.dart';

class AddSleepScreen extends StatefulWidget {
  final SleepRecord? existingRecord;

  const AddSleepScreen({super.key, this.existingRecord});

  @override
  State<AddSleepScreen> createState() => _AddSleepScreenState();
}

class _AddSleepScreenState extends State<AddSleepScreen> {
  DateTime _sleepTime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();
  int _quality = 3;
  List<String> _selectedFactors = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _sleepTime = record.sleepTime;
      _wakeTime = record.wakeTime;
      _quality = record.quality;
      _selectedFactors = List.from(record.factors);
      _noteController.text = record.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecord == null ? '수면 기록 추가' : '수면 기록 수정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 취침 시간
            Card(
              child: ListTile(
                leading: const Icon(Icons.bedtime),
                title: const Text('취침 시간'),
                subtitle: Text(
                  '${_sleepTime.year}/${_sleepTime.month}/${_sleepTime.day} ${_sleepTime.hour}:${_sleepTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _selectDateTime(context, true),
              ),
            ),
            const SizedBox(height: 8),

            // 기상 시간
            Card(
              child: ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('기상 시간'),
                subtitle: Text(
                  '${_wakeTime.year}/${_wakeTime.month}/${_wakeTime.day} ${_wakeTime.hour}:${_wakeTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _selectDateTime(context, false),
              ),
            ),
            const SizedBox(height: 16),

            // 수면의 질
            Text(
              '수면의 질',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final quality = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _quality = quality;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _quality == quality
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                    child: Center(
                      child: Text(
                        '$quality',
                        style: TextStyle(
                          color:
                              _quality == quality ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // 수면 방해 요인
            Text(
              '수면 방해 요인',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: SleepFactor.all.map((factor) {
                final isSelected = _selectedFactors.contains(factor);
                return FilterChip(
                  label: Text(factor),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFactors.add(factor);
                      } else {
                        _selectedFactors.remove(factor);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 메모
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '수면에 대한 추가 메모를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const Spacer(),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSleepRecord,
                child: Text(widget.existingRecord == null ? '저장' : '수정'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isSleepTime) async {
    final currentDateTime = isSleepTime ? _sleepTime : _wakeTime;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (isSleepTime) {
            _sleepTime = newDateTime;
          } else {
            _wakeTime = newDateTime;
          }
        });
      }
    }
  }

  void _saveSleepRecord() async {
    if (_wakeTime.isBefore(_sleepTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기상 시간이 취침 시간보다 빠를 수 없습니다.'),
        ),
      );
      return;
    }

    try {
      final record = SleepRecord(
        id: widget.existingRecord?.id,
        sleepTime: _sleepTime,
        wakeTime: _wakeTime,
        quality: _quality,
        factors: _selectedFactors,
        note: _noteController.text,
      );

      final sleepProvider = Provider.of<SleepProvider>(context, listen: false);

      if (widget.existingRecord == null) {
        await sleepProvider.addSleepRecord(record);
      } else {
        await sleepProvider.updateSleepRecord(record);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingRecord == null
              ? '수면 기록이 저장되었습니다.'
              : '수면 기록이 수정되었습니다.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
