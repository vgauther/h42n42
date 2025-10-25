# Debian 11
FROM debian:11-slim

# Outils système + depexts nécessaires pour compiler OCaml/ocsigen/eliom
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip make \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
    libpcre3-dev libsqlite3-dev \
    xz-utils bzip2 patch perl \
 && rm -rf /var/lib/apt/lists/*

# opam binaire
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
 && chmod +x /usr/local/bin/opam

# Utilisateur non-root
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# opam en non-interactif + sans sandbox dans Docker
ENV OPAMYES=1 OPAMNOAUTORUN=1

# Utiliser bash pour les RUN suivants
SHELL ["/bin/bash","-lc"]

# Init opam + update + switch OCaml 5.2.1
RUN opam init --disable-sandboxing -a \
 && opam update \
 && opam switch create 5.2.1 ocaml-base-compiler.5.2.1

# Outils OCaml
RUN eval "$(opam env)" && opam install dune opam-depext

# ocsigenserver + eliom (avec depexts)
RUN eval "$(opam env)" && opam depext -uiv ocsigenserver eliom && opam install ocsigenserver eliom

# Projet
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# Dépendances du projet si présentes
RUN eval "$(opam env)" \
 && if compgen -G "*.opam" > /dev/null; then \
      opam depext -uiv . || true; \
      opam install . --deps-only || true; \
    elif [ -f "dune-project" ]; then \
      opam pin add -n . || true; \
      opam depext -uiv . || true; \
      opam install . --deps-only || true; \
    else \
      echo "Aucun .opam / dune-project — on passe."; \
    fi

# (Optionnel) si ton test ouvre un port
EXPOSE 8080

# Lancer automatiquement `make test.byte`
ENTRYPOINT ["/bin/bash","-lc","eval \"$(opam env --switch=5.2.1)\" && make test.byte"]
