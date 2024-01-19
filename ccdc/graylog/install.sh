print_step() {
        echo "======================================================================="
        echo $1
        echo "======================================================================="
}
read -p "Enter a graylog password: " GRAYLOG_PASSWORD
HASH=$(echo -n $GRAYLOG_PASSWORD | shasum -a 256 | cut -b -64)

read -p "Are you in Texas?[y/N]: " INTEXAS
if [ "$INTEXAS" = y ]; then
	TIMEZONE="CST6CDT"
else
	TIMEZONE="PST8PDT"
fi

print_step "Step 0: Retrieving elasticsearch and graylog"

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.1-amd64.deb
wget https://packages.graylog2.org/repo/debian/pool/stable/4.3/g/graylog-server/graylog-server_4.3.9-1_all.deb

print_step "Step 1 Installing debs"

dpkg -i *.deb

print_step "Step 2 Installing Java and pwgen"

apt update
apt install -y openjdk-8-jdk pwgen

print_step "Step 3 Configuring Elasticsearch"
echo "Setting cluster-name to graylog"
sed -i "s/#cluster.name: my-application/cluster.name: graylog/" /etc/elasticsearch/elasticsearch.yml
echo "Setting network.host to 127.0.0.1"
sed -i "s/#network.host: 192.168.0.1/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
echo "Setting listerning port to 9200"
sed -i "s/#http.port: 9200/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml

print_step "Step 4 Configuring Graylog"
PASSWORD_SECRET=$(pwgen -N 1 -s 96)
echo "Installing password secret: $PASSWORD_SECRET"
sed -i "s/password_secret =/password_secret = $PASSWORD_SECRET/" /etc/graylog/server/server.conf
echo "Installing password: $GRAYLOG_PASSWORD"
sed -i "s/root_password_sha2 =/root_password_sha2 = $HASH/" /etc/graylog/server/server.conf
echo "Changing the listerning port to 9000"
sed -i "s/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/" /etc/graylog/server/server.conf
echo "Setting the timezone to $TIMEZONE"
sed -i "s/#root_timezone = UTC/root_timezone = $TIMEZONE/" /etc/graylog/server/server.conf

print_step "Step 5 Reloading daemons"
systemctl daemon-reload

print_step "Step 5.1 Enabling mongod"
systemctl enable mongod

print_step "Step 5.2 Enabling elasticsearch"
systemctl enable elasticsearch

print_step "Step 5.3 Enabling Graylog"
systemctl enable graylog-server

print_step "Step 5.4 Starting mongod"
systemctl start mongod

print_step "Step 5.5 Starting elasticsearch"
systemctl start elasticsearch

print_step "Step 5.6 Starting Graylog"
systemctl start graylog-server

echo "Graylog should be up on port 9000, the password is $GRAYLOG_PASSWORD"
echo "Don't forget to configure your inputs"
