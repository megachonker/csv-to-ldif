#!/bin/bash
FLDIF=CANNER.ldif 
USRF=usr.csv
GRPF=grp.csv
FIRSTDC=dc=example,dc=com
HOMEMNT=/srv/homes
rm -f $FLDIF 

grp(){
        
    for group in $(tail -n +2 $1 | cut -d";" -f2|uniq)
    do
create_dir /srv/share $group
cat <<EOF >> $FLDIF
dn: cn=$group,ou=Group,$FIRSTDC
cn: $group
objectclass: posixGroup
objectclass: top
gidnumber: $(uid $group)
$(grep $group grp.csv |cut -d";" -f 1|sed 's/^/memberuid: /')

EOF
    done
    for  line in $(tail -n  +2 $1)
    do
        ID=$(echo $line|cut -d";" -f1)
cat <<EOF >> $FLDIF
dn: cn=$ID,ou=Group,$FIRSTDC
cn: $ID
objectclass: posixGroup
objectclass: top
gidnumber: $(uid $ID)

EOF
    done
}

usr(){
    while read line
    do
        NA=$(echo $line|cut -d";" -f1)
        SU=$(echo $line|cut -d";" -f2)
        LOG=$(echo $line|cut -d";" -f3)
        PASS=$(echo $line|cut -d";" -f4)
        ldifusr $NA $SU $LOG $PASS 

        create_dir $HOMEMNT $LOG
    done < $1
}

create_dir(){
ID=$(uid $2)
mkdir "$1/$2"
chmod 770 $1/$2
chown $ID:$ID "$1/$2"
}

uid(){
    echo $(($(sha512sum  --binary  <(echo $1) | grep [1-9] -o|tr --delet '\n'|grep ^.... -o)+1000))
}

ldifusr(){
cat <<EOF >> $FLDIF
dn: uid=$3,ou=People,$FIRSTDC
objectclass: top
objectclass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
objectclass: posixAccount
objectclass: shadowAccount
cn: $1 $2
sn: $2
uid: $3
givenName: $1
userpassword: $(slappasswd -s $4)
loginshell: /bin/bash
gidnumber: $(uid $3)
uidnumber: $(uid $3)
homeDirectory: /home/$3

EOF
}

ldifgrp(){
cat <<EOF >> $FLDIF
dn: cn=$1,ou=Group,$FIRSTDC
cn: $1
objectclass: posixGroup
objectclass: top
gidnumber: $(uid $1)

EOF

cat <<EOF >> $FLDIF

dn: cn=$2,ou=Group,$FIRSTDC
cn: $2
objectclass: posixGroup
objectclass: top
gidnumber: $(uid $2)

EOF
}



grp $GRPF 
usr $USRF

cat $FLDIF

# RETARD ldapdelete -r -v -x -H ldap://127.0.0.1 -D cn=admin,dc=example,dc=com -w secret1234 "ou=People,dc=example,dc=com" "ou=Group,dc=example,dc=com"
