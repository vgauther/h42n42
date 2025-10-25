FROM debian:11-slim

# ====== Système ======
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip make \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev libpcre3-dev libsqlite3-dev \
    xz-utils bzip2 patch perl gnupg tar findutils procps \
 && rm -rf /var/lib/apt/lists/*

# ocsigen/eliom via APT (évite un build OPAM lourd)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ocsigenserver eliom \
 && rm -rf /var/lib/apt/lists/*

# ====== opam (binaire) ======
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
 && chmod +x /usr/local/bin/opam

# ====== Utilisateur non-root ======
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# Env OPAM + répertoire TMP hors /tmp + logs détaillés
ENV OPAMYES=1 OPAMNOAUTORUN=1 OPAMJOBS=1 MAKEFLAGS=-j1 \
    TMPDIR=/home/opam/tmp OPAMTMPDIR=/home/opam/tmp \
    OPAMVERBOSE=1 OPAMKEEPBUILDDIR=1
SHELL ["/bin/bash","-lc"]
RUN mkdir -p "$TMPDIR"

# ====== Init opam ======
RUN set -eux; \
  opam init --disable-sandboxing -a --bare || { \
    echo "---- opam init FAILED ----"; opam --version || true; opam config report || true; \
    echo "Disk/mem:"; df -h || true; free -h || true; \
    echo "OPAM logs:"; find ~/.opam -type f -name '*.log' -print -exec sh -c 'echo ===== {} =====; tail -n +1 {} | sed -n "1,400p"' \; || true; \
    exit 1; \
  }

RUN set -eux; \
  opam repository set-url default https://opam.ocaml.org; \
  opam update -vv || { \
    echo "---- opam update FAILED ----"; opam config report || true; df -h || true; free -h || true; exit 1; \
  }

# ====== Switch OCaml 5.2.1 ======
RUN set -eux; \
  opam switch create 5.2.1 ocaml-base-compiler.5.2.1 -j 1 -v || { \
    echo "---- switch create FAILED ----"; opam config report || true; \
    df -h || true; free -h || true; \
    echo "Build logs:"; find ~/.opam -type f -name '*.log' -print -exec sh -c 'echo ===== {} =====; tail -n +1 {} | sed -n "1,400p"' \; || true; \
    exit 1; \
  }

# ====== dune ======
RUN set -eux; \
  eval "$(opam env --switch=5.2.1)"; \
  opam install -y -v dune || { \
    echo "---- dune install FAILED ----"; opam config report || true; \
    df -h || true; free -h || true; \
    find ~/.opam -type f -name '*.log' -print -exec sh -c 'echo ===== {} =====; tail -n +1 {} | sed -n "1,400p"' \; || true; \
    exit 1; \
  }; \
  opam clean -a -c || true

# ====== Projet ======
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# Dépendances projet (si présentes) + logs si échec
RUN set -eux; \
  eval "$(opam env --switch=5.2.1)"; \
  if compgen -G "*.opam" > /dev/null; then \
    opam install -y -v . --deps-only || { \
      echo "---- deps (.opam) FAILED ----"; find ~/.opam -type f -name '*.log' -print -exec sh -c 'echo ===== {} =====; tail -n +1 {} | sed -n "1,400p"' \; || true; exit 1; }; \
  elif [ -f "dune-project" ]; then \
    opam pin add -n . || true; \
    opam install -y -v . --deps-only || { \
      echo "---- deps (dune-project) FAILED ----"; find ~/.opam -type f -name '*.log' -print -exec sh -c 'echo ===== {} =====; tail -n +1 {} | sed -n "1,400p"' \; || true; exit 1; }; \
  else \
    echo "Aucun .opam / dune-project — on passe."; \
  fi; \
  opam clean -a -c || true

EXPOSE 8080
ENTRYPOINT ["/bin/bash","-lc","eval \"$(opam env --switch=5.2.1)\" && make test.byte"]
