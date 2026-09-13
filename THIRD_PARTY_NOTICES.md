# Third-party notices and provenance

This repository is a compatibility port. It does not redistribute the model
checkpoint.

The checkpoint and associated quantization work identify **Local Inference
Lab, Inc.** as the author under the current license:

- Project home: https://local-inference-lab.ai/
- Upstream source: https://huggingface.co/brandonmusic/GLM-5.3-Flash-tr3-4bpw

## Runtime foundation

The Dockerfile is pinned to:

```text
localinferencelab/vllm@sha256:723159dff669c259d32fbe59e2887016baa4c5d3a67a61dba49c8c456286af5f
```

That image is the Local Inference Lab release
`jovian-judgement-community-tp2-experimental-20260912-r1`. Its embedded source
lock identifies:

- vLLM: `https://github.com/voipmonitor/vllm.git` at
  `7f4aecc66e857d093e012a2c57d03711bd23be4a`
- B12X: `https://github.com/local-inference-lab/b12x.git` at
  `73f66f028c1b59e92728e9fbbe4a472bb7796248`
- ExLlamaV3: `https://github.com/brandonmmusic-max/exllamav3.git` at
  `704aefd743b390af4bd0fb429d1906f9b964c7d8`

The vLLM and B12X source trees are licensed under Apache-2.0. ExLlamaV3 is
licensed under MIT; a copy is included in
[`THIRD_PARTY_LICENSES/EXLLAMAV3-MIT.txt`](THIRD_PARTY_LICENSES/EXLLAMAV3-MIT.txt).

## Brandon Music's EXL3 runtime

The EXL3 adapter was ported from Brandon Music's r19 runtime image:

```text
verdictai/glm53-flash-exl3-k4@sha256:0f1cdcc8891f1cc3a444121eb61d366289a1cbba285f0892dcbb24bc94961692
```

Its public source and model documentation are:

- https://github.com/brandonmmusic-max/glm-5.3-flash-exl3-4bpw
- https://huggingface.co/brandonmusic/GLM-5.3-Flash-tr3-4bpw

File lineage:

- `overlay/vllm/model_executor/layers/quantization/exl3_online_cache.py` is
  byte-identical to the file in the r19 image (SHA-256
  `de2d4622ebb265fc79ae380441d4a44569e870f67d3b6658f1ba9a7094d7415d`).
- `overlay/vllm/model_executor/layers/quantization/exl3.py` is Brandon's r19
  adapter with one compatibility change: the shared-expert path predicate
  removed from newer LIL vLLM is implemented locally.
- `chat_template.jinja` is adapted from the r19 multimodal template, with
  Jinja scoping/concatenation fixes required by the current runtime.

The adapter files retain their Apache-2.0 SPDX notices. The checkpoint's
current license is the Local Inference Lab Attribution License 1.0; a verbatim
copy is included in
[`THIRD_PARTY_LICENSES/LIL-ATTRIBUTION-1.0.txt`](THIRD_PARTY_LICENSES/LIL-ATTRIBUTION-1.0.txt).

## This port

The remaining overlay files are full-file modifications of the pinned LIL
vLLM/B12X source trees. They add EXL3 selection, correct rank-sliced expert
weight recognition, and a checked zero-copy bridge from the adapter's native
Trellis weights into the current B12X API. Modified files carry a notice near
their existing SPDX header or module docstring.
