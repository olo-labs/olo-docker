# Reference — directory, Compose files, scripts, ports

## Repository directory structure

```
olo-docker/
├── README.md                 # Main quick start (root README)
├── LICENSE
├── install.sh                # Root: runs dev|prod|demo install (default: dev)
├── install.bat               # Windows: same
├── docs/                     # This documentation
│   ├── README.md
│   ├── architecture.md
│   └── reference.md
├── dev/                      # Full OLO development platform
│   ├── install.sh / install.bat
│   ├── docker-compose-*.yml  # Split by concern (see table below)
│   ├── configuration/        # DB init, env samples, worker JSON, Temporal, pgAdmin, RedisInsight
│   └── scripts/              # Post-up model pulls (Ollama, LocalAI)
├── prod/                     # Minimal production template
│   ├── docker-compose.yml
│   ├── .env.example
│   └── install.sh / install.bat
└── demo/                     # Minimal demo (DB + optional app profile)
    ├── docker-compose.yml
    └── install.sh / install.bat
```

**IDE:** `.idea/` holds JetBrains/Cursor project metadata — not required for runtime.

---

## Install scripts (what runs when)

| Script | Behavior |
|--------|----------|
| `install.sh` / `install.bat` (repo root) | Validates Docker (Unix script); delegates to `dev/install.sh`, `prod/install.sh`, or `demo/install.sh`. Argument: `dev` (default), `prod`, or `demo`. |
| `dev/install.sh` | Creates `olo-net`, pulls OLO images, prompts for optional AI (speech/image/video), merges compose files, `docker compose -p olo up -d`, runs `ollama-pull-models.sh` and `openai-oss-pull-models.sh`. **Text AI is always included.** |
| `dev/install.bat` | Same as above on Windows; uses PowerShell for model scripts; exits non-zero if `docker compose up` fails. |
| `prod/install.sh` / `install.bat` | Requires `prod/.env`; `docker compose up -d` in `prod/`. |
| `demo/install.sh` / `install.bat` | `docker compose up -d` in `demo/`. |

**Dev AI selection (installers):**

- Always: **text** AI (`docker-compose-ai-text.yml`).
- Optional prompts: **speech** (`docker-compose-ai-audio.yml`), **image** (`docker-compose-ai-image.yml`), **video** (`docker-compose-ai-video.yml`). Empty answer = skip.
- Core services are always part of the compose file list: db, cache, Elasticsearch, vectordb, Temporal, OLO services.

---

## Docker Compose files (`dev/`)

Compose uses **multiple `-f` files** merged into one project (`olo`). Order matters when the same service name appears twice — **later files override** earlier ones.

| File | Purpose | Main services |
|------|---------|---------------|
| `docker-compose-db.yml` | PostgreSQL + pgAdmin | `db`, `pgadmin` |
| `docker-compose-cache.yml` | Redis + RedisInsight | `redis`, `redisinsight` |
| `docker-compose-ElasticSearch.yml` | Elasticsearch + Kibana | `elasticsearch`, `kibana` |
| `docker-compose-vectordb.yml` | Vector database | `qdrant` |
| `docker-compose-temporal.yml` | Workflows + admin tools + UI | `temporal`, `temporal-admin-tools`, `temporal-ui` |
| `docker-compose-olo.yml` | OLO core app | `olo`, `olo-worker`, `olo-ui`, `olo-chat` |
| `docker-compose-ai-text.yml` | Text LLM stack | `openai-oss` (LocalAI), `ollama` |
| `docker-compose-ai-audio.yml` | Speech/TTS/STT (optional) | `openai-oss`, `ollama` (separate volumes — same service names as text if both loaded; prefer one or understand merge rules) |
| `docker-compose-ai-image.yml` | Image generation | `stable-diffusion`, `invokeai`, `comfyui` |
| `docker-compose-ai-video.yml` | Video workflows | `comfyui` (video-oriented) |

**Networks:** Every file declares `olo-net` as `external: true` — the network must exist before `compose up`.

**GPU:** AI compose files use `deploy.resources.reservations.devices` for NVIDIA; host needs [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

---

## Scripts (`dev/scripts/`)

| Script | Role |
|--------|------|
| `ollama-pull-models.ps1` / `.sh` | Finds a running container whose name contains `ollama`, runs `ollama pull` for each model in the list. Streams progress (stdout/stderr). Large models (e.g. 70B) take a long time. |
| `openai-oss-pull-models.ps1` / `.sh` | Finds LocalAI (`openai-oss`), calls `POST /models/apply` on **host** ports for text and audio stacks (see port table). Installs gallery models by ID. |

PowerShell is used from `dev/install.bat`; shell scripts from `dev/install.sh`.

---

## Configuration (`dev/configuration/`)

| Path | Role |
|------|------|
| `envirinment/database.env` | Typo in folder name is historical; referenced by db/pgadmin compose for credentials. |
| `database-initialization/*.sql` | Runs on first Postgres init (mounted to `/docker-entrypoint-initdb.d`). |
| `olo-configuration/default/*.json` | Regional `WorkflowDefinition` presets for the **olo** API (`OLO_CONFIGURATION_DIR`). Mounted at `/app/olo-configuration` in the `olo` container. Keep in sync with `olo-mono/olo-configuration` and `olo/olo-configuration`. |
| `olo-worker/config/*.json` | Worker queue and feature config; mounted into `olo-worker`. |
| `olo-worker/*.json` | Additional worker-related JSON at repo layout level. |
| `temporal/dynamicconfig/development-sql.yaml` | Temporal dynamic config (referenced by Temporal container). |
| `pgadmin/servers.json` | Pre-seeded pgAdmin server list. |
| `redisinsight/connections.json` | Pre-seeded RedisInsight connections. |

---

## Host port map (dev) — quick lookup

These are **host:container** mappings. Use **left** port in browser/`curl` from the host. **Right** port is inside the container.

| Service | Host port (typical) | Container port |
|---------|---------------------|----------------|
| OLO API | 47080 | 7080 |
| OLO UI | 43001 | 80 |
| OLO Chat | 43000 | 80 |
| PostgreSQL | 45432 | 5432 |
| pgAdmin | 48081 | 80 |
| Redis | 46379 | 6379 |
| RedisInsight | 45540 | 5540 |
| Elasticsearch HTTP | 29200 | 9200 |
| Elasticsearch transport | 39400 | 9300 |
| Kibana | 45601 | 5601 |
| Qdrant HTTP / gRPC | 46333 / 46334 | 6333 / 6334 |
| Temporal (ports) | 48001 / 47233 | 8000 / 7233 |
| Temporal UI | 48092 | 8080 |
| LocalAI text | 48090 | 8080 |
| Ollama text | 51435 | 11434 |
| LocalAI audio | 48082 | 8080 |
| Ollama audio | 51434 | 11434 |
| Stable Diffusion | 47860 | 7860 |
| InvokeAI | 49090 | 9090 |
| ComfyUI image | 48188 | 8188 |
| ComfyUI video | 48189 | 8188 |

Exact values may drift — always check the `ports:` section in the corresponding YAML if something fails to bind.

### Port conflicts on Windows

Windows can reserve port ranges (Hyper-V, NAT, etc.). If Docker reports **forbidden by its access permissions** on bind, pick another **host** port in the compose file (left side only) and update any script or README that references that URL.

---

## `demo/` and `prod/` compose

| File | Services | Notes |
|------|----------|--------|
| `demo/docker-compose.yml` | `app` (profile `app`), `db` | App uses `your-app:latest`; DB exposed on high host port. |
| `prod/docker-compose.yml` | `app`, `db` | DB **not** published; requires `prod/.env` for secrets. |

---

## Internal DNS quick reference (inside `olo-net`)

Use these from **other containers** (worker, API), not from arbitrary host scripts unless port-forwarded:

- `redis:6379`
- `db:5432`
- `temporal:7233`
- `elasticsearch:9200`
- `qdrant:6333`
- `ollama:11434` (when that service is up)
- `openai-oss:8080` (LocalAI internal listener)

Callback URLs aimed at **your browser or host tools** may use `localhost` and the **mapped host port** (e.g. OLO API callback base URL in `docker-compose-olo.yml`).

---

## Related reading

- [Architecture](architecture.md) — diagrams and flows
- [README](../README.md) — install commands and tables
