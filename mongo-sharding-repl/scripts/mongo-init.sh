#!/bin/sh
set -e

echo "⏳ Ждём запуск контейнеров MongoDB..."
sleep 2

# ========================= CONFIG SERVER REPL =========================
echo "🚀 Инициализация CONFIG SERVER replica set..."

docker compose exec -T configsvr01 mongosh --quiet <<EOF
rs.initiate({
  _id: "configRepl",
  configsvr: true,
  members: [
    { _id: 0, host: "configsvr01:27017" },
    { _id: 1, host: "configsvr02:27017" },
    { _id: 2, host: "configsvr03:27017" }
  ]
});
EOF

sleep 1

# ========================= SHARD 1 REPLICA SET =========================
echo "🚀 Инициализация SHARD 1 replica set..."

docker compose exec -T shard1-01 mongosh --quiet <<EOF
rs.initiate({
  _id: "shard1Repl",
  members: [
    { _id: 0, host: "shard1-01:27017" },
    { _id: 1, host: "shard1-02:27017" },
    { _id: 2, host: "shard1-03:27017" }
  ]
});
EOF

sleep 1

# ========================= SHARD 2 REPLICA SET =========================
echo "🚀 Инициализация SHARD 2 replica set..."

docker compose exec -T shard2-01 mongosh --quiet <<EOF
rs.initiate({
  _id: "shard2Repl",
  members: [
    { _id: 0, host: "shard2-01:27017" },
    { _id: 1, host: "shard2-02:27017" },
    { _id: 2, host: "shard2-03:27017" }
  ]
});
EOF

sleep 10


# ========================= MONGOS ROUTER =========================
echo "⚙️ Добавляем шарды в mongos..."

docker compose exec -T mongos_router mongosh --port 27020 <<EOF
sh.addShard("shard1Repl/shard1-01:27017,shard1-02:27017,shard1-03:27017");
sh.addShard("shard2Repl/shard2-01:27017,shard2-02:27017,shard2-03:27017");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { name: "hashed" });

use somedb;
for (let i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}

db.helloDoc.countDocuments();
EOF

echo "✅ Инициализация завершена успешно!"
