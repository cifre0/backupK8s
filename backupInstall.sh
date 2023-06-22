######################################## 
### Script deployement Backup Server ###
########################################
# Le fichier d'install doit être dans le meme repertoire que le valuesSrvBackup.yml

###########
### VAR ###
###########
IP_INTERNAL=$( yq e '.srv-backup.SYSTEM.IP_INTERNAL' ./valuesSrvBackup.yml )
DISK_MOUNTED_FOR_MINIO=$( yq e '.srv-backup.SYSTEM.DISK_MOUNTED_FOR_MINIO' ./valuesSrvBackup.yml )
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

##########################
### Install dependance ###
##########################
apt update
apt install -y net-tools moreutils parallel jq
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
####################
### install rke2 ###
####################
# $IP_PUB $IP_INTERNAL $FQDN
mkdir -p /etc/rancher/rke2
curl -so /etc/rancher/rke2/config.yml https://naus-stack.s3.eu-west-3.amazonaws.com/dev/repository/manifests/config.yml
var=$FQDN yq e '.tls-san[0] = env(var)' -i /etc/rancher/rke2/config.yml
var=$IP_INTERNAL yq e '.node-ip = env(var)' -i /etc/rancher/rke2/config.yml
var=$IP_INTERNAL yq e '.advertise-address = env(var)' -i /etc/rancher/rke2/config.yml

curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
if [ $(systemctl is-active rke2-server.service) == "active" ];then echo "Service RKE is run" ; else echo "debug service with journalctl -u rke2-server -f"; exit; fi
### debug service: journalctl -u rke2-server -f

### verifie que le noeud K8s exist
kubectl get nodes 
if [ $_ == 0 ]; then echo "RKE est bien installé"; else tee >> log.txt; exit fi

#############
### MINIO ###
#############
# telecharge le client mc
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/

# telecharger le minio-dev.yaml
mkdir -p /etc/minio
curl -so /etc/minio/installMinio.yml curl https://raw.githubusercontent.com/cifre0/backupK8s/main/minio/install.yml
var=$IP_INTERNAL yq e '.spec.externalIPs[0] = env(var)' -i /etc/minio/installMinio.yml
var=$IP_INTERNAL yq e '.status.ingress = env(var)' -i /etc/minio/installMinio.yml


"""
uninstall minio
kubectl delete -n dev-minio
"""
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

###Creer 2 buckets BDD et S3(objectStorage)
mc mb myminio/bdd

mc mb --with-versioning --with-lock myminio/s3 #versionning, et objectloking
mc retention set --default GOVERNANCE "1d" myminio/s3obj # delais de retention

#############
## rclone ###
#############
# install rclone
mkdir -p /etc/rclone
curl https://rclone.org/install.sh | bash

# rclone cmd
rclone config
.config/rclone/rclone.conf
# corp du fichier rclone.conf
### PROD CBOX: $S3_PROD_ALIAS_NAME $S3_PROD_PROVIDER $S3_PROD_ACCESS_KEY $S3_PROD_SECRET_KEY $S3_PROD_ENDPOINT $S3_PROD_ACL $S3_PROD_BUCKET_NAME
### BACKUP: $S3_BACK_ALIAS_NAME $S3_BACK_PROVIDER $S3_BACK_ACCESS_KEY $S3_BACK_SECRET_KEY $S3_BACK_REGION $S3_BACK_ACL $S3_BACK_ENDPOINT $S3_BACK_PORT_ENDPOINT $S3_BACK_BUCKET_NAME_OBJ

### create alias PROD and BACKUP
rclone config create $S3_PROD_ALIAS_NAME s3 provider=$S3_PROD_PROVIDER access_key_id=$S3_PROD_ACCESS_KEY secret_access_key=$S3_PROD_SECRET_KEY endpoint=http://$S3_PROD_ENDPOINT:$S3_PROD_PORT_ENDPOINT acl=$S3_PROD_ACL
rclone config create $S3_BACK_ALIAS_NAME s3 provider=$S3_BACK_PROVIDER access_key_id=$S3_BACK_ACCESS_KEY secret_access_key=$S3_BACK_SECRET_KEY region=$S3_BACK_REGION acl=$S3_BACK_ACL endpoint=http://$S3_BACK_ENDPOINT:$S3_BACK_PORT_ENDPOINT

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
# cmd rclone pour synch
# rclone sync source:path dest:path [flags]
rclone sync -P $S3_PROD_ALIAS_NAME:$S3_PROD_BUCKET_NAME $S3_BACK_ALIAS_NAME:$S3_BACK_BUCKET_NAME_OBJ


