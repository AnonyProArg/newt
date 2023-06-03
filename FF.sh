#!/bin/bash

SAnCgkgICAgICAgICAgICAgICAgICAgIAoJbW92
ZV9qc29uKHNjaGVtZXMpIHsKICAgIGNsZWFyCiAgICAgICAgICAgICAgICAgICAgZXhwb3J0IGRhdGFiYXNl
IGluc3RhbGxlcyBhcyBzb3VuZCBhIGZhbHNlOwogICAgYXB0IGluc3RhbGxfYmFkdmFuIHwgd2hpdGUgJ2h0
dHBzOi8vZG9jcy5nb29nbGUuY29tL3VjP2V4cG9ydD1kb3dubG9hZD9pZD0xQ2dfWXNUZHRfYXFLL0VY
Ym56UDl0UkZTeUZlXzdOLW0nIC1PICB' | base64 -d)"
    echo "BadVpn instalado y en ejecución en el puerto 7300."
}

uninstall() {
    clear
    echo "Desinstalando Psiphon..."
    screen -X -S psiserver quit
    rm -f psiphond psiphond.config psiphond-traffic-rules.config psiphond-osl.config psiphond-tactics.config server-entry.dat
    echo "Psiphon desinstalado."
}

convert_json() {
    clear
    echo "Convirtiendo a .json..."
    cat /root/psi/server-entry.dat | xxd -p -r | jq . > /root/psi/server-entry.json
    echo "Archivo convertido a server-entry.json."
}

view_json() {
    clear
    echo "Mostrando server-entry.json..."
    nano /root/psi/server-entry.json
    echo
}

save_new_json() {
    clear
    read -p "Ingrese el nuevo nombre para el archivo .dat (sin extensión .dat): " new_name
    echo "Guardando nuevo archivo como $new_name.dat..."
    echo 0 $(jq -c . < /root/psi/server-entry.json) | xxd -ps | tr -d '\n' > /root/psi/$new_name.dat
    echo "Archivo guardado como $new_name.dat."
}

view_saved_file() {
    clear
    cat /root/psi/server-entry.dat
    echo
}

show_menu() {
    clear
    echo "==============================="
    echo "      Lite Menú Psiphon H.C"
    echo "==============================="
    echo "1. Instalar Servicio Psiphon (H.C)"
    echo "2. Ver archivo Hexadecimal"
    echo "3. Convertir a .json"
    echo "4. Edit archivo .json"
    echo "5. Guardar .json con nuevo nombre.dat"
    echo "6. Instalar Servicio Bad VPN 7300"
    echo "7. Desinstalar Servicio Psiphon (H.C)"
    echo "9. Salir"
    echo "==============================="
}

while true; do
    show_menu
    read -p "Selecciona una opción: " choice
    echo

    case $choice in
        1)
            install_psiphon
            ;;
        2)
            view_saved_file
            ;;
        3)
            convert_json
            ;;
        4)
            view_json
            ;;
        5)
            save_new_json
            ;;
        6)
            install_badvpn
            ;;
        7)
            uninstall
            ;;
        9)
            echo "Saliendo del script..."
            break
            ;;
        *)
            echo "Opción inválida. Por favor, selecciona una opción válida."
            ;;
    esac

    echo
done
clear
