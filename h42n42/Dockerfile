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

# --- opam: switch + pins git (plus récents) ---
USER opam

# 1) switch 5.2.1
RUN opam update && opam switch create 5.2.1 && eval $(opam env)

# 2) dep helper
RUN opam install -y opam-depext dune

# 3) PINS git (versions récentes compatibles 5.2.x)
#    NB: on utilise -n pour ne pas build tout de suite, puis depext + install
RUN opam pin -n add eliom https://github.com/ocsigen/eliom.git && \
    opam pin -n add ocsigenserver https://github.com/ocsigen/ocsigenserver.git && \
    opam pin -n add ocsipersist https://github.com/ocsigen/ocsipersist.git

# 4) depext + install (inclut ocsipersist-dbm)
RUN eval $(opam env) && \
    opam depext -iy eliom ocsigenserver ocsipersist ocsipersist-dbm && \
    opam install -y eliom ocsigenserver ocsipersist-dbm

# --- build / install projet ---
RUN eval $(opam env) && make clean && make all

USER root
RUN eval $(opam env) && make install || true

# --- chemins run/log accessibles et patch conf ---
RUN mkdir -p /app/local/var/log/h42n42 /app/local/var/run && \
    chown -R opam:opam /app/local/var

# Patch auto des .conf présents (usr/local ou local)
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
USER opam
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
