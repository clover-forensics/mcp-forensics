# Forensic agent image — all Python deps are installed at *build* time (no pip on your laptop required).
# Build:  docker build -t mcp-forensics .
# Run:    docker run --rm -e API_KEY=... -v /path/to/cases:/app/cases mcp-forensics \
#            python pipeline.py --case /app/cases/my_case --query "Your instruction here"

FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONPATH=/app

# --- core/tools/linux.py: ls, find, cat, head, strings, grep, hexdump, xxd, sha256sum
# --- core/tools/sleuthkit.py: mmls, fls, … (full TSK + EWF/VHD/VMDK stack)
# --- core/tools/bulkextractor.py / volatility.py: built or pip-installed below
RUN apt-get update \
 && apt-get install -y \
    ca-certificates \
    curl \
    man-db \
    sqlite3 \
    sleuthkit \
    ewf-tools \
    libewf2 \
    coreutils \
    findutils \
    grep \
    binutils \
    util-linux \
    bsdextrautils \
    less \
    xxd \
    e2fsprogs \
 && rm -rf /var/lib/apt/lists/* \
 && mmls -i list 2>&1 | grep -qi ewf

# bulk_extractor: build from release (requires git submodules).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    cmake \
    zlib1g-dev \
    libssl-dev \
    libbz2-dev \
    libexpat1-dev \
    libsqlite3-dev \
    libre2-dev \
    flex \
    bison \
 && git clone --recurse-submodules --branch v2.1.1 --depth 1 \
      https://github.com/simsong/bulk_extractor.git /tmp/bulk_extractor \
 && cd /tmp/bulk_extractor \
 && ./bootstrap.sh \
 && ./configure \
 && make -j"$(nproc)" \
 && make install \
 && cd / \
 && rm -rf /tmp/bulk_extractor \
 && command -v bulk_extractor

WORKDIR /app

COPY requirements.txt .

RUN pip3 install --no-cache-dir uv \
 && uv pip install --system --no-cache -r requirements.txt \
 && uv pip install --system --no-cache volatility3 \
 && vol --help >/dev/null

COPY . .

CMD ["python", "pipeline.py", "--help"]
