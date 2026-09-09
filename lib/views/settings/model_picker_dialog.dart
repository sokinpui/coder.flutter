import 'package:flutter/material.dart';

import '../../core/widgets/generic_picker_dialog.dart';

class ModelPickerDialog extends StatelessWidget {
  const ModelPickerDialog({
    super.key,
    required this.models,
    required this.activeModel,
    required this.onModelSelected,
  });

  final List<String> models;
  final String activeModel;
  final ValueChanged<String> onModelSelected;

  List<String> get _resolvedModels {
    if (models.contains(activeModel)) {
      return models;
    }
    return [activeModel, ...models];
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolvedModels.map((m) {
      return PickerItem<String>(id: m, title: m, data: m);
    }).toList();

    return GenericPickerDialog<String>(
      title: 'Switch Model',
      titleIcon: Icons.memory,
      searchPlaceholder: 'Fuzzy search models... (↑/↓ navigate, Enter select)',
      emptyMessage: 'No matching models found',
      items: items,
      activeId: activeModel,
      onSelected: (item) => onModelSelected(item.data),
    );
  }
}
