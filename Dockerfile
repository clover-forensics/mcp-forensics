# Forensic agent image — all Python deps are installed at *build* time (no pip on your laptop required).
# Build:  docker build -t mcp-forensics .
# Run:    docker run --rm -e API_KEY=... -v /path/to/cases:/app/cases mcp-forensics \
#            python pipeline.py --case /app/cases/my_case --query "Your instruction here"

FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    sleuthkit \
    man-db \
    coreutils \
    findutils \
    grep \
    binutils \
    util-linux \
    bsdextrautils \
    less \
    e2fsprogs \
    xxd \
    --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir uv && uv pip install --system --no-cache -r requirements.txt

COPY . .

# Application and subprocess MCP server both resolve imports from /app
ENV PYTHONPATH=/app

# Default: show that the image is ready (override when running investigations)
CMD ["python", "pipeline.py", "--help"]
