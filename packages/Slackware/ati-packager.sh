#!/bin/bash

# Copyright (c) 2009-2011 Emanuele Tomasi

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Inizializzazione: esegue alcuni controlli di base e imposta delle variabili
# d'ambiente utitli per le altre funzioni.
# In caso di errore esce con il valore ${ATI_INSTALLER_ERR_PREP}
function _init_env()
{
    # Mi assicuro che tutti i comandi interni alla bash necessari, siano abilitati
    enable cd echo exit export local return set source test

    # Controllo l'esistenza dei comandi esterni essenziali
    # (eseguiti in questa funzione)!
    local ESSENTIAL_PGR=0
    for pgr in gettext grep uname
    do
	if ! $pgr --version &> /dev/null; then
	    _print '1;31' '' "$pgr: command not found!"
	    ESSENTIAL_PGR=1
	fi

	if [ $ESSENTIAL_PGR -eq 1 ]; then
	    exit ${ATI_INSTALLER_ERR_PREP}
	fi
    done

    # Controllo l'esistenza di alcuni comandi utili ma non necessari
    which -V &> /dev/null && USE_WHICH=1 || USE_WHICH=0
    tput -V &> /dev/null && USE_TPUT=1 || USE_TPUT=0

    # ROOT_DIR = directory attuale
    ROOT_DIR=$PWD

    # Directory, relativa a ROOT_DIR, in cui si trova questo script.
    # Si ricordi che quando l'ati-installer.sh esegue questo script la root directory
    # è ROOT_DIR
    SCRIPT_DIR=packages/Slackware

    # Settaggi per gettext
    export TEXTDOMAIN=ATI_SlackBuild
    export TEXTDOMAINDIR=${ROOT_DIR}/${SCRIPT_DIR}/locale

    echo "$ROOT_DIR" | grep -q ' ' && _print '' '' "`gettext "The name of the current directory mustn't contain any spaces"`" && exit ${ATI_INSTALLER_ERR_PREP}

    # Architettura, può essere 'x86' o 'x86_64'
    ARCH=$(uname -m)
    [[ $ARCH != x86_64 ]] && ARCH='x86'

    # Release del kernel in uso
    KNL_RELEASE=$(uname -r)

    # Info sui driver
    ! _check_external_resource 'x' '_files' './ati-packager-helper.sh' && exit ${ATI_INSTALLER_ERR_PREP}
    ATI_DRIVER_NAME=fglrx
    ATI_DRIVER_VER=$(./ati-packager-helper.sh --version)
    ATI_DRIVER_REL=$(./ati-packager-helper.sh --release)

    # Directory in cui verrà spostato il pacchetto creato
    DEST_DIR=${PWD%/*}

    # Nome del pacchetto che verrà creato
    PKG_NAME=${ATI_DRIVER_NAME}-${ATI_DRIVER_VER}-${ARCH}-${ATI_DRIVER_REL}.tgz
}

# Controlla l'esistenza di file o comandi esterni
# $1 può essere:
#   'x': stampa a video solo il nome dei file o comando non trovato.
#   'x--dryrun': stampa a video il nome del file o comando che sta controllando
#                e se lo trova.
# $2 può essere:
#   '_commands': per controllare l'esistenza di comandi.
#   '_files': per controllare l'esistenza di file.
# $3,$4,...,$n: i file o i comandi da controllare.
function _check_external_resource()
{
    local DRYRUN=0
    [ $1 = 'x--dryrun' ] && DRYRUN=1

    local CHECK_FOR=''
    case $2 in
	_commands)
	    CHECK_FOR='command'
	    ;;
	_files)
	    CHECK_FOR='file'
	    ;;
    esac
    shift 2

    local DEPS_OK=0
    for WHAT in $*
    do
	if [ $DRYRUN -eq 1 ]; then
	    _print '' 'n' "`gettext 'Check for '`"
	    echo -n "${CHECK_FOR}: ${WHAT}"
	    [ $USE_TPUT -eq 1 ] && tput hpa 45
	    echo -n '   [ '
	fi

	if [ $CHECK_FOR = 'command' ]; then
	    if [ $USE_WHICH -eq 1 ]; then
		which ${WHAT} &> /dev/null
	    else
		grep "bin/${WHAT}\$" ${DIR_PACKAGE}/* &> /dev/null
	    fi
	else
	    [ -f ${WHAT} ] > /dev/null
	fi

	if [ $? != 0 ]; then
	    if [ $DRYRUN -eq 1 ]; then
		_print '1;31' 'n' "`gettext 'NOT FOUND'`"
	    else
		if [ $CHECK_FOR = 'command' ]; then
		    _print '1;31' 'n' "`gettext 'You must install command:'`"
		    _print '1;31' '' " ${WHAT}"
		else
		    _print '1;31' 'n' "${WHAT}: "
		    _print '1;31' '' "`gettext 'file not found, internal error. Please contact the maintaners.'`"
		fi
	    fi
	    DEPS_OK=1
	elif [ $DRYRUN -eq 1 ]; then
	    _print '1;32' 'n' "`gettext 'OK'`"
	fi

	[ $DRYRUN -eq 1 ] && echo ' ]'
    done
    unset WATH

    return $DEPS_OK
}

# Controlla che l'utente sia root
function _check_if_root()
{
    if [ $(id -u) -gt 0 ]; then
	_print '' '' "`gettext 'Only root can do it!'`"
	exit 1
    fi
}

# Stampa a video i parametri $[2-*]
# $1 può essere una stringa nulla ('') oppure un colore nella forma ?;??.
#    Per il colore si veda uno dei seguenti valori:
#
#    Nero           0;30     Grigio Scuro  1;30
#    Blu            0;34     Blu Chiaro    1;34
#    Verde          0;32     Verde Chiaro  1;32
#    Ciano          0;36     Ciano Chiaro  1;36
#    Rosso          0;31     Rosso Chiaro  1;31
#    Viola          0;35     Viola Chiaro  1;35
#    Marrone        0;33     Giallo        1;33
#    Grigio Chiaro  0;37     Bianco        1;37
#
# $2 può essere una stringa nulla ('') oppure il carattere 'n'. Se vale 'n',
#    allora dopo la stampa non va a capo.
function _print()
{
    local color=$1
    local new_line=$2
    shift 2

    if [ -z $color ]
    then
	echo -e${new_line} "${*}"
    else
	echo -e${new_line} "\E[${color}m${*}\E[00m"
    fi

    return 0
}

# Implementa l'opzione --buildpkg dello script
# $1: nome del pacchetto da costruire
# $2 può essere:
# '' : costruisce il pacchetto
# '--dryrun': controlla solo che il parametro $1 sia corretto
#             ritorna 0 se lo è, 1 altrimenti
function _buildpkg()
{
    ! _check_external_resource 'x' '_files' "${SCRIPT_DIR}/make_module.sh ${SCRIPT_DIR}/make_x.sh"\
                                            "${SCRIPT_DIR}/info/slack-desc ${SCRIPT_DIR}/info/doinst.sh"\
                                            "${SCRIPT_DIR}/info/amd-uninstall.sh" && return 1

    local DRYRUN=0
    [ "x$2" != 'x' ] && DRYRUN=1

    case $1 in
	Slackware)
	    [ $DRYRUN -eq 1 ] && return 0

	    local WORKING_DIRECTORY=${ROOT_DIR}/${SCRIPT_DIR}/_working_directory_

	    mkdir ${WORKING_DIRECTORY} || return 1

	    # Compilo il modulo del kernel
	    source ${ROOT_DIR}/${SCRIPT_DIR}/make_module.sh
	    ! _make_module && return 1

	    # Sposto i file per il server X
	    source ${ROOT_DIR}/${SCRIPT_DIR}/make_x.sh
	    ! _make_x && return 1

	    # Creo il pacchetto
	    ###
	    cd ${WORKING_DIRECTORY}

	    # Creo la directory '/install/'
	    mkdir install
	    cp ${ROOT_DIR}/${SCRIPT_DIR}/info/slack-desc install
	    cp ${ROOT_DIR}/${SCRIPT_DIR}/info/doinst.sh install

	    # Copio l'uninstaller e i file per la localizzazione
	    mkdir -p usr/share/ati/ATI_SlackBuild
	    cp ${ROOT_DIR}/${SCRIPT_DIR}/info/amd-uninstall.sh usr/share/ati
	    cp -r ${ROOT_DIR}/${SCRIPT_DIR}/info/locale usr/share/ati/ATI_SlackBuild 2> /dev/null

	    # Setto la variabile PKG_NAME nell'amd-uninstall.sh
	    sed -i "/PKG_NAME=/s/=.*/=${PKG_NAME%.*}/" usr/share/ati/amd-uninstall.sh

            # Strip binaries and libraries
	    find . | xargs file | sed -n "/ELF.*executable/b PRINT;/ELF.*shared object/b PRINT;d;:PRINT s/\(.*\):.*/\1/;p;"\
                   | xargs strip --strip-unneeded 2> /dev/null

	    # Mi assicuro che il proprietario sia root
	    chown root.root -R *

	    # Creo il pacchetto
	    makepkg -l y -c n ${DEST_DIR}/${PKG_NAME}
	    ;;
	*)
            # Il formato di questa stringa è definito nel file README.distro (non la traduco)
	    echo -n "$1: unsupported option passed by ati-installer.sh"
            return 1
	    ;;
    esac

    return 0
}

# Implemente l'opzione --installpkg dello script
function _installpkg()
{
    _print '1;32' '' "`gettext 'Install/Upgrade package'`"

    # Se c'è l'uninstaller, lo uso per rimuovere il vecchio pacchetto
    if [ -f /usr/share/ati/amd-uninstall.sh ]; then
	/usr/share/ati/amd-uninstall.sh
    fi

    # Installo il pacchetto
    installpkg ${DEST_DIR}/${PKG_NAME}

    return 0
}

# Directory che contiene l'elenco dei pacchetti installati nelle distribuzioni
# basate su Slackware
DIR_PACKAGE=/var/log/packages

# L'elenco dei maintaners dell'ATI SlackBuild (è una lista separata da ';')
MAINTAINERS='Emanuele Tomasi <tomasi@cli.di.unipi.it>'

# Per queste opzioni, non c'è bisogno dell'inizializzazione
case $1 in
    # Stampa l'elenco dei nomi di pacchetto che è possibile costruire (lista separata da '\t)
    --get-supported)
	echo -e 'Slackware'
	exit 0
	;;

    # Ritorna:
    # ${ATI_INSTALLER_ERR_VERS}: se la distribuzione su cui si sta tentando di eseguire lo script
    #                            non è basata su Slackware
    # 0: Se la distribuzione su cui si sta tentando di eseguire lo script è basata su Slackware
    #    e se il pacchetto che si vuole creare è 'Slackware'.
    --identify)
	[ $2 != 'Slackware' ] && exit ${ATI_INSTALLER_ERR_VERS}

	[ ! -d ${DIR_PACKAGE} ] && exit ${ATI_INSTALLER_ERR_VERS}

	exit 0
	;;

    # Questo script onora le API versione 2 dell'ati-installer.sh
    --getAPIVersion)
	exit 2
	;;

    # Lista dei maintainer (separata da ';')
    --get-maintainer)
	echo ${MAINTAINERS}
	exit 0
	;;
esac

_init_env
case $1 in
    # Controllo che tutto il necessario alla costruzione del pacchetto sia correttamente installato
    --buildprep)
	echo -en "\nATI SlackBuild"\
                "\n--------------------------------------------"\
                "\nby: "
	echo -e ${MAINTAINERS//;/\\n} "\n"

	EXIT_STATUS=0

	# Controllo che $3 sia un blank oppure --dryrun
	if [ "x${3}" != 'x' ] && [ "x${3}" != 'x--dryrun' ]; then
	    _print '1;31' 'n' "`gettext 'Not a valid parameter: '`"
	    _print '1;31' '' "$3"
	    EXIT_STATUS=${ATI_INSTALLER_ERR_PREP}
	fi

	# Controllo l'esistenza dei comandi esterni necessari alla costruzione del pacchetto
        ! _check_external_resource "x${3}" '_commands'\
            'chmod cp file find gzip id ln makepkg mkdir mv rm sed sh strip tar xargs'\
            && EXIT_STATUS=${ATI_INSTALLER_ERR_PREP}

	# Controllo che il parametro $2 sia un nome di pacchetto da costruire, valido
	! _buildpkg $2 '--dryrun' && EXIT_STATUS=${ATI_INSTALLER_ERR_PREP}

	exit $EXIT_STATUS
	;;
    # Creo il pacchetto
    --buildpkg)
	_check_if_root
	_buildpkg $2
	exit $?
	;;

    # Controllo che tutto il necessario alla corretta installazione del pacchetto sia correttamente installato
    --installprep)
	EXIT_STATUS=0

	# Controllo l'esistenza dei comandi esterni necessari all'installazione del pacchetto
	! _check_external_resource "x${3}" '_commands'\
          'basename dirname depmod gettext id installpkg md5sum modprobe ps sed'\
          && EXIT_STATUS=${ATI_INSTALLER_ERR_PREP}

	exit $EXIT_STATUS
	;;

    # Installo il pacchetto creato dall'opzione --buildpk.
    --installpkg)
	_check_if_root
        _installpkg
    	exit $?
    	;;

    *)
	# Il formato di questa stringa è definito nel file README.distro (non la traduco)
	echo -n "$1: unsupported option passed by ati-installer.sh"
	exit 1
	;;
esac