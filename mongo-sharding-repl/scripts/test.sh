#!/bin/bash

docker compose exec -T shard1-01 mongosh --port 27017 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF

docker compose exec -T shard2-01 mongosh --port 27017 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF

