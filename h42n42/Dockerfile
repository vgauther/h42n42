# ---- Base : Debian 11 ----
FROM debian:11-slim

# ---- Installer les dépendances système ----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# ---- Installer opam ----
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
  && chmod +x /usr/local/bin/opam

# ---- Créer un utilisateur non-root ----
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}

USER ${USER}
WORKDIR /home/${USER}

# Variables d’environnement pour opam
ENV OPAMYES=1
ENV OPAMNOAUTORUN=1

# ---- Initialiser opam ----
RUN opam init --disable-sandboxing -a

# ---- Créer le switch OCaml 5.2.1 ----
RUN opam switch create 5.2.1 ocaml-base-compiler.5.2.1

# ---- Installer dune ----
SHELL ["/bin/bash", "-lc"]
RUN eval "$(opam env)" && opam install dune

# ---- Copier ton application ----
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# ---- Installer les dépendances du projet si présentes ----
RUN eval "$(opam env)" \
  && if compgen -G "*.opam" > /dev/null; then \
       opam install . --deps-only; \
     elif [ -f "dune-project" ]; then \
       opam pin add -n . || true; \
       opam install . --deps-only || true; \
     else \
       echo "Aucun fichier .opam ni dune-project trouvé — dépendances ignorées."; \
     fi

# ---- Variable par défaut pour la commande du serveur ----
ENV APP_CMD="opam exec -- ocaml -vnum"

# ---- Exposer le port du serveur ----
EXPOSE 8080

# ---- Entrypoint inline (aucun fichier .sh nécessaire) ----
ENTRYPOINT ["/bin/bash", "-lc", "eval \"$(opam env --switch=5.2.1)\" && exec $APP_CMD"]
