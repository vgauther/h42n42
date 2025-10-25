# syntax=docker/dockerfile:1
FROM debian:11-slim

# ====== Système : outils de build & libs requises ======
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip make \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev libpcre3-dev libsqlite3-dev \
    xz-utils bzip2 patch perl gnupg tar findutils procps \
 && rm -rf /var/lib/apt/lists/*

# ====== OPAM (binaire) ======
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
 && chmod +x /usr/local/bin/opam

# ====== Utilisateur non-root pour OPAM ======
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# ====== Environnement OPAM (stable & économe en espace) ======
# - TMPDIR/OPAMTMPDIR hors /tmp (certains environnements ont peu d’espace sur /tmp)
# - OPAMJOBS=1 & MAKEFLAGS=-j1 pour limiter la RAM/disque durant la compile
ENV OPAMYES=1 OPAMNOAUTORUN=1 OPAMJOBS=1 MAKEFLAGS=-j1 \
    TMPDIR=/home/opam/tmp OPAMTMPDIR=/home/opam/tmp
SHELL ["/bin/bash","-lc"]
RUN mkdir -p "$TMPDIR"

# ====== Init OPAM & switch OCaml 5.2.1 ======
RUN opam init --disable-sandboxing -a --bare \
 && opam repository set-url default https://opam.ocaml.org \
 && opam update \
 && opam switch create 5.2.1 ocaml-base-compiler.5.2.1 -j 1

# ====== Outils OCaml dans le switch ======
RUN eval "$(opam env --switch=5.2.1)" \
 && opam install -y dune

# ====== ocsigenserver + eliom via OPAM (même switch) ======
RUN eval "$(opam env --switch=5.2.1)" \
 && opam install -y ocsigenserver eliom \
 && opam clean -a -c

# ====== Projet ======
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# Dépendances du projet si présentes (sans depext ; tout passe par OPAM)
RUN eval "$(opam env --switch=5.2.1)" \
 && if compgen -G "*.opam" > /dev/null; then \
      opam install -y . --deps-only || true; \
    elif [ -f "dune-project" ]; then \
      opam pin add -n . || true; \
      opam install -y . --deps-only || true; \
    else \
      echo "Aucun .opam / dune-project — on passe."; \
    fi \
 && opam clean -a -c

# (Optionnel) si ton test ouvre un port
EXPOSE 8080

# ====== Lancer automatiquement `make test.byte` avec l'env du switch ======
ENTRYPOINT ["/bin/bash","-lc","eval \"$(opam env --switch=5.2.1)\" && make test.byte"]
