# Prompt Material MD3 de la terminal WSL2 de referencia.
# Se carga solo en sesiones Bash interactivas.

__estado_git_md3() {
    local rama
    rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1
    [[ $rama == HEAD ]] && rama=$(git rev-parse --short HEAD 2>/dev/null)

    local adelantados=0 atrasados=0
    if git rev-parse --abbrev-ref '@{u}' &>/dev/null; then
        adelantados=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
        atrasados=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
    fi

    # Glifos Nerd Font escritos como bytes UTF-8: algunas herramientas eliminan
    # el área de uso privado y dejaban cadenas vacías. Cloud Shell usa Unicode estándar.
    local icono_preparado=$'\xef\x80\x8c' icono_modificado=$'\xef\x81\x84' icono_sin_seguimiento=$'\xef\x84\xa8'
    local icono_adelantado=$'\xef\x81\xa2' icono_atrasado=$'\xef\x81\xa3'
    if [[ ${TUNNING_PROFILE:-} == cloudshell || -n ${CLOUD_SHELL:-} ]]; then
        icono_preparado='+' icono_modificado='~' icono_sin_seguimiento='?'
        icono_adelantado='↑' icono_atrasado='↓'
    fi

    local estado=''
    git diff --cached --quiet 2>/dev/null || estado+=" ${icono_preparado}"
    git diff --quiet          2>/dev/null || estado+=" ${icono_modificado}"
    git ls-files --others --exclude-standard 2>/dev/null | grep -q . && estado+=" ${icono_sin_seguimiento}"
    (( adelantados  > 0 )) && estado+=" ${icono_adelantado} ${adelantados} "
    (( atrasados > 0 )) && estado+=" ${icono_atrasado} ${atrasados} "

    printf '%s' "${rama}|${estado}"
}

__construir_indicador() {
    local codigo_salida=$?
    local escape=$'\e' inicio_no_imprimible=$'\001' fin_no_imprimible=$'\002'

    __secuencia_color()  { printf '%s' "${inicio_no_imprimible}${escape}[$*m${fin_no_imprimible}"; }
    __color_texto() { printf '%s' "${inicio_no_imprimible}${escape}[38;2;$1;$2;$3m${fin_no_imprimible}"; }
    __color_fondo() { printf '%s' "${inicio_no_imprimible}${escape}[48;2;$1;$2;$3m${fin_no_imprimible}"; }

    local restaurar_color=$(__secuencia_color 0) negrita=$(__secuencia_color 1) tenue=$(__secuencia_color 2)
    local texto_naranja=$(__color_texto 255 109   0) fondo_naranja=$(__color_fondo 255 109   0)
    local texto_gris_oscuro=$(__color_texto  43  41  48) fondo_gris_oscuro=$(__color_fondo  43  41  48)
    local texto_verde_azulado=$(__color_texto   0 137 123) fondo_verde_azulado=$(__color_fondo   0 137 123)
    local texto_relleno=$(__color_texto  73  69  79) texto_oscuro=$(__color_texto  28  27  31)
    local texto_terciario=$(__color_texto 2 188 249) fondo_terciario=$(__color_fondo 2 188 249) texto_blanco=$(__color_texto 255 255 255)
    local texto_amarillo=$(__color_texto 255 215  64) texto_exito=$(__color_texto 105 240 174)
    local texto_error=$(__color_texto 207 102 121)

    # Separadores redondeados U+E0B6/U+E0B4, logo Ubuntu U+F31B y rama U+E0A0.
    local separador_izquierdo=$'\xee\x82\xb6' separador_derecho=$'\xee\x82\xb4'
    local icono_sistema=$'\xef\x8c\x9b ' icono_rama=$'\xee\x82\xa0 '

    local usuario=${USER} equipo=${HOSTNAME%%.*} directorio="${PWD/#$HOME/\~}"
    local entorno_chroot="${debian_chroot:+($debian_chroot) }"
    local etiqueta_directorio='󰉋' etiqueta_reloj='󱑂'
    if [[ ${TUNNING_PROFILE:-} == cloudshell || -n ${CLOUD_SHELL:-} ]]; then
        equipo=CSE
        # Sin Nerd Font en el navegador: medios círculos y emojis estándar.
        etiqueta_directorio='📂'
        etiqueta_reloj='🕒'
        separador_izquierdo='◖' separador_derecho='◗'
        icono_sistema='' icono_rama='🌿 '
    fi

    # Bloque naranja de identidad.
    local izquierda="${texto_naranja}${separador_izquierdo}${restaurar_color}${fondo_naranja}${texto_oscuro}${negrita} ${icono_sistema}${entorno_chroot}${usuario}@${equipo} ${restaurar_color}"

    # Bloque azul cian del directorio, con texto oscuro legible.
    izquierda+="${texto_naranja}${separador_derecho}${restaurar_color} ${texto_terciario}${separador_izquierdo}${restaurar_color}${fondo_terciario}${texto_oscuro}${negrita} ${etiqueta_directorio} ${directorio} ${restaurar_color}"

    # Bloque verde azulado cuando hay un repositorio Git.
    local datos_git; datos_git=$(__estado_git_md3 2>/dev/null) || datos_git=''
    if [[ -n $datos_git ]]; then
        local rama_git="${datos_git%%|*}" estado_git="${datos_git##*|}"
        izquierda+="${texto_terciario}${separador_derecho}${restaurar_color}${texto_verde_azulado}${separador_izquierdo}${restaurar_color}${fondo_verde_azulado}${texto_blanco}${negrita} ${icono_rama}${rama_git} ${restaurar_color}"
        [[ -n $estado_git ]] && izquierda+="${fondo_verde_azulado}${texto_amarillo}${negrita}${estado_git}${restaurar_color}"
        izquierda+="${texto_verde_azulado}${separador_derecho}${restaurar_color}"
    else
        izquierda+="${texto_terciario}${separador_derecho}${restaurar_color}"
    fi

    # Mide las columnas visibles sin las secuencias de color; los emojis ocupan dos.
    local ancho_izquierda; ancho_izquierda=$(printf '%s' "$izquierda" | sed $'s/\001[^\002]*\002//g' | wc -L)

    # Medir también el reloj: el emoji de Cloud Shell ocupa dos columnas.
    local hora; hora=$(date +%H:%M)
    local derecha="${texto_gris_oscuro}${separador_izquierdo}${restaurar_color}${fondo_naranja}${texto_oscuro}${negrita} ${etiqueta_reloj} ${hora} ${restaurar_color}${texto_naranja}${separador_derecho}${restaurar_color}"
    local ancho_derecha; ancho_derecha=$(printf '%s' "$derecha" | sed $'s/\001[^\002]*\002//g' | wc -L)

    # Relleno entre el directorio y el reloj.
    local columnas=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    local ancho_relleno=$(( columnas - ancho_izquierda - ancho_derecha )); (( ancho_relleno < 1 )) && ancho_relleno=1
    local relleno; relleno=$(printf '─%.0s' $(seq 1 "$ancho_relleno"))

    # Segunda línea: verde cuando el comando termina bien y rojo si falla.
    local simbolo_estado; [[ $codigo_salida -eq 0 ]] && simbolo_estado="${texto_exito}❯${restaurar_color}" || simbolo_estado="${texto_error}❯${restaurar_color}"

    local titulo=''
    case $TERM in
        xterm*|rxvt*) titulo="${inicio_no_imprimible}${escape}]0;${usuario}@${equipo}: ${directorio}${escape}\\${fin_no_imprimible}" ;;
    esac

    # Expandir una variable una sola vez conserva la apariencia y evita ejecutar
    # sustituciones de comandos presentes en nombres de directorios o ramas.
    __indicador_tunning_renderizado="${titulo}${izquierda}${texto_relleno}${relleno}${restaurar_color}${derecha}"$'\n'"${texto_naranja}${tenue}╰ ${restaurar_color}${simbolo_estado} "
    PS1='${__indicador_tunning_renderizado}'
}

PROMPT_COMMAND='__construir_indicador'
