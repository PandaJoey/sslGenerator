#!/bin/bash
rootCAServerCAAndClientCA(){

	echo "Please enter a root common name, this can be whatever you like but I suggest root or rootCA."
	read -p "RootCN: " rootCN
	while [ -z "$rootCN" ] 
	do
		echo "Root CN missing please enter a root CN."
		read -p "RootCN: " rootCN
	done
    echo
	
	echo "Please enter a server common name, this can be whatever you like but I suggest the name of your database."
	read -p "ServerCN: " serverCN
	while [ -z "$serverCN" ] 
	do
		echo "Server CN missing please enter a server CN."
		read -p "ServerCN: " serverCN
	done
    echo

	echo "Please enter a server hostname, this will usually be the domain of the database, if local whatever you have set your hosts file to contain."
	read -p "Server hostname: " serverCNHostName
	while [ -z "$serverCNHostName" ] 
	do
		echo "Server hostname missing please enter a valid hostname."
		read -p "ServerHN: " serverCNHostName
	done
    echo

	echo "Please enter a client common name, this can be whatever you want, I suggest your name or client1."
	read -p "Client common name: " clientCN
	while [ -z "$clientCN" ] 
	do
		echo "Client CN missing please enter a client CN."
		read -p "clientCN: " clientCN
	done
    echo

	echo "Please enter a valid email. e.g. user@domain.com"
	read -p "Email: " email
	while [ -z "$email" ] 
	do
		echo "Email Argument Missing, please enter an email."
		read -p "Email: " email
	done
    echo
    
    printf "Please enter a strong password. \n"
	#Generate ca.pem and privkey.pem. The subject structure is /C=<Country Name>/ST=<State>/L=<Locality Name>/O=<Organisation Name>/emailAddress=<email>/CN=<Common Name>.
	cd /etc/ssl/mongodbkeys/test/
	openssl req -out $rootCN.pem -new -x509 -days 3650 -subj "/C=GB/ST=HAMPSHIRE/L=PORTSMOUTH/O=AKERO/CN=$rootCN/emailAddress=$email"
    
    #Generate server .pem file:
    echo $(( 10 + RANDOM % 89 )) > file.srl # two random digits number
    openssl genrsa -out $serverCN.key 2048
    openssl req -key $serverCN.key -new -out $serverCN.req -subj  "/C=GB/ST=HAMPSHIRE/L=PORTSMOUTH/O=AKERO/CN=$serverCN/CN=$serverCNHostName/emailAddress=$email"
    openssl x509 -req -in $serverCN.req -CA $rootCN.pem -CAkey privkey.pem -CAserial file.srl -out $serverCN.crt -days 3650
    cat $serverCN.key $serverCN.crt > $serverCN.pem
    openssl verify -CAfile $rootCN.pem $serverCN.pem

    #Generate client.pem file:
    openssl genrsa -out $clientCN.key 2048
    openssl req -key $clientCN.key -new -out $clientCN.req -subj "/C=GB/ST=HAMPSHIRE/L/PORTSMOUTH/O=AKERO/CN=$clientCN/emailAddress=$email"
    openssl x509 -req -in $clientCN.req -CA $rootCN.pem -CAkey privkey.pem -CAserial file.srl -out $clientCN.crt -days 3650
    cat $clientCN.key $clientCN.crt > $clientCN.pem
    openssl verify -CAfile $rootCN.pem $clientCN.pem
}

justClientCA() {

    echo "Please enter the name of the rootCA file you would like to reuse to make new clients."
    read -p "RootCN: " rootCN
	echo "Please enter a client common name, this can be whatever you want, I suggest your name or client1."
	read -p "Client common name: " clientCN
	while [ -z "$clientCN" ] 
	do
		echo "Client CN missing please enter a client CN."
		read -p "clientCN: " clientCN
	done

	echo "Please enter a valid email. e.g. user@domain.com"
	read -p "Email: " email
	while [ -z "$email" ] 
	do
		echo "Email Argument Missing, please enter an email."
		read -p "Email: " email
	done
	cd /etc/ssl/mongodbkeys/test/
    #Generate client.pem file:
    openssl genrsa -out $clientCN.key 2048
    openssl req -key $clientCN.key -new -out $clientCN.req -subj "/C=GB/ST=HAMPSHIRE/L/PORTSMOUTH/O=AKERO/CN=$clientCN/emailAddress=$email"
    openssl x509 -req -in $clientCN.req -CA $rootCN.pem -CAkey privkey.pem -CAserial file.srl -out $clientCN.crt -days 3650
    cat $clientCN.key $clientCN.crt > $clientCN.pem
    openssl verify -CAfile $rootCN.pem $clientCN.pem
}


printf "Wellcome to Akeros mongodb local ssl generator \n"

printf "If you are setting up a new mongodb server press 1 otherwise press enter to add more client keys"
read -p "Enter choice: " choice
if [ $choice == "1" ]
then
	rootCAServerCAAndClientCA
else
	justClientCA
fi


#After generating the .pem files, now you can run mongod. for example:

#mongod --sslMode requireSSL --sslPEMKeyFile ~/server.pem --sslCAFile ~/ca.pem
#You can test the connection using the mongo shell, for example:

#mongo --ssl --sslPEMKeyFile ~/client.pem --sslCAFile ~/ca.pem --host <server hostname>
