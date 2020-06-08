#!/bin/bash
logger *** TF Remote-Exec Started ***
  echo "DBS :: Remote-Exec :: Let's get started.."
  
    echo "DBS :: Remote-Exec :: Adding & updating package repo's.."
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm -q -y >>/tmp/noise.txt
    echo "DBS :: Remote-Exec :: Adding & updating package repo's.. :: Done.."
  
    echo "DBS :: Remote-Exec :: Installing packages.."
        yum install mysql mysql-server -q -y
    echo "DBS :: Remote-Exec :: Installing packages.. :: Done.."
  
    echo "DBS :: Remote-Exec :: Starting services.."
        chkconfig mysqld on
        service mysqld start >>/tmp/noise.txt
    echo "DBS :: Remote-Exec :: Starting services.. :: Done.."

    echo "DBS :: Remote-Exec :: Configuaration.."
        mysql -uroot < /tmp/dbs-script.sql
    echo "DBS :: Remote-Exec :: Configuaration.. :: Done.."

  echo "DBS :: Remote-Exec :: Done.."
logger *** TF Remote-Exec Stopped ***