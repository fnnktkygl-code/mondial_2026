import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../l10n/translations.dart';
import 'team_flag.dart';

class TeamSelectorBottomSheet extends StatefulWidget {
  final String lang;
  final String title;
  final String? selectedTeamCode;
  final List<String> teamCodes;
  final ValueChanged<String> onTeamSelected;

  const TeamSelectorBottomSheet({
    super.key,
    required this.lang,
    required this.title,
    required this.selectedTeamCode,
    required this.teamCodes,
    required this.onTeamSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String lang,
    required String title,
    required String? selectedTeamCode,
    required List<String> teamCodes,
    required ValueChanged<String> onTeamSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TeamSelectorBottomSheet(
        lang: lang,
        title: title,
        selectedTeamCode: selectedTeamCode,
        teamCodes: teamCodes,
        onTeamSelected: onTeamSelected,
      ),
    );
  }

  @override
  State<TeamSelectorBottomSheet> createState() => _TeamSelectorBottomSheetState();
}

class _TeamSelectorBottomSheetState extends State<TeamSelectorBottomSheet> {
  String _searchQuery = '';
  late List<String> _filteredTeams;

  @override
  void initState() {
    super.initState();
    _filteredTeams = widget.teamCodes;
  }

  void _filterTeams(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTeams = widget.teamCodes;
      } else {
        _filteredTeams = widget.teamCodes.where((code) {
          final name = AppTranslations.getTeam(widget.lang, code).toLowerCase();
          return name.contains(query.toLowerCase()) || code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderMid,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDim),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterTeams,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: AppTranslations.get(widget.lang, 'searchTeams'),
                hintStyle: const TextStyle(color: AppColors.textDim),
                prefixIcon: const Icon(Icons.search, color: AppColors.textDim),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          // Team List
          Expanded(
            child: _filteredTeams.isEmpty
                ? Center(
                    child: Text(
                      AppTranslations.get(widget.lang, 'noTeamsFound'),
                      style: const TextStyle(color: AppColors.textDim, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTeams.length,
                    itemBuilder: (context, index) {
                      final code = _filteredTeams[index];
                      final name = AppTranslations.getTeam(widget.lang, code);
                      final isSelected = widget.selectedTeamCode?.toLowerCase() == code.toLowerCase();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: TeamFlagWidget(
                            code: code,
                            width: 36,
                            height: 24,
                            borderRadius: 6,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? AppColors.accent : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.accent, size: 24)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onTap: () {
                            widget.onTeamSelected(code);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
