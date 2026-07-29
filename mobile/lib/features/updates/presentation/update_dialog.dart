import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../data/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppReleaseInfo releaseInfo;

  const UpdateDialog({super.key, required this.releaseInfo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: AppTheme.primaryAccent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update Available (${releaseInfo.tagName})',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('A new version of RenCloud is available on GitHub!', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Release Notes:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              releaseInfo.releaseNotes,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final url = releaseInfo.apkDownloadUrl.isNotEmpty
                ? releaseInfo.apkDownloadUrl
                : 'https://github.com/addiigg/mc-hosting-app/releases/latest';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.download),
          label: const Text('Download Update'),
        ),
      ],
    );
  }
}
