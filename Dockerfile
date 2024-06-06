# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Install necessary tools including curl
RUN apt-get update && apt-get install -y wget gnupg lsb-release curl

# Add PostgreSQL's PGDG repository
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list

# Update and install dependencies including PostgreSQL 15
RUN apt-get update && apt-get install -y \
    postgresql-15 \
    postgresql-contrib-15 \
    python3.11 \
    python3-pip \
    git \
    nano \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

# Manually install Liquibase
RUN wget https://github.com/liquibase/liquibase/releases/download/v4.13.0/liquibase-4.13.0.tar.gz \
    && tar -xzf liquibase-4.13.0.tar.gz -C /usr/local/bin \
    && rm liquibase-4.13.0.tar.gz

# Set up the database and user
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" && \
    createdb -O docker docker

# Adjust PostgreSQL configuration to allow local connections
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/15/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/15/main/postgresql.conf

# Switch back to the root user
USER root

# Install the latest Node.js (includes npm and npx)
RUN curl -sL https://deb.nodesource.com/setup_current.x | bash - && apt-get update && apt-get install -y nodejs

# Install Yarn
RUN npm install --global yarn

# Install Bazel
RUN apt-get update && apt-get install -y apt-transport-https curl gnupg
RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg
RUN mv bazel-archive-keyring.gpg /usr/share/keyrings
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN apt-get update && apt-get install -y bazel
RUN apt-get update && apt-get full-upgrade -y

# Expose the PostgreSQL port
EXPOSE 5432

# Add a volume to the container
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Create the workspace folder to clone the repository
RUN mkdir -p /workspace

# Set the default command to run when starting the container
CMD ["pg_ctl", "-D", "/var/lib/postgresql/15/main", "-l", "logfile", "start"]
