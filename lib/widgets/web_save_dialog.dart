import 'package:flutter/material.dart';

class WebSaveDialog extends StatefulWidget {
  const WebSaveDialog({Key? key}) : super(key: key);

  @override
  _WebSaveDialogState createState() => _WebSaveDialogState();
}

class _WebSaveDialogState extends State<WebSaveDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _saveToLocalStorage = true;

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
            title: const Text('Save to browser storage'),
            subtitle:
                const Text('Keep this drawing in your browser for later use'),
            value: _saveToLocalStorage,
            onChanged: (value) {
              setState(() {
                _saveToLocalStorage = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (!_saveToLocalStorage)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'The drawing will be downloaded to your device',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
              'saveToLocalStorage': _saveToLocalStorage,
            });
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
