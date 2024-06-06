#!/bin/bash
# entrypoint.sh

# Start PostgreSQL
/etc/init.d/postgresql start

# Do any other necessary setup here

# Keep the container running
tail -f /dev/null
