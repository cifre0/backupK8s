#!/bin/bash


######################################## 
### Script deployement Backup Server ###
########################################
"""
# lien de telechargement:
 curl -so ./script_install_backup.sh https://raw.githubusercontent.com/cifre0/backupK8s/main/backupInstall.sh
# Le fichier d'install doit être dans le meme repertoire que le valuesSrvBackup.yml
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
  if [ $test = false ]; then echo $1 is installed; return 3; fi
}


function maj_values() {
IP_INTERNAL=$( yq e '.srv-backup.SYSTEM.IP_INTERNAL' ./valuesSrvBackup.yml )
DISK_MOUNTED_FOR_MINIO=$( yq e '.srv-backup.SYSTEM.DISK_MOUNTED_FOR_MINIO' ./valuesSrvBackup.yml )
IP_PROD_CBOX=$( yq e '.srv-backup.SYSTEM.IP_PROD_CBOX' ./valuesSrvBackup.yml )
USER_PROD_CBOX=$( yq e '.srv-backup.SYSTEM.USER_PROD_CBOX' ./valuesSrvBackup.yml )
FQDN=$( yq e '.srv-backup.RKE2.FQDN' ./valuesSrvBackup.yml )
S3_PROD_ALIAS_NAME=$( yq e .srv-backup.RCLONE.PROD.S3_PROD_ALIAS_NAME' ./valuesSrvBackup.yml' )
S3_PROD_PROVIDER=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_PROVIDER' ./valuesSrvBackup.yml )
S3_PROD_ACCESS_KEY=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ACCESS_KEY' ./valuesSrvBackup.yml )
S3_PROD_SECRET_KEY=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_SECRET_KEY' ./valuesSrvBackup.yml )
S3_PROD_ENDPOINT=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ENDPOINT' ./valuesSrvBackup.yml )
S3_PROD_PORT_ENDPOINT=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_PORT_ENDPOINT' ./valuesSrvBackup.yml )
S3_PROD_ACL=$( yq e '.srv-backup.RCLONE.PROD.S3_PROD_ACL' ./valuesSrvBackup.yml )
S3_BACK_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ALIAS_NAME' ./valuesSrvBackup.yml )
S3_BACK_PROVIDER=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_PROVIDER' ./valuesSrvBackup.yml )
S3_BACK_ACCESS_KEY=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ACCESS_KEY' ./valuesSrvBackup.yml )
S3_BACK_SECRET_KEY=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_SECRET_KEY' ./valuesSrvBackup.yml )
S3_BACK_REGION=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_REGION' ./valuesSrvBackup.yml )
S3_BACK_ACL=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ACL' ./valuesSrvBackup.yml )
S3_BACK_ENDPOINT=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_ENDPOINT' ./valuesSrvBackup.yml )
S3_BACK_PORT_ENDPOINT=$( yq e '.srv-backup.RCLONE.BACKUP.S3_BACK_PORT_ENDPOINT' ./valuesSrvBackup.yml )
S3_PROD_ALIAS_NAM=$( yq e '.srv-backup.RCLONE.SYNC.S3_PROD_ALIAS_NAM' ./valuesSrvBackup.yml )
S3_PROD_BUCKET_NAME=$( yq e '.srv-backup.RCLONE.SYNC.S3_PROD_BUCKET_NAME' ./valuesSrvBackup.yml )
S3_BACK_ALIAS_NAME=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_ALIAS_NAME' ./valuesSrvBackup.yml )
S3_BACK_BUCKET_NAME_OBJ=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_BUCKET_NAME_OBJ' ./valuesSrvBackup.yml )
S3_BACK_BUCKET_BDD=$( yq e '.srv-backup.RCLONE.SYNC.S3_BACK_BUCKET_BDD' ./valuesSrvBackup.yml )
CMD_SSH=$( ssh -o "StrictHostKeyChecking=no" $USER_PROD_CBOX@$IP_PROD_CBOX sudo -i )
BDD_WORKSPACE_PROD_CBOX=$( yq e '.srv-backup.K8S.WORKSPACE_PROD_CBOX_BDD' ./valuesSrvBackup.yml )
BDD_POD_NAME_PROD_CBOX=$( yq e '.srv-backup.K8S.POD_NAME_PROD_CBOX_BDD' ./valuesSrvBackup.yml )
BDD_TABLE_PROD_CBOX=$( yq e '.srv-backup.K8S.BDD.TABLE_PROD_CBOX' ./valuesSrvBackup.yml )
BDD_USERNAME_PROD_CBOX=$( yq e '.srv-backup.K8S.BDD.USERNAME_PROD_CBOX' ./valuesSrvBackup.yml )

echo "fin de la mise à jour des variables"
}

###############
### Install ###
###############
function install_dependance() {
  apt update
  gestion_erreur "update"
  apt install -y net-tools moreutils parallel jq
  gestion_erreur "net-tools moreutils parallel jq"
  DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass
  gestion_erreur "sshpass"
}

function install_kubectl() {
  test_command kubectl 
  # install kubectl
  curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
  kubectl version --client
  ### auto-completion
  source /usr/share/bash-completion/bash_completion
  echo 'source <(kubectl completion bash)' >>~/.bashrc
  kubectl completion bash >/etc/bash_completion.d/kubectl
  echo 'alias k=kubectl' >>~/.bashrc
  echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
  ### tcheck if kubectl is up

}

function install_rke() {
  test_command rke
  # $IP_PUB $IP_INTERNAL $FQDN
  mkdir -p /etc/rancher/rke2
  curl -so /etc/rancher/rke2/config.yml https://raw.githubusercontent.com/cifre0/backupK8s/main/rkeMonoNode/config.yml
  var=$FQDN yq e '.tls-san[0] = env(var)' -i /etc/rancher/rke2/config.yml
  var=$IP_INTERNAL yq e '.node-ip = env(var)' -i /etc/rancher/rke2/config.yml
  var=$IP_INTERNAL yq e '.advertise-address = env(var)' -i /etc/rancher/rke2/config.yml

  curl -sfL https://get.rke2.io | sh -
  systemctl enable rke2-server.service
  systemctl start rke2-server.service
  if [ $(systemctl is-active rke2-server.service) == "active" ];
  then 
        echo "Service RKE is run" ; 
  else
        echo "debug service with journalctl -u rke2-server -f"; 
        exit; 
  fi
  ### debug service: journalctl -u rke2-server -f

  ### verifie que le noeud K8s exist
  kubectl get nodes 
  if [ $? == 0 ]; then echo "RKE est bien installé"; else tee >> log.txt; exit fi
}

#############
### MINIO ###
#############
function install_client_mc() {

  test_command mc
  
  # telecharge le client mc
  curl https://dl.min.io/client/mc/release/linux-amd64/mc \
    --create-dirs \
    -o $HOME/minio-binaries/mc

  chmod +x $HOME/minio-binaries/mc
  export PATH=$PATH:$HOME/minio-binaries/
}

function install_minio() {
  
  # uninstall minio
  kubectl delete -n dev-minio

  # telecharger le minio-dev.yaml
  mkdir -p /etc/minio
  curl -so /etc/minio/installMinio.yml curl https://raw.githubusercontent.com/cifre0/backupK8s/main/minio/install.yml
  var=$IP_INTERNAL yq e '.spec.externalIPs[0] = env(var)' -i /etc/minio/installMinio.yml
  var=$IP_INTERNAL yq e '.status.ingress = env(var)' -i /etc/minio/installMinio.yml

  # folder de montage
  mkdir -p /mnt/DataStore
  # voir les disk monter
  ### $DISK_MOUNTED_FOR_MINIO $UUID_DISK_MOUNTED
  ### 
  UUID_DISK_MOUNTED=$( blkid $DISK_MOUNTED_FOR_MINIO -s UUID -o value )
  ### mettre le montage dans /etc/fstab
  echo "UUID=$UUID_DISK_MOUNTED /mnt/DataStore    ext4    rw,relatime   0   0" >> /etc/fstab

  ### apply the config
  kubectl apply -f /etc/minio/installMinio.yml
}

function create_alias_minio(){
  
  ### create alias
  ### mc alias set ALIAS URL ACCESSKEY SECRETKEY
  mc alias set ALIAS $IP_INTERNAL:$S3_BACK_PORT_ENDPOINT $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY

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

  mc mb --with-versioning --with-lock $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_NAME_OBJ #versionning, et objectloking
  mc retention set --default GOVERNANCE "1d" $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_NAME_OBJ # delais de retention
}

#############
## rclone ###
#############
function install_rclone() {

  test_command rclone
  # install rclone
  mkdir -p /etc/rclone
  curl https://rclone.org/install.sh | bash
}
"""
# rclone cmd
rclone config
.config/rclone/rclone.conf
# corp du fichier rclone.conf
"""

function create_alias_rclone() {
  ### PROD CBOX: $S3_PROD_ALIAS_NAME $S3_PROD_PROVIDER $S3_PROD_ACCESS_KEY $S3_PROD_SECRET_KEY $S3_PROD_ENDPOINT $S3_PROD_ACL $S3_PROD_BUCKET_NAME
  ### BACKUP: $S3_BACK_ALIAS_NAME $S3_BACK_PROVIDER $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY $S3_BACK_REGION $S3_BACK_ACL $S3_BACK_ENDPOINT $S3_BACK_PORT_ENDPOINT $S3_BACK_BUCKET_NAME_OBJ
  ### create alias PROD and BACKUP
  rclone config create $S3_PROD_ALIAS_NAME s3 provider=$S3_PROD_PROVIDER access_key_id=$S3_PROD_ACCESS_KEY secret_access_key=$S3_PROD_SECRET_KEY endpoint=http://$S3_PROD_ENDPOINT:$S3_PROD_PORT_ENDPOINT acl=$S3_PROD_ACL
  rclone config create $S3_BACK_ALIAS_NAME s3 provider=$S3_BACK_PROVIDER access_key_id=$S3_BACK_ACCESS_KEY secret_access_key=$S3_BACK_SECRET_KEY region=$S3_BACK_REGION acl=$S3_BACK_ACL endpoint=http://$S3_BACK_ENDPOINT:$S3_BACK_PORT_ENDPOINT
}
"""
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

function backup_S3() {
  # cmd rclone pour synch
  # rclone sync source:path dest:path [flags]
  rclone sync -P $S3_PROD_ALIAS_NAME:$S3_PROD_BUCKET_NAME $S3_BACK_ALIAS_NAME:$S3_BACK_BUCKET_NAME_OBJ
}

function check_if_key(){
  if_not_priv_key=$( echo -e "\n"|ssh-keygen -t rsa -N "" )
  if_not_pub_key=$( ssh-keygen -f .ssh/id_rsa -y > .ssh/id_rsa.pub )
  
  if [ -f .ssh/id_rsa ]; then  :; else $if_not_priv_key; fi
  if [ -f .ssh/id_rsa.pub ]; then  :; else $if_not_pub_key; fi
}


function modify_conf_ssh(){
  REPLY=""
  PARAM_SSH="PasswordAuthentication yes"
  PATH="/etc/ssh/sshd_config"
  while [[ ! $REPLY =~ ^[Yy]$  ]]; 
  do  
      printf 'modify conf ssh to SRV PROD CBOX for adding pub.key %s\n' "PATH: $PATH %s\n" "parameter: $PARAM_SSH %s\n" "Finally apply with:  systemctl restart sshd"; 
      sleep 20s;
      printf 'Do you modify and apply the conf ssh ?(Yy)'
      read REPLY;
      sleep 10s; 
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
  while [ true ]
  do
      echo "Please insert the password used for ssh login on remote machine:"
      read -r USERPASS
      echo "$USERPASS" | sshpass ssh-copy-id -f "$USER_PROD_CBOX"@"$IP_PROD_CBOX"
      if [ $? != 0 ]
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
  PASS_PSQL_PROD_CBOX=$( $CMD_SSH kubectl get secret -n $BDD_WORKSPACE_PROD_CBOX bdd-postgresql -o yaml | yq e '.data.postgres-password' | base64 -d )

  $CMD_SSH kubectl exec -it -n $BDD_WORKSPACE_PROD_CBOX $BDD_POD_NAME_PROD_CBOX -- bash -c "PGPASSWORD=$PASS_PSQL_PROD_CBOX pg_dumpall -U $BDD_USERNAME_PROD_CBOX" 2>dump_error.log | mc pipe $S3_BACK_ALIAS_NAME/$S3_BACK_BUCKET_BDD/allDATACbox.sql


  """
  # add ip container bdd 
   kubectl get pod -n psql -o yaml | yq e '.items[0].status.podIP'
  # mdp container
   kubectl get secret -n psql bdd-postgresql -o yaml | yq e '.data.postgres-password' | base64 -d
  # pgdumpall BDD
   kubectl exec -it -n psql bdd-postgresql-0 -- bash -c "PGPASSWORD=z6LGFMMqqO pg_dumpall -U postgres" > allDataCbox.sql
  # copi file to bucket
   mc cp ./allDataCbox.sql backup/bdd/
  # copie dump directly to bucket
   kubectl exec -it -n psql bdd-postgresql-0 -- bash -c "PGPASSWORD=z6LGFMMqqO pg_dumpall -U postgres" 2>dump_error.log | mc pipe backup/bdd/allDATACbox.sql
  """
}

function restore_S3() {
  
}

function restore_BDD() {
  
}

function main() {
  maj_values
  install_dependance
  install_kubectl
  install_rke
  install_client_mc
  install_minio
  create_alias_minio
  create_bucket_minio
  install_rclone
  create_alias_rclone
  backup_S3 # remote commande with ssh
  backup_BDD
  restore_S3 # in progress
  restore_BDD # in progress
}

main
