import 'package:flutter/material.dart';

class SaveDialog extends StatefulWidget {
  const SaveDialog({Key? key}) : super(key: key);

  @override
  _SaveDialogState createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _saveToGallery = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Drawing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Drawing Name',
              hintText: 'Enter a name for your drawing',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Also save to device gallery'),
            value: _saveToGallery,
            onChanged: (value) {
              setState(() {
                _saveToGallery = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.isEmpty
                  ? 'Drawing ${DateTime.now().toString().substring(0, 16)}'
                  : _nameController.text,
              'saveToGallery': _saveToGallery,
            });
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
