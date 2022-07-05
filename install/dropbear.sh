#!/bin/bash

uninstal_drop(){
  clear
  msg -bar
  print_center -ama '>>>> Desinstalando dropbear <<<<'
  service dropbear stop &>/dev/null 2>&1
  apt remove dropbear dropbear-bin dropbear-initramfs dropbear-run -y &>/dev/null
  apt purge dropbear dropbear-bin dropbear-initramfs dropbear-run -y &>/dev/null
  apt autoremove dropbear-bin dropbear-initramfs dropbear-run -y &>/dev/null
  rm -rf /etc/default/dropbear &>/dev/null
  if crontab -l|grep '@reboot'|grep 'service'|grep 'dropbear' &>/dev/null; then
    crontab -l > /root/cron
    sed -i '/@reboot service dropbear start/d' /root/cron
    crontab /root/cron
    rm /root/cron
  fi
  del 1
  print_center -verd '>>>> Dropbear desinstado <<<<'
  enter
}

instal_drop(){
  title 'INSTALADOR DROPBEAR'
  echo " $(msg -verm2 "Ingrese Sus Puertos:") $(msg -verd "80 90 109 110 143 443")"
  msg -bar
  msg -ne " Digite Puertos: " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do
    [[ $(mportas|grep "${TTOTAL[$i]}") = "" ]] && {
      echo " $(msg -azu 'Puerto Elegido:') $(msg -verd "${TTOTAL[$i]} OK")"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo " $(msg -azu 'Puerto Elegido:') $(msg -verm2 "${TTOTAL[$i]} FAIL")"
    }
  done
  [[  -z $PORT ]] && {
    print_center -verm2 'Ningun Puerto Valida Fue Elegido'
    enter
    return
  }
  msg -bar3
  msg -nazu "        Instalando dropbear$(msg -ama '...........')"
  if apt install dropbear -y &>/dev/null ; then
      msg -verd "INSTALL"
  else
      msg -verm2 "FAIL"
      enter
      return
  fi
  msg -nazu "        Configurando dropbear$(msg -ama '.........')"
  [[ ! $(cat /etc/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> /etc/shells
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  if [ "$(echo "$chk" | grep -v "#Banner" | grep Banner)" != "" ]; then
    local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  else
    local="/etc/bannerssh"
  fi
  touch $local
cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=VAR1
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="$local"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
  n=0
  for i in $(echo $PORT); do
    p[$n]=$i
    let n++
  done
  sed -i "s/VAR1/${p[0]}/g" /etc/default/dropbear
  if [[ ! -z ${p[1]} ]]; then

    for (( i = 0; i < ${#p[@]}; i++ )); do
      [[ "$i" = "0" ]] && continue
      sed -i "s/VAR/-p ${p[$i]} VAR/g" /etc/default/dropbear
    done
  fi
  sed -i "s/VAR//g" /etc/default/dropbear
  service ssh restart > /dev/null 2>&1
  service dropbear restart > /dev/null 2>&1
  for ufww in `echo $PORT`; do
    ufw allow $ufww/tcp > /dev/null 2>&1
  done
  sleep 2
  msg -verd 'INSTALL'
  enter
}

instal_drop_fix(){
  title 'INSTALADOR FIX DROPBEAR'
  print_center -ama 'En este instalador utd vera todo el\nproceso de instalacion dropbear para asi\npoder identificar posibles fallas.\n\nPuede que se requerir alguna accion de su parte\npropia de la instalacion de dropbear.'
  enter
  apt install dropbear -y
  if [[ ! $(dpkg --get-selections|grep -w 'dropbear'|grep -v 'dropbear-'|awk '{print $1}') ]]; then
    msg -bar
    print_center -verm2 'No se instalo dropbear!!!\nse en contraron falla en el proceso'
    enter
    return
  fi
  msg -bar
  print_center -ama 'instalacion dropbear finalizada\nSe procede a relizar la configuracion.'
  enter
  instal_drop
}

mod_port(){
  title 'REDEFINIR PUERTOS DROPBEAR'
  act=$(mportas|grep 'dropbear'|awk '{print $2}'|tr '\n' ' ') && [[ -z $act ]] && act='no hay puertos definidos'
  print_center 'Puertos actuales'
  print_center -verd "$act"
  msg -bar
  msg -ne " Digite Puertos: " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do
    [[ $(mportas|grep -v 'dropbear'|grep "${TTOTAL[$i]}") = "" ]] && {
      echo " $(msg -azu 'Puerto Elegido:') $(msg -verd "${TTOTAL[$i]} OK")"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo " $(msg -azu 'Puerto Elegido:') $(msg -verm2 "${TTOTAL[$i]} FAIL")"
    }
  done
  [[  -z $PORT ]] && {
    print_center -verm2 'Ningun Puerto Valida Fue Elegido'
    enter
    return
  }
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  if [ "$(echo "$chk" | grep -v "#Banner" | grep Banner)" != "" ]; then
    local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  else
    local="/etc/bannerssh"
  fi
  touch $local
  cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=VAR1
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="$local"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
  n=0
  for i in $(echo $PORT); do
    p[$n]=$i
    let n++
  done
  sed -i "s/VAR1/${p[0]}/g" /etc/default/dropbear
  if [[ ! -z ${p[1]} ]]; then

    for (( i = 0; i < ${#p[@]}; i++ )); do
      [[ "$i" = "0" ]] && continue
      sed -i "s/VAR/-p ${p[$i]} VAR/g" /etc/default/dropbear
    done
  fi
  sed -i "s/VAR//g" /etc/default/dropbear
  service ssh restart > /dev/null 2>&1
  service dropbear restart > /dev/null 2>&1
  for ufww in `echo $PORT`; do
    ufw allow $ufww/tcp > /dev/null 2>&1
  done
  msg -bar
  print_center -verd 'PUERTOS REDEFINIDOS'
  enter
}

mod_conf(){
  title 'CONFIGURACION MANUAL DROPBEAR'
  print_center -ama 'Al finalizar las modificaciones\ny si utd cambio algun puerto\npuede que sea necesario conf su firewall\nej: ufw allow 80/tcp'
  enter
  nano /etc/default/dropbear
  service ssh restart > /dev/null 2>&1
  service dropbear restart > /dev/null 2>&1
  tput cuu1 && tput dl1 && tput cuu1 && tput dl1
  print_center -verd 'configuracion finalizada'
  enter
}

fix_boot(){
  unset fix
  title 'FIX EN INICIO DEL SISTEMA'
  print_center -ama 'Si el servicio dropbear no inicia en el\narranque de su sistema aplique este fix!'
  msg -bar
  if crontab -l|grep '@reboot'|grep 'service'|grep 'dropbear' &>/dev/null; then
    print_center -verd 'fix activo'
    msg -bar
    read -rp "$(msg -ama "Remover fix [S/N]:") " -e -i S fix
    del 1
    if [[ $fix = @(S|s) ]]; then
      crontab -l > /root/cron
      sed -i '/@reboot service dropbear start/d' /root/cron
      crontab /root/cron
      rm /root/cron
      del 2
      print_center -ama 'fix removido!' 
      enter
      return
    fi
  else
    read -rp "$(msg -ama "Aplicar fix [S/N]:") " -e -i S fix
    del 1
    if [[ $fix = @(S|s) ]]; then
      crontab -l > /root/cron
      echo '@reboot service dropbear start' >> /root/cron
      crontab /root/cron
      rm /root/cron
      print_center -verd 'fix dropbear en el inicio de sistema aplicado!'
      enter
      return
    fi
  fi
  del 1
  enter
}

restart_service(){
  if service dropbear restart; then
    print_center -verd 'servicio dropbear reiniciado!'
  else
    print_center -verm2 'falla al reinciar servicio dropbear'
  fi
  enter
}

menu_dropbear(){
  [[ $(crontab -l|grep '@reboot'|grep 'service'|grep 'dropbear') ]] && actfix='\e[1m\e[32m[ON]' || actfix='\e[1m\e[31m[OFF]'
  title 'MENU DE INSTALACION DROPBEAR'
  nu=1
  if [[ $(dpkg --get-selections|grep -w 'dropbear'|grep -v 'dropbear-'|awk '{print $1}') ]]; then
    echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR DROPBEAR')" && de="$nu"; in='a'; in2='a'
    msg -bar3
    echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -azu 'REDEFINIR PUERTOS')"
    echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -azu 'CONFIGURACION MANUAL (nano)')"
    echo -e " $(msg -verd '[4]') $(msg -verm2 '>') $(msg -ama 'FIX DE INICIO CON EL SISTEMA') $actfix"
    echo " $(msg -verd '[5]') $(msg -verm2 '>') $(msg -azu 'REINICIAR SERVICIO DROPBEAR')"
    nu=5
  else
    print_center -ama 'Si estas usando debian!!!\nse recomienda usar la opcion 2'
    msg -bar
    echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'INSTALAR DROPBEAR')" && in="$nu"; de='a'
    nu=2
    echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -ama 'INSTALAR DROPBEAR FIX')" && in2="$nu"; de='a'
  fi
  back
  opcion=$(selection_fun $nu)
  case $opcion in
    "$in")instal_drop;;
    "$in2")instal_drop_fix;;
    "$de")uninstal_drop;;
    2)mod_port;;
    3)mod_conf;;
    4)fix_boot;;
    5)restart_service;;
    0)return 1;;
  esac
}

while [[  $? -eq 0 ]]; do
  menu_dropbear
done