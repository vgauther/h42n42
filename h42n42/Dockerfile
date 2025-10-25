# Debian 11 (bullseye)
FROM debian:11-slim

# ---- System deps (build toolchain + common OCaml deps) ----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential m4 pkg-config \
    git curl ca-certificates rsync unzip \
    libgmp-dev libssl-dev libffi-dev zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# ---- Install opam (single binary) ----
# Pin an opam version known to work broadly. Adjust if you need another.
ARG OPAM_VERSION=2.2.1
RUN curl -fsSL -o /usr/local/bin/opam "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-x86_64-linux" \
  && chmod +x /usr/local/bin/opam

# ---- Create non-root user for opam ----
ARG USER=opam
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USER}

USER ${USER}
WORKDIR /home/${USER}

# Make opam non-interactive inside Docker
ENV OPAMYES=1
# Disable sandboxing in containers
ENV OPAMNOAUTORUN=1

# ---- Initialize opam root ----
RUN opam init --disable-sandboxing -a

# ---- Create OCaml 5.2.1 switch ----
# (This creates ~/.opam/5.2.1 and sets it as current for subsequent RUN steps)
RUN opam switch create 5.2.1 ocaml-base-compiler.5.2.1

# Persist opam env for interactive shells; Docker RUN uses explicit eval anyway.
RUN echo 'eval $(opam env --switch=5.2.1 --set-switch)' >> ~/.bashrc

# ---- App setup ----
# Copy your app into /app. Replace this with a bind mount if you prefer.
WORKDIR /app
COPY --chown=${USER}:${USER} . /app

# If an opam file exists, install deps. If a dune-project only, try solving deps via opam pin.
SHELL ["/bin/bash", "-lc"]
RUN eval "$(opam env)" \
  && if compgen -G "*.opam" > /dev/null; then \
       opam install . --deps-only; \
     elif [ -f "dune-project" ]; then \
       opam pin add -n . || true; \
       opam install . --deps-only || true; \
     else \
       echo "No .opam or dune-project found; skipping opam deps."; \
     fi

# Default command can be overridden at 'docker run' time.
# Put your real server command here, e.g.:
#   ENV APP_CMD="dune exec -- ./bin/server.exe"
# or   ENV APP_CMD=\"./run.sh\"
ENV APP_CMD="opam exec -- ocaml -vnum"

# Lightweight entrypoint that ensures opam env is loaded then runs APP_CMD
COPY --chown=${USER}:${USER} docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["sh", "-lc", "$APP_CMD"]
