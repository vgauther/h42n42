# Dockerfile
FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive \
    OPAMYES=1

# 1) Dépendances système (ajout: libpcre3-dev)
RUN apt-get update && apt-get install -y \
    curl git m4 build-essential pkg-config \
    libgmp-dev libssl-dev libsqlite3-dev zlib1g-dev bubblewrap \
    libgdbm-dev libpcre3-dev ca-certificates wget unzip rsync \
 && rm -rf /var/lib/apt/lists/*

# 2) OPAM 2.2.1 (binaire direct, pas d'interaction)
RUN wget -q https://github.com/ocaml/opam/releases/download/2.2.1/opam-2.2.1-x86_64-linux \
      -O /usr/local/bin/opam \
 && chmod +x /usr/local/bin/opam

# 3) Init OPAM + switch OCaml 4.14.2
RUN opam init --disable-sandboxing -y \
 && opam switch create 4.14.2 -y \
 && opam switch set 4.14.2 \
 && opam update

# 4) Paquets OPAM (versions demandées)
# eliom=10.2.0 + ocsigenserver=5.1.0 => ocsipersist < 2.0
RUN opam install -y dune.3.20.0 \
    'eliom=10.2.0' 'ocsigenserver=5.1.0' \
    'ocsipersist<2.0' 'ocsipersist-dbm<2.0' dbm \
    js_of_ocaml js_of_ocaml-ppx lwt bigstringaf

# 5) Copie du projet
WORKDIR /app/h42n42
COPY ./h42n42/ ./

# 6) Exposer le port et lancer
EXPOSE 8080
CMD ["/bin/sh","-lc","find . -name '*.conf.in' -exec sed -i 's/127\\.0\\.0\\.1/0.0.0.0/g' {} + && opam exec -- make test.byte"]
