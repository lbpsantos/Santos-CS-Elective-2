import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import '../providers/nickname_provider.dart';

// Opens the nickname editor for a Pokemon.
void showNicknameDialog(BuildContext context, Pokemon pokemon) {
  showDialog(
    context: context,
    builder: (context) => NicknameDialog(pokemon: pokemon),
  );
}

// Dialog for adding, editing or removing a nickname.
// Stateful because it owns a TextEditingController that needs to be disposed.
class NicknameDialog extends ConsumerStatefulWidget {
  final Pokemon pokemon;

  const NicknameDialog({super.key, required this.pokemon});

  @override
  ConsumerState<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends ConsumerState<NicknameDialog> {
  late TextEditingController nicknameController;

  @override
  void initState() {
    super.initState();
    // Start with the current nickname so the user can edit it.
    final currentNickname = ref.read(nicknameProvider)[widget.pokemon.id];
    nicknameController = TextEditingController(text: currentNickname);
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  void saveNickname() {
    ref
        .read(nicknameProvider.notifier)
        .setNickname(widget.pokemon.id, nicknameController.text);
    Navigator.pop(context);
  }

  void removeNickname() {
    ref.read(nicknameProvider.notifier).removeNickname(widget.pokemon.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nicknames = ref.watch(nicknameProvider);
    final hasNickname = nicknames.containsKey(widget.pokemon.id);

    return AlertDialog(
      title: Text('Nickname for ${widget.pokemon.displayName}'),
      content: TextField(
        controller: nicknameController,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nickname',
          hintText: 'ex: Sparky',
          border: OutlineInputBorder(),
        ),
        // Pressing enter on the keyboard also saves.
        onSubmitted: (_) => saveNickname(),
      ),
      actions: [
        // Only show Remove if there is a nickname to remove.
        if (hasNickname)
          TextButton(
            onPressed: removeNickname,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: saveNickname, child: const Text('Save')),
      ],
    );
  }
}
