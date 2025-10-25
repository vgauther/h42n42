# ---- Base : Debian 11 ----
FROM debian:11-slim

# ---- Install system deps ----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config git curl ca-certificates rsync unzip \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# ---- Install opam ----
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
  && chmod +x /usr/local/bin/opam

# ---- Create non-root user ----
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}

USER ${USER}
WORKDIR /home/${USER}

ENV OPAMYES=1
ENV OPAMNOAUTORUN=1

# ---- Initialize opam ----
RUN opam init --disable-sandboxing -a

# ---- Create OCaml 5.2.1 switch ----
RUN opam switch create 5.2.1 ocaml-base-compiler.5.2.1

# ---- Prepare app directory ----
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# ---- Install opam dependencies if available ----
SHELL ["/bin/bash", "-lc"]
RUN eval "$(opam env)" \
  && if compgen -G "*.opam" > /dev/null; then \
       opam install . --deps-only; \
     elif [ -f "dune-project" ]; then \
       opam pin add -n . || true; \
       opam install . --deps-only || true; \
     else \
       echo "No opam or dune-project file found; skipping dep install."; \
     fi

# ---- Default command ----
ENV APP_CMD="opam exec -- ocaml -vnum"

# ---- Inline entrypoint (no .sh file needed) ----
ENTRYPOINT ["/bin/bash", "-lc", "eval \"$(opam env --switch=5.2.1)\" && exec $APP_CMD"]
