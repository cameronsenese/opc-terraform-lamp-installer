#!/bin/bash
logger *** TF Remote-Exec Started ***
  echo "APP :: Remote-Exec :: Let's get started.."
  
    echo "APP :: Remote-Exec :: Adding & updating package repo's.."
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm -q -y >>/tmp/noise.txt
    echo "APP :: Remote-Exec :: Adding & updating package repo's.. :: Done.."
  
    echo "APP :: Remote-Exec :: Installing packages.."
        yum install mysql phpMyAdmin httpd php -q -y
    echo "APP :: Remote-Exec :: Installing packages.. :: Done.."
  
    echo "APP :: Remote-Exec :: Configuaration files.."
        sed -i '/Allow from 127/ c\     Allow from All' /etc/httpd/conf.d/phpMyAdmin.conf
        cp /tmp/web/config.inc.php /etc/phpMyAdmin/
        cp /tmp/web/httpd.conf /etc/httpd/conf/httpd.conf
    echo "APP :: Remote-Exec :: Configuaration files.. :: Done.."
    
    echo "APP :: Remote-Exec :: Starting services.."
        chkconfig httpd on
        service httpd start >>/tmp/noise.txt
    echo "APP :: Remote-Exec :: Starting services.. :: Done.."
  
  echo "APP :: Remote-Exec :: Done.."
logger *** TF Remote-Exec Stopped ***