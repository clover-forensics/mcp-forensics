# mcp-forensics (dev)

## Docker

Build:

```bash
docker build --no-cache -t mcp-forensics .
```

## Configuration

### Gemini Developer API (AI Studio / free tier)

Set `API_KEY` (e.g. `-e API_KEY=...` for `docker run`). Do not commit real keys.

```bash
# From the repo root — writes appear under ./cases/<case>/logs/
docker run --rm \
  -e API_KEY="$API_KEY" \
  -v "$(pwd)/cases:/app/cases" \
  mcp-forensics \
  python pipeline.py \
    --case /app/cases/example \
    --query "Recover deleted text files from the ext image and extract the secret password" \
    --max-steps 5
```

Note: 

- Use absolute path to local folder for correct volume binding

- You can create your own free Gemini API key through Google AI Studio with any Gmail account.

### Vertex AI (paid GCP / higher quotas)

1. Enable Vertex AI API on your GCP project and pick a region (e.g. `us-central1`).
2. Authenticate with a **service account** JSON (`GOOGLE_APPLICATION_CREDENTIALS`) or Application Default Credentials (`gcloud auth application-default login` on your machine).
3. Set:

| Variable | Meaning |
|----------|---------|
| `GOOGLE_GENAI_USE_VERTEXAI=true` | Also accepted: `USE_VERTEX_AI=true` |
| `GOOGLE_CLOUD_PROJECT` | GCP project id |
| `GOOGLE_CLOUD_LOCATION` | Region (default `us-central1` if unset) |
| `GEMINI_MODEL` | Optional; default `gemini-2.5-flash` |

Example (Docker + service account file on the host):

```bash
docker run --rm \
  -e GOOGLE_GENAI_USE_VERTEXAI=true \
  -e GOOGLE_CLOUD_PROJECT=cmu-14789 \
  -e GOOGLE_CLOUD_LOCATION=us-central1 \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/sa.json \
  -v /absolute/path/to/service-account.json:/secrets/sa.json:ro \
  -v "$(pwd)/cases:/app/cases" \
  mcp-forensics \
  python pipeline.py --case /app/cases/example --query "Recover deleted text files from the ext image and extract the secret password" --max-steps 5
```

Note:

- `/app/cases/example` is the directory that contains your disk image and other accompanying information you provide. The outcome of the investigation (including steps logging) will be saved in the `logs` subfolder under this directory.

- Download the service account credentials from your GCP account and pass it to the container using volume binding.

## (Optional) Shell in container

```bash
docker run -it --rm -v "$(pwd)/cases:/app/cases" mcp-forensics sh
```