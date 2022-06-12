#!/usr/bin/env bash
# https://mirror.tuna.tsinghua.edu.cn/kernel/v4.x/linux-4.17.11.tar.gz

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LT_KERNEL_PACKAGE="kernel-lt.x86_64"
LT_KERNEL_TOOL_PACKAGE="kernel-lt-tools.x86_64"
ML_KERNEL_PACKAGE="kernel-ml.x86_64"
ML_KERNEL_TOOL_PACKAGE="kernel-ml-tools.x86_64"
OLD_TOOLS="kernel-tools.x86_64"
OLD_TOOLS_LIBS="kernel-tools-libs.x86_64"
ELREPO_FIELNAME="/etc/yum.repos.d/elrepo.repo"
ELREPO_ADDRESS="https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm"


usage() {
    echo "sh $0 [OPTIONS]
            -m [auto|manual] Mode: yum or source code
            -v [lt|ml]  lt: Long time support  ml: Main line
            -r [true|false] Auto reboot
    "
    exit 1
}

install_gpg_rpm() {
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    test -f ${ELREPO_FIELNAME} || yum install ${ELREPO_ADDRESS} -y
    # echo available package
    # lt: long term support
    # mt: mainline
    yum --disablerepo=\* --enablerepo=elrepo-kernel repolist
    echo -e "\033[32mAvailable Package:\033[0m"
    yum --disablerepo=\* --enablerepo=elrepo-kernel list kernel* | egrep --color "${LT_KERNEL_PACKAGE}|${ML_KERNEL_PACKAGE}"
    read -p "Continue? [yes/no]: " is_next

}


latest_lt() {
    yum --disablerepo=\* --enablerepo=elrepo-kernel install  ${LT_KERNEL_PACKAGE}  -y
    yum remove ${OLD_TOOLS_LIBS} ${OLD_TOOLS}  -y
    yum --disablerepo=\* --enablerepo=elrepo-kernel install ${LT_KERNEL_TOOL_PACKAGE}  -y
}

latest_ml() {
    yum --disablerepo=\* --enablerepo=elrepo-kernel install  ${ML_KERNEL_PACKAGE}  -y
    yum remove ${OLD_TOOLS_LIBS} ${OLD_TOOLS}  -y
    yum --disablerepo=\* --enablerepo=elrepo-kernel install ${ML_KERNEL_TOOL_PACKAGE}  -y
}

update_default_kernel() {
    echo -e "\033[32mCurrent kernel insertion order:\033[0m"
    awk -F \' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

    echo -e "\033[32mCurrent kernel boot order:\033[0m"
    grub2-editenv list
    grub2-set-default 0 # new kernel is 0 (default)

    if [[ "${REBOOT_NOW}" == true ]]; then
        reboot_now
    fi

}


check_kernel_version() {
    ckv=$(uname -r|awk -F- '{print $1}')
    ltv=$(yum --disablerepo=\* --enablerepo=elrepo-kernel list kernel* | grep ${LT_KERNEL_PACKAGE} | awk '{print $2}' | awk -F- '{print $1}')
    mlv=$(yum --disablerepo=\* --enablerepo=elrepo-kernel list kernel* | grep ${ML_KERNEL_PACKAGE} | awk '{print $2}' | awk -F- '{print $1}')

    if [[ "${ckv}" == "${ltv}" ]]; then
        echo -e "\033[32mLong time support version currently installed:\033[0m"
        echo -e "\033[32m-------------------------\033[0m"
        echo -e "\033[31mCurrent: ${ckv}\033[0m"
        echo -e "Long time support: ${ltv}"
        echo -e "Main line: ${mlv}"
        echo -e "\033[32m-------------------------\033[0m"
        echo -e "\033[32mYou may want to upgrade mainline version?\033[0m"
        read -p "[yes/no]: " want_upgrade
        [ -z "${want_upgrade}" ] && want_upgrade=yes
        case ${want_upgrade} in
            y|Y|yes|YES)
                latest_ml
                update_default_kernel
                ;;
            n|N|no|NO)
                echo -e "\033[31mAborted! Cancel upgrade.\033[0m"
                exit 1
                ;;
        esac
    elif [[ "${ckv}" == "${mlv}" ]]; then
        echo -e "\033[32mThe current version is the latest.\033[0m"
        echo -e "Main line: ${mlv}" && exit 0
    fi

}


reboot_now() {
    read -p "You may need to reboot [yes/no]: " reboot_now
    case "${reboot_now}" in
        y|yes|YES)
            sleep 3s
            reboot
            ;;
        n|no|NO)
            sleep 3s && echo -e "\033[32mAborted! you may need to run reboot command!\033[0m"
            exit 1
    esac
}


main() {
    # args:
    # -m [auto|manual]
    # -v [lt|ml]
    # -u [default: true | false] auto reboot
    while getopts "m:v:r" opt; do
        case "$opt" in
            m) MODE="${OPTARG}" ;;
            v) VERSION="${OPTARG}" ;;
            r) REBOOT_NOW=true ;;
            *)  usage ;;
        esac
    done

    if [ "$#" -le 1 ]; then
        usage
    fi
    echo -e "\033[32m-------------------------\033[0m"
    echo -e "\033[32mMODE: \033[0m" "${MODE}"
    echo -e "\033[32mVERSION: \033[0m" "${VERSION}"
    echo -e "\033[32mREBOOT: \033[0m" "${REBOOT_NOW}"
    echo -e "\033[32m-------------------------\033[0m"

    install_gpg_rpm
    check_kernel_version
    if [[ "${VERSION}" == ml ]]; then
        latest_ml
    fi
    latest_lt
    update_default_kernel


}


#### __main
if [[ "${BASH_SOURCE[0]}" == "$0" ]];then
    main "$@"
fi
