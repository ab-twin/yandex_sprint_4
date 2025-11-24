#!/bin/sh
set -e

echo "⏳ Ждём запуск контейнеров MongoDB..."
sleep 5

echo "🚀 Инициализация config server..."
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
if (rs.status().ok !== 1) {
  rs.initiate(
    {
      _id : "config_server",
         configsvr: true,
      members: [
        { _id : 0, host : "configSrv:27017" }
      ]
    }
  );
}
exit();
EOF

echo "🚀 Инициализация shard1..."
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
if (rs.status().ok !== 1) {
  rs.initiate(
      {
        _id : "shard1",
        members: [
          { _id : 0, host : "shard1:27018" },
         // { _id : 1, host : "shard2:27019" }
        ]
      }
  );
}
exit();
EOF

echo "🚀 Инициализация shard2..."

docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
if (rs.status().ok !== 1) {
  rs.initiate(
      {
        _id : "shard2",
        members: [
         // { _id : 0, host : "shard1:27018" },
          { _id : 0, host : "shard2:27019" }
        ]
      }
    );
  }
exit();
EOF

#
#echo "⚙️ Добавляем шарды в mongos..."
#docker compose exec -T mongos_router mongos --port 27020 --quiet <<EOF
#sh.addShard("shard1RS/shard1:27018")
#sh.addShard("shard2RS/shard2:27019")
#EOF
#
#echo "📦 Включаем шардирование БД..."
#docker compose exec -T mongos_router mongos --port 27020 --quiet <<EOF
#sh.enableSharding("somedb")
#EOF
#
#echo "📁 Создаём коллекцию..."
#docker compose exec -T mongos_router mongos --port 27020 --quiet <<EOF
#use somedb
#db.createCollection("helloDoc")
#EOF
#
#echo "🔑 Выбираем ключ шардирования..."
#docker compose exec -T mongos_router mongos --port 27020 --quiet <<EOF
#sh.shardCollection("somedb.helloDoc", { age: 1 })
#EOF

#echo "📝 Заполняем данными..."
#docker compose exec -T mongos_router mongos --port 27020 --quiet <<EOF
#use somedb
#for (var i = 0; i < 1000; i++) {
#  db.helloDoc.insertOne({ age: i, name: "ly" + i })
#}
#EOF


docker compose exec -T mongos_router mongosh --port 27020 <<EOF

sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments()
exit();
EOF
echo "✅ Инициализация завершена!"

