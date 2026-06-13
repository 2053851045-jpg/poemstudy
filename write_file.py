
import base64, sys
path = sys.argv[1]
content_b64 = sys.argv[2]
content = base64.b64decode(content_b64).decode('utf-8')
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Written:', path)
