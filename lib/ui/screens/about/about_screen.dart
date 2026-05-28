import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.favorite, size: 80, color: theme.primaryColor),
                const SizedBox(height: 12),
                Text('Health Tracker',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${l10n.version} 3.6.0',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
          'Health Tracker là người bạn đồng hành sức khỏe cá nhân của bạn. '
          'Theo dõi bữa ăn, bài tập, lượng nước uống, giấc ngủ và nhiều hơn nữa. '
          'Luôn duy trì động lực và đạt được mục tiêu sức khỏe cùng chúng tôi!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                _buildTile(
                    context, Icons.privacy_tip, l10n.privacy, null),
                const Divider(height: 1, indent: 56),
                _buildTile(
                    context, Icons.description, l10n.terms, null),
                const Divider(height: 1, indent: 56),
                _buildTile(
                    context, Icons.share, l10n.share, null),
                const Divider(height: 1, indent: 56),
                _buildTile(
                    context, Icons.star_rate, l10n.rate, null),
                const Divider(height: 1, indent: 56),
                _buildTile(
                    context, Icons.mail_outline, l10n.contact, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
