dir=$(mktemp -d)
echo 'FROM --platform=linux/amd64 debian:latest' > "$dir/Dockerfile"
docker buildx build --load -t test-amd64-in-dockerfile "$dir"

docker image inspect test-amd64-in-dockerfile --format '{{.Architecture}}'
digest=$(docker image inspect test-amd64-in-dockerfile --format '{{.Id}}')
docker save test-amd64-in-dockerfile | tar -xO blobs/sha256/${digest#sha256:} | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'manifests' in data:
    print('Manifest list found:')
    for m in data['manifests']:
        p = m.get('platform', {})
        t = m.get('annotations', {}).get('vnd.docker.reference.type', 'image')
        print(f'  type={t} arch={p.get(\"architecture\")} os={p.get(\"os\")} variant={p.get(\"variant\", \"\")}')
else:
    print('No manifest list (single manifest)')
"