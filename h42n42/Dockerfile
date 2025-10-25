FROM ocaml/opam:debian-12
SHELL ["/bin/bash","-lc"]
ENV OPAMYES=1 OPAMJOBS=2

# --- root: deps système ---
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y \
    m4 pkg-config make libssl-dev libgmp-dev libpcre3-dev zlib1g-dev \
    libsqlite3-dev libgdbm-dev curl ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# sources
COPY . /app
RUN chown -R opam:opam /app

# --- opam: choisir la 1ère version compatible ---
USER opam
RUN opam update

# Ajoute le dépôt Ocsigen (plus frais que l’index officiel)
RUN opam repo add ocsigen https://github.com/ocsigen/opam-repository.git || true && opam update

# Essaie en cascade: 5.2.1 -> 5.2.0 -> 5.1.1 -> 4.14.1
RUN set -e; \
  for ver in 5.2.1 5.2.0 5.1.1 4.14.1; do \
    echo "=== Trying OCaml $ver ==="; \
    opam switch remove -y "$ver" || true; \
    if opam switch create "$ver"; then \
      eval $(opam env); \
      opam install -y opam-depext dune; \
      # Pin git (versions récentes) pour débloquer le solveur si besoin
      opam pin -n add eliom https://github.com/ocsigen/eliom.git || true; \
      opam pin -n add ocsigenserver https://github.com/ocsigen/ocsigenserver.git || true; \
      opam pin -n add ocsipersist https://github.com/ocsigen/ocsipersist.git || true; \
      # Depext + install
      if opam depext -iy eliom ocsigenserver ocsipersist ocsipersist-dbm && \
         opam install -y eliom ocsigenserver ocsipersist-dbm; then \
        echo ">>> Using OCaml $ver"; \
        echo "$ver" > /tmp/ocaml.ok; \
        break; \
      fi; \
    fi; \
    echo "=== OCaml $ver failed, trying next ==="; \
  done; \
  test -f /tmp/ocaml.ok

# Build projet
RUN eval $(opam env) && make clean && make all

# Install (si ton Makefile l’utilise)
USER root
RUN eval $(opam env) && make install || true

# Répertoires logs/run accessibles par 'opam'
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run && \
    chown -R opam:opam /app/local/var

# Patch auto des .conf (usr/local ou local) : logs/run/pipe + suppression <user>/<group>
RUN set -eux; \
  confs="$( { test -d /usr/local/etc/h42n42 && find /usr/local/etc/h42n42 -maxdepth 1 -name '*.conf' || true; }; \
            { test -d /app/local/etc/h42n42 && find /app/local/etc/h42n42 -maxdepth 1 -name '*.conf' || true; } )"; \
  for f in $confs; do \
    sed -i 's#/usr/local/var/log/h42n42#/app/local/var/log/h42n42#g' "$f"; \
    sed -i 's#/usr/local/var/run/h42n42#/app/local/var/run/h42n42#g' "$f"; \
    sed -i 's#/usr/local/var/run/h42n42-cmd#/app/local/var/run/h42n42-cmd#g' "$f"; \
    sed -i '/<user>.*<\/user>/d; /<group>.*<\/group>/d' "$f"; \
  done || true; \
  chown -R opam:opam /usr/local/etc/h42n42 || true

EXPOSE 80

# Run en non-root
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
