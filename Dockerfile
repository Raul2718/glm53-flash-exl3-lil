ARG BASE_IMAGE=localinferencelab/vllm@sha256:723159dff669c259d32fbe59e2887016baa4c5d3a67a61dba49c8c456286af5f
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="GLM-5.3-Flash EXL3 on LIL vLLM" \
      org.opencontainers.image.description="EXL3 compatibility overlay for the LIL Jovian Judgement GLM-5.3 TP2 runtime" \
      local.glm53-exl3.base="localinferencelab/vllm@sha256:723159dff669c259d32fbe59e2887016baa4c5d3a67a61dba49c8c456286af5f" \
      local.glm53-exl3.adapter-source="verdictai/glm53-flash-exl3-k4@sha256:0f1cdcc8891f1cc3a444121eb61d366289a1cbba285f0892dcbb24bc94961692" \
      local.glm53-exl3.status="experimental"

# Overlay the complete files selected through the base image's PYTHONPATH. No
# installed wheel, CUDA extension, model weight, or checkpoint is replaced.
COPY overlay/vllm/ /opt/glm53-flash/vllm/vllm/
COPY overlay/b12x/ /opt/glm53-flash/b12x/b12x/

# The parent image's launcher selects its remote NVFP4 model by default. Replace
# that launcher and make the local mount the only model passed to vLLM.
ENV MODEL=/model

RUN /opt/venv/bin/python -m py_compile \
      /opt/glm53-flash/vllm/vllm/model_executor/layers/quantization/exl3.py \
      /opt/glm53-flash/vllm/vllm/model_executor/layers/quantization/exl3_online_cache.py \
      /opt/glm53-flash/vllm/vllm/model_executor/layers/quantization/__init__.py \
      /opt/glm53-flash/vllm/vllm/model_executor/layers/fused_moe/routed_experts.py \
      /opt/glm53-flash/vllm/vllm/config/model.py \
      /opt/glm53-flash/b12x/b12x/moe/fused_moe/_btx_adoption.py \
      /opt/glm53-flash/b12x/b12x/moe/fused_moe/api.py \
      /opt/glm53-flash/b12x/b12x/moe/fused_moe/__init__.py

ENTRYPOINT ["/opt/venv/bin/vllm"]
CMD ["serve", "/model"]
