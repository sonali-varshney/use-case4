wget https://raw.githubusercontent.com/apache/devlake/main/docker-compose.yml   # it will not work instead ni
git clone https://github.com/apache/incubator-devlake.git
vi docker-compose-dev.yml  #comment 5432 (the port which is overlapping(postgres ko rehne dena h dusre wale ko dlt kr do)
sudo docker-compose -f docker-compose-dev.yml up -d
sudo docker ps -a
sudo docker-compose -f docker-compose-dev.yml down
openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1