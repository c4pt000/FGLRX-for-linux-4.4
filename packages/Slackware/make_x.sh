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

# Sposta i file necessari al server X.
function _make_x()
{
    cd ${ROOT_DIR}

    # setta X_VERSION e X_LAYOUT
    ! _check_external_resource 'x' '_files' './check.sh' && return 1

    source ./check.sh --noprint

    if [ -z $X_VERSION ]; then
	_print '1;31' '' "`gettext "ERROR: your X server isn't supported"`"
	return 1
    fi

    cd ${WORKING_DIRECTORY} || return 1

    mkdir usr

    # 1)
    # MOVE ARCH DIPENDENT FILES

    # 1.1)
    # Se l'architettura è a 64 bit, allora sposto, se necessario,
    # anche la directory "${ROOT_DIR}/arch/x86/usr/lib" con le librerie
    # a 32 bit.
    # Ci sono due filosofie sulla posizione delle librerie a 32 bit in
    # una distribuzione Slackware-based:
    # 1) Le librerie a 64 bit vanno sotto /usr/lib64, mentre quelle a 32 bit
    #    vanno sotto /usr/lib (Slamd64 e Slackware64)
    # 2) Le librerie a 64 bit vanno sotto /usr/lib ed esiste un link
    #    /usr/lib64 che punta a /usr/lib, mentre le librerie a 32 bit vanno sotto
    #    /usr/lib32 (Bluewhite64)
   if [ ${ARCH} = "x86_64" ]; then
	if [ ! -h /usr/lib64 ]; then # Se /usr/lib64 non è un link, allora Slamd64 o Slackware64
	    if [ -h /lib/ld-linux* ]; then # Se sono presenti già librerie a 32 bit
		cp -r ${ROOT_DIR}/arch/x86/usr/* usr
	    fi
	else # /usr/lib64 è un link simbolico, quindi Bluewhite64
	    if [ -h /lib32/ld-linux* ]; then # Se sono presenti già librerie a 32 bit
		cp -r ${ROOT_DIR}/arch/x86/usr/* usr
		for dir in $(find usr -type d -name "*lib") # Rinomino lib in lib32
		do
		    mv $dir ${dir}32
    		done
    	    fi
    	fi
    fi

    # 1.2)
    # Copio i file relativi all'architettura. Nel caso di un architettura x86_64 mista con
    # librerie a 32 bit, questa operazione sovrascrive i binari a 32 bit con quelli a 64 bit
    cp -r ${ROOT_DIR}/arch/${ARCH}/usr/* usr

    # 2)
    # MOVE ARCH INDIPENDENT FILES
    cp -r ${ROOT_DIR}/common/usr/* usr

    mkdir -p etc/ati
    cp ${ROOT_DIR}/common/etc/ati/* etc/ati

    # 3)
    # MOVE X_VERSION DEPENDENT FILES
    cp -r ${ROOT_DIR}/${X_VERSION}/usr/* usr

    # 4)
    # AGGIUSTO I PERMESSI
    # 4.1) Per il momento setto a tutti i file il permesso di esecuzione
    chmod -R a+x usr/

    # 4.2) Nella directory usr, tolgo i diritti di esecuzione a tutti i file che non siano:
    #      - directory
    #      - binari
    #      - librerie (a meno che non siano .a, a questi tolgo il permesso di esecuzion)
    ( cd usr
	find . -not -type d -and -not -wholename "*/bin/*" -and -not -wholename "*/sbin/*" \
	    -and -not \( -wholename "*/lib*" -and -not -name "*.a" \) | xargs chmod -x
    )

    # 4.3) I file in usr/sbin devono avere il permesso di esecuzione solo per il root
    chmod 0744 usr/sbin/*

    # 4.4) Assicuro i giusti permessi ai binari in usr/X11R6/bin
    chmod a+x usr/X11R6/bin/*

    # 4.5) Aggiusto i permessi ai file in etc/ati
    chmod a-x etc/ati/*
    chmod u+x etc/ati/*.sh 2>/dev/null

    # 5)
    # RENDO L'ALBERO CONFORME ALLA SLACKWARE
    # 5.1)
    # Alcuni dei file in etc/ati devono essere spostati come .new in modo da preservarli con la rimozione del
    # pacchetto. Sarà poi lo script doinst.sh a rinominarli o cancellarli.
    ( cd etc/ati
	for file in atiogl.xml authatieventsd.sh; do
	    [ -f $file ] && mv $file ${file}.new
	done
    )

    # 5.2)
    # Con il server X modulare i moduli vanno sotto /usr/lib(64)/xorg/modules e non più sotto /usr/X11R6/lib(64)/modules
    # L'unico caso in cui ciò non accade è con la Slackware 11 dove il server è alla versione 6.9, monolitica.
    if [ $X_LAYOUT = "modular" ]; then
	for dir in $(find usr -type d -name "lib*");
	do
	    if [ -d ${dir}/modules ]; then # Controllo che la directory sia una di quelle che contiene i moduli
		mkdir ${dir}/xorg
		mv ${dir}/modules ${dir}/xorg
	    fi
	done

	cp -a usr/X11R6/* usr/
	rm -r usr/X11R6
    fi

    # 5.3)
    # Sposto, se esiste, la directory usr/share/man in usr e comprimo le pagine di manuale, se esistono
    if [ -d usr/share/man ]; then
	mv usr/share/man usr
	for file in usr/man/*/*; do
            gzip $file
	done
    fi

    # 5.4)
    # Sposto, se esistono, tutti i file .desktop della directory usr/share/gnome in usr/share/applications
    # e poi cancello la directory
    if [ -d usr/share/gnome ]; then
	mkdir -p usr/share/applications
	find usr/share/gnome -name '*desktop' -exec mv '{}' usr/share/applications
	rm -r usr/share/gnome
    fi

    # 6)
    # CREO QUALCHE LINK SIMBOLICO
    # 6.1) Librerie particolari
    # Queste librerie potrebbero essere già presenti nel sistema e vanno trattate con l'ausilio dello script doinst.sh e dello script
    # amd-uninstall.sh. Tutte queste librerie si trovano nelle rispettive directory '*/lib*/fglrx/' ma bisogna fare un link simbolico
    # verso di esse nella directory superiore. E' proprio questo link che crea problemi.
    # - In questo passo si crea un link verso queste librerie, poi 'makepkg' accoderà la creazione del link nel doinst.sh.
    # - Il doinst.sh provvederà a fare un backup delle librerie originali e le sostituira con i link creati qui.
    # - Infine, lo script amd-uninstall.sh ripristinirà le librerie originali.
    for dir in $(find usr -type d -wholename "*/lib*/fglrx")
    do
    	( cd $dir
    	    for file in fglrx-*
    	    do
		[ $file = 'fglrx-*' ] && break
    		[ ! -f $file ] && continue
    		ln -sf fglrx/${file} ../${file#*-}
    	    done
    	)
    done

    # 6.2) Creo dei link simbolici alle librerie del tipo libname.so.X.Y
    #      Se non li creo io, li crea 'ldconfig' eseguito da 'installpkg' e 'removepkg' non li elimina
    for file in $(find usr/ -not -wholename "*/fglrx/*" -wholename "*/lib*/*" -name "*.so.*.*")
    do
	( cd ${file%/*}
	    file=${file##*/}
	    ln -s $file ${file%.*}
	    ln -s ${file%.*} ${file%%.*}.so
	)
    done

    return 0
}