// Placeholder content for the top-level "Manage Rituals" sidebar tab.
//
// Note: the existing "Manage Pujas" tab is rendered by `CmsRitualsContent`
// (historical naming). This new screen is reserved for a real CMS rituals
// module (e.g. independent of pujas) and is intentionally a placeholder
// until the API is wired up — mirrors the placeholder style used by the
// Pooja Kit Orders / Refunds tabs.
import 'package:flutter/material.dart';

import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsManageRitualsContent extends StatelessWidget {
  const CmsManageRitualsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ManageRitualsHeader(),
        Divider(height: 1, color: CmsColors.border),
        Expanded(
          child: CmsEmptyState(
            icon: Icons.local_fire_department_outlined,
            title: 'No Rituals Yet',
            subtitle:
                'Create, edit and curate rituals here. Once the rituals API '
                'is wired up the full list will appear in this section.',
          ),
        ),
      ],
    );
  }
}

class _ManageRitualsHeader extends StatelessWidget {
  const _ManageRitualsHeader();

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: 14,
      ),
      color: CmsColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Manage Rituals',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Add and update ritual entries that devotees can browse from '
            'the app.',
            style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
          ),
        ],
      ),
    );
  }
}
