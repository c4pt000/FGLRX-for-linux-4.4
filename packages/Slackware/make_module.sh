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

# Compila il modulo per il kernel
function _make_module()
{
    local MODULE_DIR=lib/modules/fglrx/build_mod

    cd ${ROOT_DIR}

    # 1)
    # Compilo il modulo del kernel

    # 1.1) Copy arch-depend files
    cp arch/${ARCH}/${MODULE_DIR}/* common/${MODULE_DIR}

    cd common/${MODULE_DIR}

    # 1.2) Se ci sono, applico le patch
    if _check_external_resource 'x' '_files' ${ROOT_DIR}/${SCRIPT_DIR}/patch_functions.sh; then
	source ${ROOT_DIR}/${SCRIPT_DIR}/patch_functions.sh
	_module_patch
    fi

    # 1.3) Make modules with ati's script
    if ! sh make.sh; then
	_print '' '' "`gettext "ERROR: I didn't make module"`"
	return 1
    fi

    # 2)
    # Copio il modulo
    mkdir -p ${WORKING_DIRECTORY}/lib/modules/${KNL_RELEASE}/external
    cat ../fglrx*.ko | gzip -c >> ${WORKING_DIRECTORY}/lib/modules/${KNL_RELEASE}/external/${ATI_DRIVER_NAME}.ko.gz

    return 0
}