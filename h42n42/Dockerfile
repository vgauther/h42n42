# Build & run the Eliom/Ocsigen project entirely inside Docker
# Host needs only Docker. No OCaml/opam deps on your machine.

# 1) Use the upstream image that already contains OCaml, opam, eliom & ocsigenserver
FROM ocsigen/eliom:latest

# 2) Workdir inside the container
WORKDIR /app

# 3) Copy project sources
# Put this Dockerfile at the root next to your Makefile before building.
COPY . /app

# 4) Build the project
# - We run as the 'opam' user inside the image.
# - We eval opam's environment before calling make.
# - 'make all' compiles client+server; 'make install' installs into /usr/local/*
USER opam
RUN bash -lc 'eval $(opam env) && make clean && make all && make install'

# 5) Expose the HTTP port configured in etc/h42n42/h42n42.conf (currently 80)
EXPOSE 80

# 6) Default command: launch ocsigenserver using the generated conf
# You can override with: docker run ... <another command>
CMD ["bash","-lc","eval $(opam env) && make run.byte"]
