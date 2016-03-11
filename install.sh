#!/usr/bin/env bash

# Creates new dhis user
createDhisUser() {
    echo "############################## Creating new user ##############################"

    # create user with given home directory and shell
    useradd -d /home/dhis -m dhis -s /bin/bash

    # Add dhis to user group with right to use sudo
    usermod -G sudo dhis
}

# Installs PostgreSQL, creates user/role and database
installPostgreSQL() {
    echo "############################## PostgreSQL  ##############################"

    # Install database from ubuntu's PPA
    apt-get -y -q install postgresql postgresql-contrib

    # Create new database user
    su -c 'psql -c "CREATE USER dhis WITH PASSWORD '"'district'"'"' postgres

    # Create new database
    su -c 'psql -c "CREATE DATABASE dhis2 WITH OWNER dhis"' postgres
}

# Installs Oracle JDK and sets JAVA_HOME environment variable
installOracleJdk() {
    echo "############################## Oracle JDK ##############################"

    # First we need to add repos with JDK installer
    apt-get -y -q install python-software-properties
    add-apt-repository -y ppa:webupd8team/java

    # Fetching packages from newly added repositories
    apt-get -y -qq update

    # Installing debconf-utils in order to make silent installation (accept oracle license).
    apt-get -y -q install debconf-utils
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

    # Installing actual JDK
    apt-get -y -qq install oracle-java8-installer
}

# Installs Tomcat
installTomcat() {
    echo "############################## Tomcat ##############################"

    # Install Tomcat server
    apt-get -y -q install tomcat7-user

    # Create tomcat user
    tomcat7-instance-create /home/dhis/tomcat-dhis/

    # Setting JAVA_HOME environment variable
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle/" >> /home/dhis/tomcat-dhis/bin/setenv.sh

    # Giving more memory to JVM
    echo "export JAVA_OPTS='-Xmx7500m -Xms4000m'" >> /home/dhis/tomcat-dhis/bin/setenv.sh

    # Export DHIS2_HOME environment variable which points to configuration
    echo "export DHIS2_HOME=/home/dhis/config" >> /home/dhis/tomcat-dhis/bin/setenv.sh
}

# Create hibernate configuration file for DHIS2
createHibernateConfiguration() {
    echo "############################## Creating hibernate configuration  ##############################"

    # Create configuration directory
    mkdir /home/dhis/config

    # Create configuration file
    touch /home/dhis/config/dhis.conf

    # Hibernate SQL dialect
    echo "connection.dialect = org.hibernate.dialect.PostgreSQLDialect" >> /home/dhis/config/dhis.conf

    # JDBC driver class
    echo "connection.driver_class = org.postgresql.Driver" >> /home/dhis/config/dhis.conf

    # JDBC driver connection URL
    echo "connection.url = jdbc:postgresql:dhis2" >> /home/dhis/config/dhis.conf

    # Database username
    echo "connection.username = dhis" >> /home/dhis/config/dhis.conf

    # Database password
    echo "connection.password = district" >> /home/dhis/config/dhis.conf

    # Database schema behavior, can be validate, update, create, create-drop
    echo "connection.schema = update" >> /home/dhis/config/dhis.conf

    # Encryption password (sensitive)
    echo "encryption.password = district" >> /home/dhis/config/dhis.conf
}

# Download dhis.war
downloadDhisWar() {
    echo "############################## Downloading DHIS2 war file  ##############################"

    # Download .war file from CI
    wget --progress=bar https://www.dhis2.org/download/releases/2.22/dhis.war -O /home/dhis/tomcat-dhis/webapps/ROOT.war
}

# Add script which will force tomcat to start on boot
configureTomcat() {
    echo "############################## Configuring Tomcat  ##############################"

    
}


installDhis2Instance() {
    # Update repos first
    apt-get -qq update

    createDhisUser
    installPostgreSQL
    installOracleJdk
    installTomcat
    createHibernateConfiguration
    downloadDhisWar
}


# Start installation
installDhis2Instance
