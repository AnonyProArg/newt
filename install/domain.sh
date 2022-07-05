#!/bin/bash

todo=$(curl -s admrufu.online:81/script.json|jq '.cloudflare')
token=$(echo "$todo"|jq -r '.token')
zonas1=($(echo "$todo"|jq -r '.zonas[]'))

ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
ip_vps=$([[ -n "$public_ip" ]] && echo "$public_ip" || echo "$ip")

verific(){
	title 'GENERADOR DE SUB-DOMINO CLOUDFLARE'
	print_center -ama 'verificando disponibilidad...'

	nu=0
	for chk in "${zonas1[@]}"; do
		name=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${chk}" \
				-H "Authorization: Bearer ${token}" \
				-H "Content-Type: application/json"|jq -r '.result.name')

		if [[ $(echo "$name"|grep 'null') ]]; then
			continue
		fi
		zonas[$nu]="$chk"

		dns[$nu]=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${chk}/dns_records?per_page=100" \
				-H "Authorization: Bearer ${token}" \
				-H "Content-Type: application/json"|jq '.')

		if [[ $(echo "${dns[$nu]}"|jq -r '.result[].content'|grep -w "$ip_vps") ]]; then
			bucle=$(echo "${dns[$nu]}"|jq -r '.result_info.count')
			for (( i = 0; i < $bucle; i++ )); do
				if [[ $(echo "${dns[$nu]}"|jq -r ".result[$i].content"|grep -w "$ip_vps") ]]; then
					domain_vps=$(echo "${dns[$nu]}"|jq -r ".result[$i].name")
					break
				fi
			done

			for (( i = 0; i < $bucle; i++ )); do
				if [[ $(echo "${dns[$nu]}"|jq -r ".result[$i].content"|grep -w "$domain_vps") ]]; then
					domain_vps_NS=$(echo "${dns[$nu]}"|jq -r ".result[$i].name")
					break
				fi
			done
			break
		fi

		status=$(echo "${dns[$nu]}"|jq -r '.result_info.count')
		status=$((100 - $status))
		inf_dns[$nu]="$name $status"
		let nu++
	done
}

domain_ls(){
	del 1
	if [[ -z "${zonas[0]}" ]]; then
		print_center -verm2 "funcion no disponible"
		enter
	elif [[ -z $domain_vps ]]; then
		msg -azu "$(printf '%-8s%-22s' "  N°" "Dominio" "Disponible")"
		msg -bar3
		u=0
		for i in "${inf_dns[@]}"; do
			let u++
			extencion=$(printf '%-25s' "$(echo "$i"|awk '{print $1}')")
			disponible=$(echo "$i"|awk '{print $2}')
			echo " $(msg -verd "[$u]") $(msg -verm2 '>') $(msg -azu "$extencion")$(msg -verd "$disponible")"
		done
		back
		opcion=$(selection_fun $u)
		if [[ $opcion = 0 ]]; then
			return
		else
			let opcion--
		fi
		zona_dns=${zonas[$opcion]}
		domain=$(echo "${inf_dns[$opcion]}"|awk '{print $1}')
		dnss=${dns[$opcion]}
	else
		print_center -ama 'Existe un sub-dominio apuntando a esta ip'
		echo
		echo " $(msg -ama ' IP')  $(msg -verd "$ip_vps")"
		echo " $(msg -ama ' A')   $(msg -verd "$domain_vps")"; echo "$domain_vps" > ${ADM_src}/dominio.txt
		[[ ! -z $domain_vps_NS ]] && echo " $(msg -ama ' NS')  $(msg -verd "$domain_vps_NS")"; echo "$domain_vps_NS" > ${ADM_src}/dominio_NS.txt
		echo
		enter
	fi
}

make_domain(){
	del $((5 + $u))
	while true; do
		print_center -ama 'Escribe un nombre corto'
		in_opcion_down 'Ej: rufuVPS'
		mydomi=$(echo "$opcion" | tr -d '[[:space:]]')

		if [[ -z $mydomi ]]; then
    		print_center -verm2 "ingresar un nombre...!"
    		sleep 2
   			del 4
   			continue
    	elif [[ ! $mydomi =~ $txt_num ]]; then
    		print_center -verm2 "ingresa solo letras y numeros...!"
    		sleep 2
   			del 4
   			continue
    	elif [[ "${#mydomi}" -lt "4" ]]; then
    		print_center -verm2 "nombre demaciado corto!"
    		sleep 2
    		del 4
   			continue
    	fi

		del 3
		msg -nama " $(printf '%-15s' 'Dominio  A >')" && msg -verd "$mydomi.$domain"
		msg -nama " $(printf '%-15s' 'Dominio NS >')" && msg -verd "$mydomi-ns.$domain"
		msg -bar3
		menu_func 'verificar' 'correjir'
		back
		opcion=$(selection_fun 2)
		case $opcion in
			1)  del 5
				if [[ $(echo "$dnss"|jq -r '.result[].name'|grep "$mydomi.$domain") ]]; then
	    			echo " $(msg -verm2 "[fail]") $(msg -azu "sub-dominio NO disponible")"
    				sleep 2
    				del 4
    			else
    				echo " $(msg -verd "[ok]") $(msg -azu "sub-dominio disponible")"
    				enter
    				break
    			fi;;
			2)del 8 && continue;;
			0)return;;
		esac
	done
	del 4
	print_center -ama 'Creando Sub-Dominio...'


var_A=$(cat <<EOF
{
  "type": "A",
  "name": "$mydomi",
  "content": "$ip_vps",
  "ttl": 1,
  "priority": 10,
  "proxied": false
}
EOF
)

var_NS=$(cat <<EOF
{
  "type": "NS",
  "name": "$mydomi-ns",
  "content": "$mydomi.$domain",
  "ttl": 1,
  "priority": 10,
  "proxied": false
}
EOF
)

	domain_A=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zona_dns/dns_records" \
    	-H "Authorization: Bearer ${token}" \
    	-H "Content-Type: application/json" \
    	-d $(echo $var_A|jq -c '.'))

    sleep 1
    if [[ $(echo "$domain_A"|jq -r '.success'|grep 'true') ]]; then
    	print_center -verd "Sub-dominio tipo A creado con exito!"
    	echo "$(echo "$domain_A"|jq -r '.result.name')" > ${ADM_src}/dominio.txt

    	domain_NS=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zona_dns/dns_records" \
    		-H "Authorization: Bearer ${token}" \
    		-H "Content-Type: application/json" \
    		-d $(echo $var_NS|jq -c '.'))

    	if [[ $(echo "$domain_NS"|jq -r '.success'|grep 'true') ]]; then
    		print_center -verd "Sub-dominio tipo NS creado con exito!"
    		echo "$(echo "$domain_NS"|jq -r '.result.name')" > ${ADM_src}/dominio_NS.txt
    	else
    		echo "" > ${ADM_src}/dominio_NS.txt
    		print_center -ama "Falla al crear Sub-dominio NS!" 

    	fi	
    else
    	echo > ${ADM_src}/dominio.txt
    	echo > ${ADM_src}/dominio_NS.txt
    	print_center -ama "Falla al crear Sub-dominio A!\npor lo tanto no se creo el NS" 	
    fi
    enter
}

init_make(){
	verific
	domain_ls
	[[ -z "$zona_dns" ]] && return
	make_domain
}