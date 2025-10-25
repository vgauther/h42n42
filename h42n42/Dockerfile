FROM debian:11-slim

# Paquets système nécessaires
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip make \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
    libpcre3-dev libsqlite3-dev \
    xz-utils bzip2 patch perl gnupg tar \
 && rm -rf /var/lib/apt/lists/*

# opam binaire
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
 && chmod +x /usr/local/bin/opam

# Utilisateur non-root pour opam
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}
USER ${USER}
WORKDIR /home/${USER}

# Env non interactif + limiter le parallélisme pour stabilité
ENV OPAMYES=1 OPAMNOAUTORUN=1 OPAMJOBS=1 MAKEFLAGS=-j1

SHELL ["/bin/bash","-lc"]

# Init opam + switch OCaml 5.2.1
RUN opam init --disable-sandboxing -a --bare \
 && opam repository set-url default https://opam.ocaml.org \
 && opam update \
 && opam switch create 5.2.1 ocaml-base-compiler.5.2.1 -j 1 --verbose

# Outils OCaml
RUN eval "$(opam env --switch=5.2.1)" \
 && opam install -y dune

# ocsigenserver + eliom (sans depext)
RUN eval "$(opam env --switch=5.2.1)" \
 && opam install -y ocsigenserver eliom

# Projet
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# Dépendances du projet si présentes (sans depext)
RUN eval "$(opam env --switch=5.2.1)" \
 && if compgen -G "*.opam" > /dev/null; then \
      opam install -y . --deps-only || true; \
    elif [ -f "dune-project" ]; then \
      opam pin add -n . || true; \
      opam install -y . --deps-only || true; \
    else \
      echo "Aucun .opam / dune-project — on passe."; \
    fi

EXPOSE 8080

# Lance automatiquement le test
ENTRYPOINT ["/bin/bash","-lc","eval \"$(opam env --switch=5.2.1)\" && make test.byte"]
