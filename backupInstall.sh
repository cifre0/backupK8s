#!/bin/bash


######################################## 
### Script deployement Backup Server ###
########################################
"""
# lien de telechargement:
# curl -so ./script_install_backup.sh https://raw.githubusercontent.com/cifre0/backupK8s/main/backupInstall.sh
"""

###########
### VAR ###
###########
function gestion_erreur () {
    if [ "$?" -eq "0" ]; then printf "$1    \U2705\n\n"; else printf "\U2620 Failed \U2757\U2757\U2757\n"; exit 1; fi
}

function recommence (){
      if [ "$?" -eq "0" ]; then echo true; else echo false; exit 1; fi
}

function test_command () {
  test=$( if [ -x "$(command -v $1)" ]; then echo true; else echo false; fi )
  if [ $test = true ]; then echo "$1 is installed"; return 3; fi;
}


function maj_values() {
  mkdir -p /etc/backup-cbox

  if [[ ! -f /etc/backup-cbox/valuesSrvBackup.yml ]]; then curl -so /etc/backup-cbox/valuesSrvBackup.yml https://raw.githubusercontent.com/cifre0/backupK8s/main/valuesSrvBackup.yml; fi
  test_command yq  
  if [[ $? = 3 ]]
  then
    IP_INTERNAL=$( yq e '.srv-backup.SYSTEM.IP_INTERNAL' /etc/backup-cbox/valuesSrvBackup.yml )
    IP_EXTERNAL=$( yq e '.srv-backup.SYSTEM.IP_EXTERNAL' /etc/backup-cbox/valuesSrvBackup.yml )
    DISK_MOUNTED_FOR_MINIO=$( yq e '.srv-backup.SYSTEM.DISK_MOUNTED_FOR_MINIO' /etc/backup-cbox/valuesSrvBackup.yml )
    IP_PROD_CBOX=$( yq e '.srv-backup.SYSTEM.IP_PROD_CBOX' /etc/backup-cbox/valuesSrvBackup.yml )
    USER_PROD_CBOX=$( yq e '.srv-backup.SYSTEM.USER_PROD_CBOX' /etc/backup-cbox/valuesSrvBackup.yml )
    FQDN=$( yq e '.srv-backup.RKE2.FQDN' /etc/backup-cbox/valuesSrvBackup.yml )
    FQDN_CONSOLE=$( yq e '.srv-backup.MINIO.FQDN_CONSOLE' /etc/backup-cbox/valuesSrvBackup.yml )
    FQDN_MINIO_BACKUP=$( yq e '.srv-backup.MINIO.FQDN_MINIO_BACKUP' /etc/backup-cbox/valuesSrvBackup.yml )
    LOCAL_VOLUME_MINIO=$( yq e '.srv-backup.MINIO.LOCAL_VOLUME' /etc/backup-cbox/valuesSrvBackup.yml )
    TIME_DELAY_RETENTION=$( yq e '.srv-backup.MINIO.TIME_DELAY_RETENTION' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ALIAS_NAME' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_PROVIDER=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_PROVIDER' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_ACCESS_KEY=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ACCESS_KEY' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_SECRET_KEY=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_SECRET_KEY' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_ENDPOINT=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ENDPOINT' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_PORT_ENDPOINT=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_PORT_ENDPOINT' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_ACL=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ACL' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ALIAS_NAME' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_PROVIDER=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_PROVIDER' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_ACCESS_KEY=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ACCESS_KEY' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_SECRET_KEY=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_SECRET_KEY' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_REGION=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_REGION' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_ACL=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ACL' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_ENDPOINT=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ENDPOINT' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_PORT_ENDPOINT=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_PORT_ENDPOINT' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.SYNC.S3_PROD_ALIAS_NAME' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_PROD_BUCKET_NAME=$( yq e '.srv-backup.RCLONE.SYNC.S3_PROD_BUCKET_NAME' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_ALIAS_NAME' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_BUCKET_NAME_OBJ=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_BUCKET_NAME_OBJ' /etc/backup-cbox/valuesSrvBackup.yml )
    S3_BACK_BUCKET_BDD=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_BUCKET_BDD' /etc/backup-cbox/valuesSrvBackup.yml )
    BDD_WORKSPACE_PROD_CBOX=$( yq e '.srv-backup.RCLONE.K8S.WORKSPACE_PROD_CBOX_BDD' /etc/backup-cbox/valuesSrvBackup.yml )
    BDD_POD_NAME_PROD_CBOX=$( yq e '.srv-backup.RCLONE.K8S.POD_NAME_PROD_CBOX_BDD' /etc/backup-cbox/valuesSrvBackup.yml )
    BDD_TABLE_PROD_CBOX=$( yq e '.srv-backup.K8S.BDD.TABLE_PROD_CBOX' /etc/backup-cbox/valuesSrvBackup.yml )
    BDD_USERNAME_PROD_CBOX=$( yq e '.srv-backup.K8S.BDD.USERNAME_PROD_CBOX' /etc/backup-cbox/valuesSrvBackup.yml )

    gestion_erreur "Mise à jour des variables"
  else
    install_dependance
    maj_values
  fi
}

function open_backup-cbox_values() {
    echo
    nano  /etc/backup-cbox/valuesSrvBackup.yml
}

###############
### Install ###
###############
function install_dependance() {
  apt update &> /dev/null
  gestion_erreur "update"
  apt install -y net-tools moreutils parallel jq wget curl &> /dev/null
  gestion_erreur "net-tools moreutils parallel qq"
  DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass &> /dev/null
  gestion_erreur "sshpass"
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 &> /dev/null
  chmod a+x /usr/local/bin/yq 
  gestion_erreur "yq"
  hostnamectl set-hostname srv-backup &> /dev/null
  gestion_erreur "hostname"
}

function install_kubectl() {
  test_command kubectl 
  if [[ $? != 3 ]]
    then
      # install kubectl
      curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl &> /dev/null
      chmod +x ./kubectl 
      mv ./kubectl /usr/local/bin/kubectl
      kubectl version --client &> /dev/null
      gestion_erreur "kubectl"
  fi
      ### auto-completion
      # tet if auto-completion
      test_completion=$(complete -p | grep kubectl)
      resultat_if_test_ok="complete -o default -F __start_kubectl kubectl complete -o default -F __start_kubectl k"
    if [[ $test_completion != $resultat_if_test_ok ]]
      then
        source /usr/share/bash-completion/bash_completion
        echo 'source <(kubectl completion bash)' >>~/.bashrc
        kubectl completion bash >/etc/bash_completion.d/kubectl
        echo 'alias k=kubectl' >>~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
  fi
  gestion_erreur "auto-completion kubectl"
}

function install_rke() {
  test_command rke
    if [[ $? != 3 ]]
      then
        # $IP_PUB $IP_INTERNAL $FQDN
        if [ ! -f "/etc/rancher/rke2/config.yml" ]
          then
            mkdir -p /etc/rancher/rke2
            curl -so /etc/rancher/rke2/config.yml https://raw.githubusercontent.com/cifre0/backupK8s/main/rkeMonoNode/config.yml &> /dev/null

            #echo  /etc/rancher/rke2/config.yml
            var=$FQDN yq e '.tls-san[0] = env(var)' -i /etc/rancher/rke2/config.yml
            var=$IP_INTERNAL yq e '.node-ip = env(var)' -i /etc/rancher/rke2/config.yml
            var=$IP_INTERNAL yq e '.advertise-address = env(var)' -i /etc/rancher/rke2/config.yml
            var=$IP_EXTERNAL yq e '.node-external-ip = env(var)' -i /etc/rancher/rke2/config.yml
        else
          echo "le fichier /etc/rancher/rke2/config.yml existe deja"
        fi

        curl -sfL https://get.rke2.io | sh - &> /dev/null
        systemctl enable rke2-server.service &> /dev/null
        systemctl start rke2-server.service &> /dev/null
        mkdir -p .kube
        cp /etc/rancher/rke2/rke2.yaml .kube/config
        if [ $(systemctl is-active rke2-server.service) == "active" ];
        then 
              echo "Service RKE is run" ; 
        else
              echo "debug service with journalctl -u rke2-server -f"; 
              exit; 
        fi
    fi
        ### debug service: journalctl -u rke2-server -f

        ### verifie que le noeud K8s exist
        kubectl get nodes 
        if [ $? == 0 ]; then echo "RKE est bien installé"; else tee >> log.txt; exit; fi
}

#############
### MINIO ###
#############
function install_client_mc() {

  test_command mc 
  if [[ $? != 3 ]]
    then
      # telecharge le client mc
      curl https://dl.min.io/client/mc/release/linux-amd64/mc \
        --create-dirs -s \
        -o $HOME/minio-binaries/mc

      chmod +x $HOME/minio-binaries/mc
      export PATH=$PATH:$HOME/minio-binaries
      echo "export PATH=$PATH:$HOME/minio-binaries" >>~/.bashrc
      source .bashrc
  fi
}

function install_minio() {
  FILE_MINIO="namespaceMinio.yml podMinio.yml serviceMinio.yml ingressMinio.yml"
  # IP_INT=$(kubectl get node -o yaml | yq e '.items[].metadata.annotations."etcd.rke2.cattle.io/node-address"')
  # uninstall minio
  #kubectl minio delete -n dev-minio
  
  # tceck if ns dev-minio exist for create the ns
  # if [[ $( kubectl get ns | cut -d' ' -f1 | grep dev-minio ) != dev-minio ]]; then kubectl create ns dev-minio; fi

  # telecharger le minio-dev.yaml
  mkdir -p /etc/minio
  for i in $FILE_MINIO; do curl -so /etc/minio/$i https://raw.githubusercontent.com/cifre0/backupK8s/main/minio/$i; done
  var=$IP_INTERNAL yq e ''.spec.externalIPs[0]' = env(var)' -i /etc/minio/serviceMinio.yml
  var=$IP_INTERNAL yq e ''.status.loadBalancer.ingress[].ip' = env(var)' -i /etc/minio/ingressMinio.yml
  # modife FQDN ingress
  var=$FQDN_MINIO_BACKUP yq e ''.spec.rules[0].host' = env(var)' -i /etc/minio/ingressMinio.yml
  var=$FQDN_CONSOLE yq e ''.spec.rules[1].host' = env(var)' -i /etc/minio/ingressMinio.yml
  # modife local volume minio
  var=$LOCAL_VOLUME_MINIO yq e ''.spec.volumes[0].hostPath.path' = env(var)' -i /etc/minio/podMinio.yml
  ### if hostname -ne to host node
  #yq e '.spec.nodeSelector."kubernetes.io/hostname"'

  # folder de montage
  mkdir -p $LOCAL_VOLUME_MINIO
  lsblk -o NAME,UUID,MOUNTPOINT -l
  # delete partition
  # for i in {1..4};do dd if=/dev/zero of=/dev/nvme"$i"n1 bs=1M count=1; done

  for i in $DISK_MOUNTED_FOR_MINIO; 
  do 
  # creer un file systeme
  if [[ $( file -s $i | awk ' { print $2 } ') = "data" ]]
  then
    # create filesystem ext4
    mkfs.ext4 -b 4096 $i
  fi
  
  if [[ $( lsblk -o MOUNTPOINT -r -n $i ) != "$LOCAL_VOLUME_MINIO" ]]
  then
    # monter le(s) disk
    mount $i $LOCAL_VOLUME_MINIO
  fi

  ### $DISK_MOUNTED_FOR_MINIO $UUID_DISK_MOUNTED
  ### 
  UUID_DISK_MOUNTED=$( blkid $i -s UUID -o value );
  # tcheck if UUID presente in file /etc/fstab
  test=$( cat /etc/fstab | grep -o $UUID_DISK_MOUNTED )
  if [[ $test == $UUID_DISK_MOUNTED ]];
  then 
    echo "$UUID_DISK_MOUNTED est deja present sur le fichier /etc/fstab";
  else 
    ### mettre le montage dans /etc/fstab;
    echo "UUID=$UUID_DISK_MOUNTED /mnt/DataStore    ext4    rw,relatime   0   0" >> /etc/fstab ; 
  fi
  done
  
  ### apply the config
  for i in $FILE_MINIO; do kubectl apply -f /etc/minio/$i; done

}

function create_alias_minio(){
  
  ### create alias
  ### mc alias set ALIAS URL ACCESSKEY SECRETKEY
  # if [[ $S3_BACK_PORT_ENDPOINT != 9000 ]]
  # then
  #   mc alias set $S3_BACK_ALIAS_NAME http://$IP_INTERNAL:$S3_BACK_PORT_ENDPOINT $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY;
  # else
  #   mc alias set $S3_BACK_ALIAS_NAME http://$IP_INTERNAL $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY;
  # fi
  mc alias set $S3_BACK_ALIAS_NAME http://$IP_INTERNAL:$S3_BACK_PORT_ENDPOINT $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY;
  mc alias list $S3_BACK_ALIAS_NAME
}

"""
### monter les disks pour minio + definir chemin de montage
df -h
lsblk --output NAME,SIZE

mount /dev/sbX /mnt/DataStore

# pour monter le disk le faire dans /etc/fstab  et faire fdisk -l pour voir le UID
### Obtenir UUID des disks 
lsblk --fs

# delete bucket
mc rb alias/bucketName
# delete file to bucket
mc rm alias/bucketName
"""

function create_bucket_minio() {
  ###Creer 2 buckets BDD et S3(objectStorage)
  mc mb $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_BDD
  mc version enable $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_BDD

  mc mb --with-versioning --with-lock $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_NAME_OBJ #versionning, et objectloking
  mc retention set --default GOVERNANCE \"$TIME_DELAY_RETENTION\" $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_NAME_OBJ # delais de retention
  mc version enable $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_NAME_OBJ
  mc ls $S3_BACK_ALIAS_NAME
}

#############
## rclone ###
#############
function install_rclone() {
  test_command rclone
  if [[ $? != 3 ]]
    then
      # install rclone
      mkdir -p /etc/rclone
      curl https://rclone.org/install.sh -s | bash &>/dev/null
  fi
}
"""
# rclone cmd
rclone config
.config/rclone/rclone.conf

# corp du fichier rclone.conf
https://rclone.org/s3/

[squeletteAWS]
type = s3
provider = AWS
env_auth = false
access_key_id = XXX
secret_access_key = YYY
region = eu-west-3
location_constraint = eu-west-3
acl = private
storage_class = STANDARD
bucket_acl = public-read-write

[squeletteCeph]
type = s3
provider = Ceph
access_key_id = 
secret_access_key = 
endpoint = https://s3.rpi.ercom.training
acl = private

[squeletteMinio]
type = s3
provider = Minio
access_key_id = minioadmin
secret_access_key = minioadmin
region = other-v2-signature
acl = bucket-owner-full-control
endpoint = http://172.19.130.178:9000

cat <<EOF > .config/rclone/rclone.conf
[$S3_PROD_ALIAS_NAME]
type = s3
provider = $S3_PROD_PROVIDER
access_key_id = $S3_PROD_ACCESS_KEY
secret_access_key = $S3_PROD_SECRET_KEY
endpoint = https://$S3_PROD_ENDPOINT
acl =  # default: private

[$S3_BACK_ALIAS_NAME]
type = s3
provider = $S3_BACK_PROVIDER
access_key_id = $S3_BACK_ACCESS_KEY
secret_access_key = $S3_BACK_SECRET_KEY
region = $S3_BACK_REGION # default: other-v2-signature
acl = $S3_BACK_ACL #default: bucket-owner-full-control
endpoint = http://$S3_BACK_ENDPOINT:$S3_BACK_PORT_ENDPOINT # default port 9000
EOF
"""

function create_alias_rclone() {
  ### PROD CBOX: $S3_PROD_ALIAS_NAME $S3_PROD_PROVIDER $S3_PROD_ACCESS_KEY $S3_PROD_SECRET_KEY $S3_PROD_ENDPOINT $S3_PROD_ACL $S3_PROD_BUCKET_NAME
  ### BACKUP: $S3_BACK_ALIAS_NAME $S3_BACK_PROVIDER $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY $S3_BACK_REGION $S3_BACK_ACL $S3_BACK_ENDPOINT $S3_BACK_PORT_ENDPOINT $S3_BACK_BUCKET_NAME_OBJ
  ### create alias PROD and BACKUP
  # if [[ "${S3_PROD_PROVIDER,,}" = "aws" ]]
  if [[ $S3_BACK_PORT_ENDPOINT != 9000 ]]
    then
      rclone config create $S3_PROD_ALIAS_NAME s3 provider=$S3_PROD_PROVIDER access_key_id=$S3_PROD_ACCESS_KEY secret_access_key=$S3_PROD_SECRET_KEY endpoint=$S3_PROD_ENDPOINT:$S3_PROD_PORT_ENDPOINT acl=$S3_PROD_ACL
    else
      rclone config create $S3_PROD_ALIAS_NAME s3 provider=$S3_PROD_PROVIDER access_key_id=$S3_PROD_ACCESS_KEY secret_access_key=$S3_PROD_SECRET_KEY endpoint=$S3_PROD_ENDPOINT acl=$S3_PROD_ACL
  fi
  rclone config create $S3_BACK_ALIAS_NAME s3 provider=$S3_BACK_PROVIDER access_key_id=$S3_BACK_ACCESS_KEY secret_access_key=$S3_BACK_SECRET_KEY region=$S3_BACK_REGION acl=$S3_BACK_ACL endpoint=$S3_BACK_ENDPOINT:$S3_BACK_PORT_ENDPOINT
}

function backup_S3() {
  # cmd rclone pour synch
  # rclone sync source:path dest:path [flags]
  # --no-check-certificate if self signed
  rclone sync -P $S3_PROD_ALIAS_NAME:$S3_PROD_BUCKET_NAME $S3_BACK_ALIAS_NAME:$S3_BACK_BUCKET_NAME_OBJ

}

function check_if_key(){
  if_not_priv_key=$( echo -e "\n" | ssh-keygen -t rsa -N "" )
  if_not_pub_key=$( ssh-keygen -f .ssh/id_rsa -y > .ssh/id_rsa.pub )
  
  if [ ! -f ~/.ssh/id_rsa ]; then $if_not_priv_key; fi
  if [ ! -f ~/.ssh/id_rsa.pub ]; then $if_not_pub_key; fi
}


function modify_conf_ssh(){
  REPLY=""
  PARAM_SSH="PasswordAuthentication yes"
  PATH_CONF_SSH="/etc/ssh/sshd_config"
  PUB_KEY=$( cat ~/.ssh/id_rsa.pub )
  while [[ ! $REPLY =~ ^[Yy]$  ]]; 
  do  
      printf "modify conf ssh to SRV PROD CBOX for adding pub.key%s\n"
      printf  "PATH: \"$PATH_CONF_SSH\"%s\n"
      printf  "parameter: \"$PARAM_SSH\"%s\n"
      printf  "public key: \"$PUB_KEY\"%s\n"
      /usr/bin/sleep 20s;
      printf "Do you modify and apply the conf ssh ?(Yy)%s\n"
      read REPLY;
  done
}

function add_key_pub(){
  """  
  REPLY=""
  KEY_PUB=$( cat .ssh/id_rsa.pub )
  while [[ ! $REPLY =~ ^[Yy]$  ]]; 
  do  printf 'add pub key to SERVER PROD CBOX %s\n' 'PATH: ~/.ssh/authorized_keys %s\n' "key: $KEY_PUB"; 
      sleep 20s;
      printf 'Do you add the key ?(Yy)'
      read REPLY;
      sleep 10s; 
  done
  """
  echo "Please insert the password used for ssh login on remote machine:"
  read -s USERPASS

  while [ true ]
  do
      echo "$USERPASS" | sshpass ssh-copy-id -f "$USER_PROD_CBOX"@"$IP_PROD_CBOX"
      if [[ $? != 0 ]]
      then    
            modify_conf_ssh;
      else
            sshpass -p $USERPASS ssh-copy-id -o "StrictHostKeyChecking=no" -f -i .ssh/id_rsa.pub "$USER_PROD_CBOX"@"$IP_PROD_CBOX"
            break
      fi
  done
  # reset password
  USERPASS=""
  printf 'Warning: Do not forgot to back follow parameter in server Prod CBOX %s\n' "PasswordAuthentication no %s\n" "and -> systemctl restart sshd"
}

function backup_BDD() {
  check_if_key
  add_key_pub
  #CMD_SSH="ssh -o \"StrictHostKeyChecking=no\" $USER_PROD_CBOX@$IP_PROD_CBOX sudo -i "
  CMD_SSH="ssh -o \"StrictHostKeyChecking=no\" $USER_PROD_CBOX@$IP_PROD_CBOX sudo -i "
  PASS_PSQL_PROD_CBOX=$( $CMD_SSH kubectl get secret -n $BDD_WORKSPACE_PROD_CBOX bdd-postgresql -o yaml | yq e '.data.postgres-password' | base64 -d )
  $CMD_SSH kubectl exec -it -n $BDD_WORKSPACE_PROD_CBOX $BDD_POD_NAME_PROD_CBOX -- bash -c "PGPASSWORD=$PASS_PSQL_PROD_CBOX pg_dumpall -U $BDD_USERNAME_PROD_CBOX" 2>dump_error.log | mc pipe $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_BDD/allDATACbox.sql


  """
  # add ip container bdd 
   kubectl get pod -n psql -o yaml | yq e '.items[0].status.podIP'
  # mdp container
   kubectl get secret -n psql bdd-postgresql -o yaml | yq e '.data.postgres-password' | base64 -d
  # pgdumpall BDD
   kubectl exec -it -n psql bdd-postgresql-0 -- bash -c "PGPASSWORD=z6dgFMMqqO pg_dumpall -U postgres" > allDataCbox.sql
  # copi file to bucket
   mc cp ./allDataCbox.sql backup/bdd/
  # copie dump directly to bucket
   kubectl exec -it -n psql bdd-postgresql-0 -- bash -c "PGPASSWORD=z6dgFMMjqO pg_dumpall -U postgres" 2>dump_error.log | mc pipe backup/bdd/allDATACbox.sql
  """
}

function restore_S3() {
  echo "In Progress"
  """
  Example:
   rclone copy -P minio:obj backuptest:ceph-bkt-cc10312f-8203-49ed-93ee-691sfsdfdvsdf
  """

}

function restore_BDD() {
  echo "In Progress"
  """
  ssh -o \"StrictHostKeyChecking=no\" root@17.26.30.160 sudo -i PGPASSWORD=z6dgFMMjqO psql -U postgres -d postgres -h 10.43.67.110 < $(mc cat myminio/bdd/allDATACbox.sql)
  mc cat myminio/bdd/allDATACbox.sql > ssh -o \"StrictHostKeyChecking=no\" root@17.26.30.160 sudo -i PGPASSWORD=z6dgFMMjqO psql -U postgres -d postgres -h 10.43.67.110
  """
}

##
# Color  Variables
##
green='\e[32m'
blue='\e[34m'
clear='\e[0m'

##
# Color Functions
##

function ColorGreen(){
	echo -ne $green$1$clear
}
function ColorBlue(){
	echo -ne $blue$1$clear
}

function menu(){
clear
echo -ne "
Menu

$(ColorGreen '1)') Start-up configuration
$(ColorGreen '2)') Generate values
$(ColorGreen '3)') install kubernetes
$(ColorGreen '4)') install minio
$(ColorGreen '5)') install rclone
$(ColorGreen '6)') backup BDD
$(ColorGreen '7)') backup S3
$(ColorGreen '8)') restore BDD
$(ColorGreen '9)') restore S3
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
        	1) install_dependance ; maj_values ; install_client_mc ; install_kubectl ; menu ;;
          2) maj_values ; clear; menu_generate ; menu ;;
	        3) maj_values ; install_rke ; menu ;;
	        4) maj_values ; install_minio ; create_alias_minio ; create_bucket_minio ; create_bucket_minio ; menu ;;
	        5) maj_values ; install_rclone ; create_alias_rclone ; menu ;;
	        6) maj_values ; backup_BDD ; menu ;;
	        7) maj_values ; backup_S3 ; menu ;;
          8) maj_values ; restore_BDD ; menu ;;
          9) maj_values ; restore_S3 ; menu ;;
		0) exit 0 ;;
		*) echo -e $red"Wrong option."$clear; menu;;
        esac
}

function menu_generate(){
    echo -ne "
    $(ColorBlue '1)') Edit values
    $(ColorBlue '2)') tcheck variable [DEBUG]
    $(ColorGreen 'q)') Go back
    $(ColorGreen 'Choose an option:') "
            read a
            case $a in
                    1) open_backup-cbox_values ; maj_values ; menu_generate ;;
                    2) maj_values ; edit_var ; menu_generate ;;
                    q) clear ;;
                    *) clear; echo -e $red"\n \U1F937 Wrong option."$clear ; menu_generate ;;
            esac
    }

function edit_var() {
  REPLY=""
  if [[ -f /etc/backup-cbox/valuesSrvBackup.yml ]];
  then 
  echo "IP_INTERNAL: $IP_INTERNAL"         
  echo "IP_EXTERNAL: $IP_EXTERNAL"
  echo "DISK_MOUNTED_FOR_MINIO: $DISK_MOUNTED_FOR_MINIO"         
  echo "IP_PROD_CBOX: $IP_PROD_CBOX"         
  echo "USER_PROD_CBOX: $USER_PROD_CBOX"         
  echo "FQDN: $FQDN"     
  echo "FQDN_CONSOLE: $FQDN_CONSOLE"
  echo "FQDN_MINIO_BACKUP: $FQDN_MINIO_BACKUP"
  echo "LOCAL_VOLUME_MINIO: $LOCAL_VOLUME_MINIO"
  echo "TIME_DELAY_RETENTION: $TIME_DELAY_RETENTION"
  echo "S3_PROD_ALIAS_NAME: $S3_PROD_ALIAS_NAME"
  echo "S3_PROD_PROVIDER: $S3_PROD_PROVIDER"
  echo "S3_PROD_ACCESS_KEY: $S3_PROD_ACCESS_KEY"
  echo "S3_PROD_SECRET_KEY: $S3_PROD_SECRET_KEY"
  echo "S3_PROD_ENDPOINT: $S3_PROD_ENDPOINT"
  echo "S3_PROD_PORT_ENDPOINT: $S3_PROD_PORT_ENDPOINT"
  echo "S3_PROD_ACL: $S3_PROD_ACL"
  echo "S3_BACK_ALIAS_NAME: $S3_BACK_ALIAS_NAME"
  echo "S3_BACK_PROVIDER: $S3_BACK_PROVIDER"
  echo "S3_BACK_ACCESS_KEY: $S3_BACK_ACCESS_KEY"
  echo "S3_BACK_SECRET_KEY: $S3_BACK_SECRET_KEY"
  echo "S3_BACK_REGION: $S3_BACK_REGION"
  echo "S3_BACK_ACL: $S3_BACK_ACL"
  echo "S3_BACK_ENDPOINT: $S3_BACK_ENDPOINT"
  echo "S3_BACK_PORT_ENDPOINT: $S3_BACK_PORT_ENDPOINT"
  echo "S3_PROD_ALIAS_NAME: $S3_PROD_ALIAS_NAME"
  echo "S3_PROD_BUCKET_NAME: $S3_PROD_BUCKET_NAME"
  echo "S3_BACK_ALIAS_NAME: $S3_BACK_ALIAS_NAME"
  echo "S3_BACK_BUCKET_NAME_OBJ: $S3_BACK_BUCKET_NAME_OBJ"
  echo "S3_BACK_BUCKET_BDD: $S3_BACK_BUCKET_BDD"
  echo "BDD_WORKSPACE_PROD_CBOX: $BDD_WORKSPACE_PROD_CBOX"
  echo "BDD_POD_NAME_PROD_CBOX: $BDD_POD_NAME_PROD_CBOX"
  echo "BDD_TABLE_PROD_CBOX: $BDD_TABLE_PROD_CBOX"
  echo "BDD_USERNAME_PROD_CBOX: $BDD_USERNAME_PROD_CBOX"
  fi
    while [[ ! $REPLY =~ ^[Yy]$  ]]; 
  do  
      echo ""
      printf "Do you finish to check variables ?(Yy)%s\n"
      read REPLY;
  done
  clear
}

########
# MAIN #
########

function main() {
  menu
}

main

# modifier le fichier ingress pour mettre le bon url: FAIT
# pour install create alias et bucket faire une verif si il existe alors exit la fonction: FAIT
# profile pour chaque provider rclone aws ceph et minio
# faire un cronjob
