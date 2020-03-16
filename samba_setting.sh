#!/bin/sh
# centos7にsambaをインストールするスクリプト

yum install samba samba-common -y

# 設定
user=13na
smbpass='hogehogehooooo'
dir='/home/share'

# ユーザー登録
useradd -M $user

# sambaにユーザー登録
echo -e "$smbpass\n$smbpass" | pdbedit -a -t -u $user
echo '-----------------------------'
echo 'sambaユーザーを登録しました'
echo '-----------------------------'

# 共有場所とpermission
mkdir -m 777 $dir
chown nobody:nobody $dir
echo '-----------------------------'
echo '共有ディレクトリを作成しました'
echo '-----------------------------'

# 自動起動登録
chkconfig smb on
chkconfig nmb on
echo '-----------------------------'
echo 'smbとnmbを自動起動に設定しました'
echo '-----------------------------'

# firewall貫通
firewall-cmd --add-service=samba --zone=public --permanent
firewall-cmd --reload
echo '-----------------------------'
echo 'firewalldにsambaを通しました'
echo '-----------------------------'

# smb.confをインポート
cd /etc/samba
mv smb.conf smb.conf.bak
wget https://www.dropbox.com/s/emskzpkxxmx8fwn/smb.conf?dl=0 -O smb.conf

# smb.confのテスト
testparm -s

# 起動
service smb start
service nmb start

# status確認
systemctl status smb nmb

echo '-----------------------------'
echo '設定完了!'
echo '-----------------------------'
