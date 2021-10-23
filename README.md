
# Moodle
---------

Moodle(TM) is a very popular open source learning management solution (LMS) for the delivery of elearning courses and programs. It’s used not only by universities, but also by hundreds of corporations around the world who provide eLearning education for their employees. Moodle(TM) features a simple interface, drag-and-drop features, role-based permissions, deep reporting, many language translations, a well-documented API and more. With some of the biggest universities and organizations already using it, Moodle(TM) is ready to meet the needs of just about any size organization.

https://moodle.org/

--------------------------------------------------------------------------

This repository contains a deployment script and terraform configuration file to deploy all the needed resources for moodle platform on azure.

Azure resources will be deployed :

 > resource group for moodle resources

 > virtual network with 3 subnets (appgw , vmss , netapp)

 > azure mysql server

 > netapp account , pool , volume

 > ubuntu virtual machine (application server) with cloud-config script to install (apache , moodle software and dependencies and configure permissions)

 > azure cache for redis instance
 
 > application gateway

before running the deployment you must consider the following : 

> Make sure to prepare your azure subscription for netapp account creation and you can find more information on the below link :

https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-create-netapp-account#before-you-begin

> customize the SKUs for mysql , virtual machine , Redis Cache and any parameters according to your requirements.

Deployment Steps : 
-------------------

run terraform config file to deploy the infrastructure resources 

After successful deployment of azure infrastructure resources you have to do the following :

navigate to azure portal and make sure that the above mentioned resources has been succesfully deployed.

Open your browser and go to http://serverpublicip and you'll find moodle installation page , now go back to azure portal : 

> configure private endpoint for Mysql also don't forget to enable azure defender for mysql.

> configure private endpoint for Redis Cache

connect to the created ubuntu vm and copy "deployment-config.sh" content and change the parameters of the netapp , mysql , installer script parameters to your own 

ones and run the script which will do the following :  ( OR use "custom script extension" to run the script for you )

> create a database for moodle and a user with the proper permissions

> mount the netapp volume and configure automounting 

> run the installer script with the configured parameters to configure moodle

Now you can go back to your browser and refresh moodle page you'll find that the installation has been finished succesfully.

 Moodle Configuration :
--------------------------------------

Open /var/www/html/config.php 

> change "$CFG->wwwroot" to your domain instead of the public ip.

-------------------------------------------------------------------------

Now you have to generalize the virtual machine and create a custom image to be used for the virtual machine scale set creation

> for azure linux vm generalize check this link : https://docs.microsoft.com/bs-cyrl-ba/azure/virtual-machines/generalize

---------------------------------------------------------------------------

Final step is to add the created scaleset nic as a backend target and you're done.

Note that : Moodle can be implemented using different architecture and with different azure resources for ex: you can use azure sql instead of mysql or azure file
share instaed of netapp.
