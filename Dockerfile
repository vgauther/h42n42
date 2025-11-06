# Use official OCaml/OPAM image
FROM ocaml/opam:ubuntu-22.04-ocaml-4.14

# Set environment variables
ENV OPAMROOT=/home/opam/.opam

# Install system dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    pkg-config \
    libgmp-dev \
    libgdbm-dev \
    libdb-dev \
    libsqlite3-dev \
    libev-dev \
    libpam0g-dev \
    libssl-dev \
    zlib1g-dev \
    && sudo rm -rf /var/lib/apt/lists/*

# Install Eliom and required packages
RUN eval $(opam env) && opam install -y \
    eliom \
    js_of_ocaml \
    js_of_ocaml-ppx \
    js_of_ocaml-ppx_deriving_json \
    lwt_ppx \
    bigstringaf \
    dbm \
    sqlite3 \
    ocsipersist-dbm

# Set working directory
WORKDIR /home/opam/app

# Copy project files
COPY --chown=opam:opam . .

# Build the application
RUN eval $(opam env) && make clean && make all

# Expose the port (using test port for development)
EXPOSE 8080

# Set the default command to run the application
CMD ["make", "test.byte"]
