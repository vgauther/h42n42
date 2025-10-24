# Étape 1 : base Debian avec OCaml et opam
FROM ocaml/opam:debian-12

# Étape 2 : travailler dans /app
WORKDIR /app

# Étape 3 : copier ton projet
COPY . /app

# Étape 4 : installer Eliom et Ocsigen via opam
# (on installe aussi dune et make si nécessaire)
RUN sudo apt-get update && sudo apt-get install -y m4 pkg-config libssl-dev make && \
    opam update && \
    opam install -y eliom ocsigenserver && \
    eval $(opam env)

# Étape 5 : compiler ton projet
RUN bash -lc "make clean && make all && make install"

# Étape 6 : exposer le port HTTP
EXPOSE 80

# Étape 7 : lancer le serveur
CMD ["bash", "-lc", "make run.byte"]
