#!/bin/sh

# firewalldの削除用スクリプト

# ifconfigコマンドで確認すること!!
IF=enp0s3

# centos7用のfirewall設定

# データを持たないパケットの接続を破棄する
firewall-cmd  --permanent --direct --remove-rule ipv4 filter INPUT 0 -p tcp --tcp-flags ALL NONE -j DROP 
# SYNflood攻撃と思われる接続を破棄する
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -p tcp ! --syn -m state --state NEW -j DROP 
# ステルススキャンと思われる接続を破棄する
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -p tcp --tcp-flags ALL ALL -j DROP  
# ブロードキャストアドレスを破棄する
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -m pkttype --pkt-type broadcast -j DROP
# マルチキャストアドレスを破棄する
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -m pkttype --pkt-type multicast -j DROP 
# IP Spoofing(なりすまし) の対応(外部からやってくるローカルIPは破棄)
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -i $IF -s 127.0.0.1/8 -j DROP
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -i $IF -s 10.0.0.0/8 -j DROP #開発環境では許可
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -i $IF -s 172.16.0.0/12 -j DROP
# firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -i $IF -s 192.168.0.0/16 -j DROP  #開発環境では許可
# firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -i $IF -s 192.168.0.0/24  -j DROP #開発環境では許可
# Ping of Death 攻撃対策（firewall-cmdに修正するのがめんどくなったので割愛。参考サイトを参照してください。）
# Pingに不要なicmpタイプのブロック(echo-request、echo-reply 以外)
firewall-cmd --permanent --remove-icmp-block=destination-unreachable
firewall-cmd --permanent --remove-icmp-block=parameter-problem
firewall-cmd --permanent --remove-icmp-block=redirect
firewall-cmd --permanent --remove-icmp-block=router-advertisement
firewall-cmd --permanent --remove-icmp-block=router-solicitation
firewall-cmd --permanent --remove-icmp-block=source-quench
firewall-cmd --permanent --remove-icmp-block=time-exceeded
# invalid パケットを破棄
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -m state --state INVALID -j DROP
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 0 -m state --state INVALID -j DROP
firewall-cmd --permanent --direct --remove-rule ipv4 filter OUTPUT 0 -m state --state INVALID -j DROP

# Ping Flood攻撃対策（4回以上pingを受信した場合、以降は1秒間に1度だけ許可します。）
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -p icmp --icmp-type 8 -m length --length :85 -m limit --limit 1/s --limit-burst 4 -j ACCEPT
# flooding of RST packets, smurf attack Rejection
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

# Protecting portscans
# Attacking IP will be locked for 24 hours (3600 x 24 = 86400 Seconds)
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -m recent --name portscan --rcheck --seconds 86400 -j DROP
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 0 -m recent --name portscan --rcheck --seconds 86400 -j DROP

# Remove attacking IP after 24 hours
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 -m recent --name portscan --remove
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD  0 -m recent --name portscan --remove

# add service
firewall-cmd --remove-port=10000/tcp --zone=public --permanent # webmin
firewall-cmd --remove-port=20222/tcp --zone=public --permanent # sshd
firewall-cmd --remove-service=http --zone=public --permanent # httpd(80)
firewall-cmd --remove-service=https --zone=public --permanent # httpd(443)

# ポートスキャン対策
firewall-cmd --permanent --direct --remove-chain ipv4 filter port-scan
firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 400 -i $IF -p tcp --tcp-flags SYN,ACK,FIN,RST SYN -j port-scan
firewall-cmd --permanent --direct --remove-rule ipv4 filter port-scan 450 -m limit --limit 1/s --limit-burst 4 -j RETURN
firewall-cmd --permanent --direct --remove-rule ipv4 filter port-scan 451 -j LOG --log-prefix "IPTABLES PORT-SCAN:"
firewall-cmd --permanent --direct --remove-rule ipv4 filter port-scan 452 -j DROP

# ルールに当てはまらない受信を破棄(これで、INPUT、FORWARD両方にDROP)
firewall-cmd --permanent --zone=public --set-target=DROP

# 適用
firewall-cmd --reload
