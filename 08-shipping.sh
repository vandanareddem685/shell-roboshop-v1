#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="practicedaws92s.online"
scripts_dir=$(dirname "$(realpath "$0")")

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access.."
    exit 1
fi

mkdir -p $logs_folder

timestamp(){  
    date "+%F %T" 
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing java and maven"

alternatives --set java /usr/lib/jvm/java-25-openjdk/bin/java
validate $? "setting java 25 as default java version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "setting JAVA_HOME for maven"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Creating system user"
else
    echo -e "$(timestamp) [INFO] System user roboshop already exist...${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "Downloading shipping"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "Unzipping shipping"

cd /app
mvn clean package &>> $logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "moving shippingjar file"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service"
cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y &>> $logs_file
validate $? "installing mysql client"

COUNT=$(mysql -h mysql.$domain_name -u root -pRobosho@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file)
if [ -z "$COUNT"] || [ "$COUNT" -eq 0 ];then
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
    valdiate $? "loading shipping data"
else
    echo -e "$(timestamp)[INFO] Master Data aleady loaded .. ${Y}SKIPPING{N}"
fi

mysql -h mysql.$domain_name -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "creating APP user"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl restart shipping &>> $logs_file
validate $? "Starting and enabling shipping"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file