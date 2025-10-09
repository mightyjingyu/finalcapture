import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/reminder_model.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: userId == null
          ? const Center(child: Text('로그인이 필요합니다'))
          : StreamBuilder<List<ReminderModel>>(
              stream: FirestoreService().getUserRemindersStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                final reminders = snapshot.data ?? [];
                if (reminders.isEmpty) {
                  return const _EmptyView();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final r = reminders[index];
                    return ListTile(
                      leading: Text(r.type.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(r.title),
                      subtitle: Text(
                        '${r.reminderDate.toLocal()}\n${r.metadata['photoFileName'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        r.isCompleted ? Icons.check_circle : Icons.alarm,
                        color: r.isCompleted ? Colors.green : AppColors.textSecondary,
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: reminders.length,
                );
              },
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '스크린샷에 알림을 설정하면 여기에 표시됩니다',
            style: TextStyle(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
