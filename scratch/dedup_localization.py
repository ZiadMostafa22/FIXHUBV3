import re

file_path = r'd:\FIXHUB_ANTI\MVVM_FIXHUB\lib\core\localization\app_localizations.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

def clean_map(map_name, content):
    pattern = rf"'{map_name}': \{{(.*?)\}},"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content
    
    map_body = match.group(1)
    lines = map_body.split('\n')
    
    seen_keys = {}
    new_lines = []
    
    for line in lines:
        key_match = re.search(r"'(.*?)':", line)
        if key_match:
            key = key_match.group(1)
            if key in seen_keys:
                print(f"Duplicate key found in {map_name}: {key}")
                # If they are identical, just skip. If different, maybe warn?
                # For now, we'll keep the FIRST one as it's usually the one we want to keep if we are deduplicating.
                continue
            seen_keys[key] = line
            new_lines.append(line)
        else:
            new_lines.append(line)
            
    new_body = '\n'.join(new_lines)
    return content.replace(map_body, new_body)

new_content = clean_map('en', content)
new_content = clean_map('ar', new_content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)
