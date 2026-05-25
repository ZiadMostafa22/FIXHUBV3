import 'dart:io';

void main() {
  final dir = Directory('lib');
  final emojis = ['✅', '❌', '🚀', '⚠️', '📋', '🔧', '💰', '💬', '🤖', '🎉', '👍', '💳'];
  
  int count = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool changed = false;
      
      for (final emoji in emojis) {
        if (content.contains(emoji)) {
          // Replace emoji and any following spaces
          content = content.replaceAll(RegExp('$emoji\\s*'), '');
          changed = true;
        }
      }
      
      if (changed) {
        entity.writeAsStringSync(content);
        count++;
        print('Updated: ${entity.path}');
      }
    }
  }
  
  print('Removed emojis from $count files.');
}
