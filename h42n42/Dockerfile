# ===== Base Debian 11 =====
FROM debian:11-slim

# ===== Paquets système (inclut outils d'archive/patch requis par OCaml) =====
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip make \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
    libpcre3-dev libsqlite3-dev \
    xz-utils bzip2 patch perl gnupg tar findutils \
 && rm -rf /var/lib/apt/lists/*

# ===== opam binaire =====
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
 && chmod +x /usr/local/bin/opam

# ===== Utilisateur non-root =====
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# ===== Environnement opam (non interactif) + logs/diag très verbeux =====
# - OPAMJOBS=1 / MAKEFLAGS=-j1 : réduit la conso mémoire (builds plus stables)
# - OPAMVERBOSE=1 : verbosité
# - OPAMKEEPBUILDDIR=1 : conserve les dossiers de build pour lire les logs
ENV OPAMYES=1 OPAMNOAUTORUN=1 OPAMJOBS=1 MAKEFLAGS=-j1 OPAMVERBOSE=1 OPAMKEEPBUILDDIR=1

SHELL ["/bin/bash","-lc"]

# ===== Init opam & switch OCaml 5.2.1 avec diagnostics en cas d'échec =====
RUN set -euxo pipefail \
 && opam init --disable-sandboxing -a --bare \
 && opam repository set-url default https://opam.ocaml.org \
 && opam update \
 && opam --version \
 && opam config report \
 && ( opam switch create 5.2.1 ocaml-base-compiler.5.2.1 -j 1 -v \
    || { echo "---- FAILURE creating switch 5.2.1 ----"; opam config report || true; \
         echo "Listing build logs (if any)"; BR="$(opam var build_root || echo ~/.opam/build)"; \
         find "$BR" -maxdepth 3 -type f -name '*.log' -print -exec sh -c 'echo \"===== {} =====\"; tail -n +1 {} | sed -n \"1,400p\"' \; || true; \
         exit 1; } )

# ===== Outils OCaml =====
RUN eval "$(opam env --switch=5.2.1)" \
 && opam install -y -v dune

# ===== ocsigenserver + eliom via OPAM avec logs détaillés =====
RUN eval "$(opam env --switch=5.2.1)" \
 && ( opam install -y -v ocsigenserver eliom \
    || { echo "---- FAILURE installing ocsigenserver/eliom ----"; \
         opam list --installed || true; \
         opam show ocsigenserver || true; \
         opam show eliom || true; \
         echo "opam config report:"; opam config report || true; \
         echo "Dump last build logs:"; BR="$(opam var build_root)"; \
         find "$BR" -maxdepth 3 -type f -name '*.log' -print -exec sh -c 'echo \"===== {} =====\"; tail -n +1 {} | sed -n \"1,400p\"' \; || true; \
         echo "Exporting switch state for post-mortem:"; opam switch export /home/${USER}/switch-5.2.1.export || true; \
         exit 1; } )

# ===== Projet =====
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# ===== Dépendances du projet (logs + robustesse) =====
RUN eval "$(opam env --switch=5.2.1)" \
 && set -euxo pipefail \
 && if compgen -G "*.opam" > /dev/null; then \
      ( opam install -y -v . --deps-only ) \
      || { echo "---- FAILURE installing project deps (.opam) ----"; \
           BR="$(opam var build_root)"; \
           find "$BR" -maxdepth 3 -type f -name '*.log' -print -exec sh -c 'echo \"===== {} =====\"; tail -n +1 {} | sed -n \"1,400p\"' \; || true; \
           exit 1; }; \
    elif [ -f "dune-project" ]; then \
      opam pin add -n . || true; \
      ( opam install -y -v . --deps-only ) \
      || { echo "---- FAILURE installing project deps (dune-project) ----"; \
           BR="$(opam var build_root)"; \
           find "$BR" -maxdepth 3 -type f -name '*.log' -print -exec sh -c 'echo \"===== {} =====\"; tail -n +1 {} | sed -n \"1,400p\"' \; || true; \
           exit 1; }; \
    else \
      echo "Aucun .opam / dune-project — on passe."; \
    fi

# (si ton test ouvre un port)
EXPOSE 8080

# ===== Entrée : lance make test.byte avec env opam du switch =====
ENTRYPOINT ["/bin/bash","-lc","eval \"$(opam env --switch=5.2.1)\" && make test.byte"]
