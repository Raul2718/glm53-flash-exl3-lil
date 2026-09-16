# GLM-5.3-Flash EXL3 4bpw on two RTX PRO 6000 Blackwell GPUs

This repository ports the EXL3 adapter used by [Brandon Music's GLM-5.3-Flash
TR3 4bpw runtime](https://github.com/brandonmmusic-max/glm-5.3-flash-exl3-4bpw)
to [Local Inference Lab's](https://github.com/local-inference-lab) newer Jovian
Judgement TP2 image. It keeps the LIL GLM-5.3 scheduler, B12X attention/MoE
backends, MTP3 speculation, DCP2, tool calling, and vision support.

On two RTX PRO 6000 Blackwell GPUs, this configuration reaches about **5,900
prefill tok/s**, up to **160 tok/s** single-stream decode and **387 tok/s**
aggregate at concurrency 4. The FP8 KV pool is about **1.6M tokens** with
`GPU_MEMORY_UTILIZATION=0.98`.

The checkpoint and associated quantization work are provided by [Local
Inference Lab, Inc.](https://local-inference-lab.ai/) through [Brandon's
upstream checkpoint](https://huggingface.co/brandonmusic/GLM-5.3-Flash-tr3-4bpw).

The image and checkpoint are not included. This image replaces LIL's stock
launcher and passes the local `/model` mount directly to vLLM, so the parent's
NVFP4 model is never selected.

## Requirements

- Linux with Docker, Docker Compose, and the NVIDIA Container Toolkit
- Two NVIDIA RTX PRO 6000 Blackwell GPUs
- [brandonmusic/GLM-5.3-Flash-tr3-4bpw](https://huggingface.co/brandonmusic/GLM-5.3-Flash-tr3-4bpw)

## Build and run

```bash
git clone https://github.com/Raul2718/glm53-flash-exl3-lil
cd glm53-flash-exl3-lil
cp .env.example .env
```

Set `GLM53_MODEL_PATH` in `.env` to the absolute checkpoint path, then:

```bash
./build.sh
docker compose up -d
```

The first build automatically pulls the pinned LIL Docker image if it is not
already available. Brandon's runtime image is not required. The model
checkpoint must be downloaded separately and must exist at
`GLM53_MODEL_PATH`.

The OpenAI-compatible API is available at `http://127.0.0.1:8118`:

```bash
curl http://127.0.0.1:8118/v1/models
docker compose logs -f
```

Stop it with:

```bash
docker compose down
```

Common settings can be added to `.env` or overridden on the command line:

| Variable | Default |
| --- | --- |
| `GLM53_CACHE_PATH` | `./cache` |
| `PORT` | `8118` |
| `GLM53_GPU_0`, `GLM53_GPU_1` | `0`, `1` |
| `MAX_MODEL_LEN` | `409600` |
| `MAX_NUM_BATCHED_TOKENS` | `3072` |
| `MAX_NUM_SEQS` | `4` |
| `GPU_MEMORY_UTILIZATION` | `0.95` |
| `SERVED_MODEL_NAME` | `GLM-5.3-Flash-EXL3-4bpw` |

The cache path persists runtime and compilation caches outside the container.
The supplied `.env.example` sets memory utilization to 0.95, which allocates
about 1M KV-cache tokens. The roughly 1.6M-token figure above uses 0.98 instead; change
`GPU_MEMORY_UTILIZATION` in `.env` to select between them.

## What is patched

The Dockerfile applies a small source overlay to the digest-pinned LIL image:

- Brandon's EXL3 adapter and cache module, with one compatibility helper for
  the newer vLLM tree;
- EXL3 registration and per-expert Trellis weight recognition in vLLM;
- a B12X 1.3 compatibility path for adopting the checkpoint's native Trellis
  weights without copying them; and
- the working multimodal chat template used by this runtime.

The serving profile is TP2/EP2/DCP2 with FP8 MLA KV cache, MTP3 speculation,
prefix caching, vision, and tool calling. LMCache transfer is not configured.

## Performance

Measured on two RTX PRO 6000 Blackwell Workstation Edition GPUs at stock
clocks, with a 500 W power limit and x8/x8 PCIe 5.0 links, using
[llm-inference-bench](https://github.com/local-inference-lab/llm-inference-bench).

### Prefill

| Context | Tokens | TTFT | Throughput |
| ---: | ---: | ---: | ---: |
| 8K | 8,198 | 1.43 s | 5,731 tok/s |
| 16K | 16,228 | 2.79 s | 5,818 tok/s |
| 32K | 32,319 | 5.47 s | 5,912 tok/s |
| 64K | 64,509 | 10.87 s | 5,936 tok/s |
| 128K | 128,878 | 21.80 s | 5,913 tok/s |

### Aggregate decode

| Context | C1 | C2 | C4 |
| ---: | ---: | ---: | ---: |
| 0 | 151.2 | 238.1 | 362.7 |
| 16K | 155.3 | 242.3 | 382.7 |
| 32K | 155.0 | 246.8 | 386.5 |
| 64K | 155.5 | 247.2 | 369.6 |
| 128K | 159.9 | 253.2 | 383.4 |

All decode values are aggregate tok/s.

## Attribution and license

[Brandon Music](https://github.com/brandonmmusic-max) created the checkpoint,
quantization work, and original EXL3 runtime adapter. [Local Inference
Lab](https://github.com/local-inference-lab) provides the vLLM/B12X runtime
foundation, and [turboderp](https://github.com/turboderp-org/exllamav3)
created EXL3 and ExLlamaV3.

The repository's original compatibility changes are provided under the
[Apache License 2.0](LICENSE). Third-party files retain their existing terms.
The checkpoint is distributed separately under the [Local Inference Lab
Attribution License 1.0](THIRD_PARTY_LICENSES/LIL-ATTRIBUTION-1.0.txt).
Exact image digests, source commits, and file lineage are recorded in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
