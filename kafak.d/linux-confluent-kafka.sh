#/bin/bash

### 프롬포트 색상
ResetCl='\033[0m'       # Text Reset

Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

BOLD='\033[0;1m'          # Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

UWhite='\033[4;37m'       # White

ITALIC='\033[0;3m'          # Bold
IBlack='\033[3;30m'       # Black
IRed='\033[3;31m'         # Red
IGreen='\033[3;32m'       # Green
IYellow='\033[3;33m'      # Yellow
IBlue='\033[3;34m'        # Blue
IPurple='\033[3;35m'      # Purple
ICyan='\033[3;36m'        # Cyan
IWhite='\033[3;37m'       # White

function run_command() {
    local COMMAND=$@
    case ${DEBUG_MODE} in
        "yes" )
            logging "CMD" "${COMMAND}"
            eval "${COMMAND}" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                logging "OK"
                return 0
            else
                logging "FAIL"
                return 1
            fi
        ;;

        "no"  )
            eval "${COMMAND}" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                return 0
            else
                return 1
            fi
        ;;
    esac
}

function logging() {
    local log_time=$(date "+%y%m%d %H:%M:%S.%3N")
    local log_type="$1"
    local log_msg="$2"
    
    # cmd_log="tee -a ${SCRIPT_LOG}/script_${TODAY}.log"
    # printf "%-*s | %s\n" ${STR_LEGNTH} "Server Serial" "Unknown" |tee -a ${LOG_FILE} >/dev/null
    case ${log_type} in
        "CMD"   ) printf "%s | ${BOLD}%-*s${ResetCl} | ${BOLD}%s${ResetCl}\n"    "${log_time}" 7 "${log_type}" "${log_msg}"    ;;
        "OK"    ) printf "%s | ${Green}%-*s${ResetCl} | ${Green}%s${ResetCl}\n"  "${log_time}" 7 "${log_type}" "command ok."   ;;
        "FAIL"  ) printf "%s | ${Red}%-*s${ResetCl} | ${Red}%s${ResetCl}\n"      "${log_time}" 7 "${log_type}" "command fail." ;;
        "INFO"  ) printf "%s | ${Cyan}%-*s${ResetCl} | %s${ResetCl}\n"           "${log_time}" 7 "${log_type}" "${log_msg}"    ;;
        "WARR"  ) printf "%s | ${Red}%-*s${ResetCl} | %s${ResetCl}\n"            "${log_time}" 7 "${log_type}" "${log_msg}"    ;;
        "SKIP"  ) printf "%s | ${Yellow}%-*s${ResetCl} | %s${ResetCl}\n"         "${log_time}" 7 "${log_type}" "${log_msg}"    ;;
        "ERROR" ) printf "%s | ${BRed}%-*s${ResetCl} | %s${ResetCl}\n"           "${log_time}" 7 "${log_type}" "${log_msg}"    ;;
    esac
}

# function set_opts() {
#     arguments=$(getopt --options irh \
#     --longoptions help,kafka-dir:,cluster-ips:,main,sub:,zookeeper,running,verbose \
#     --name $(basename $0) \
#     -- "$@")

#     KAFKA_ACTIVE=1
#     DEBUG_MODE="no"
#     export CLUSTER_IPS=()
#     eval set -- "${arguments}"
#     # while true; do
#     while [[ "$1" != "" ]]; do
#         case "$1" in
#             -h | --help ) help_usage    ;;
#             -i ) MODE="install" ; shift ;;
#             -r ) MODE="remove"  ; shift ;;
#             --kafka-dir   ) export KAFKA_PATH="$2"    ; shift 2 ;;
#             --cluster-ips )
#                 IFS=',' read -r -a CLUSTER_IPS <<< "$2"
#                 #read -r -a CLUSTER_IPS <<< "$2"
#                 shift 2
#             ;;
#             --zookeeper   ) export CLUSTER_MODE="zookeeper" ; shift ;;
#             --main        ) export KRAFT_UUID="main"  ; shift   ;;
#             --sub         ) export KRAFT_UUID="$2"    ; shift 2 ;;
#             --running     ) export KAFKA_ACTIVE=0     ; shift   ;;
#             --verbose     ) export DEBUG_MODE="yes"   ; shift   ;;
#             -- ) shift ; break ;;
#             *  ) help_usage ;;
#         esac
#     done

#     if [ ! -n ${KAFKA_PATH} ]; then
#         printf "${Red}--kafka-dir option NULL.${ResetCl}\n"
#         help_usage
#     fi
#     shift $((OPTIND - 1))
# }

DEBUG_MODE="yes"
APP_PATH="/APP"
DATA_PATH="/DATA"
CONFLUENT_KAFKA_PATH="${APP_PATH}/kafka.d"
CONFLUENT_KAFKA_LOG_PATH="${DATA_PATH}/kafka-logs"
ZOOKEEPER_DATA_PATH="${DATA_PATH}/zookeeper"

function install_kafka() {
    [ ! -d ${APP_PATH} ] && run_command "mkdir -p ${APP_PATH}"

    ### Confluent Kafka 다운로드 및 링크 생성
    if [ ! -f ${APP_PATH}/confluent-community-7.9.0.tar.gz ]; then
        run_command "wget https://packages.confluent.io/archive/7.9/confluent-community-7.9.0.tar.gz -P ${APP_PATH}"
        if [ $? -eq 0 ]; then
            run_command "tar -zxf ${APP_PATH}/confluent-community-7.9.0.tar.gz -C ${APP_PATH}"
            run_command "cd ${APP_PATH}; ln -s ./confluent-7.9.0 ./kafka.d"    
        else
            logging "ERROR" "Donwload faile."
            return 1
        fi
    fi

    if ! grep -q "${CONFLUENT_KAFKA_PATH}" ${HOME}/.bash_profile; then
        run_command "sed -i '/export PATH/i\export CONFLUENT_HOME=${CONFLUENT_KAFKA_PATH}\/bin\nPATH=\$PATH:\$CONFLUENT_HOME' ${HOME}/.bash_profile"
    fi

    ### 설치 여부 확인
    source ${HOME}/.bash_profile
    if $(command -v kafka-configs |grep -q "kafka-configs"); then
        return 0
    else
        return 1
    fi
}

function setup_kafka() {
    [ ! -d ${DATA_PATH} ] && run_command "mkdir -p ${DATA_PATH}/{kafka-logs,zookeeper}" 

    if [ ! -f ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties.org ]; then
        run_command "cp -p ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties.org"
    fi

    ### kafka log 디렉토리 설정
    if ! grep -q "${CONFLUENT_KAFKA_LOG_PATH}" ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties; then
        run_command "sed -i 's/log.dirs=/#&/g' ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties"
        run_command "sed -i '/^#log.dirs=/a\log.dirs=${CONFLUENT_KAFKA_LOG_PATH}' ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties"
    fi

    ### zookeeper data 디렉토리 설정
    if ! grep -q "${ZOOKEEPER_DATA_PATH}" ${CONFLUENT_KAFKA_PATH}/etc/kafka/zookeeper.properties; then
        run_command "sed -i 's/dataDir=/#&/g' ${CONFLUENT_KAFKA_PATH}/etc/kafka/zookeeper.properties"
        run_command "sed -i '/^#dataDir=/a\dataDir=${ZOOKEEPER_DATA_PATH}' ${CONFLUENT_KAFKA_PATH}/etc/kafka/zookeeper.properties"
    fi

    setup_kafka_systemd
}

function setup_kafka_systemd() {
        ### systemd 파일 생성
    if [ ! -f /usr/lib/systemd/system/kafka.service ]; then
        run_command "cat <<EOF >/usr/lib/systemd/system/kafka.service
[Unit]
Description=confluent kafka
Before=zookeeper.service
After=syslog.target
After=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/bin/sh -c '${CONFLUENT_KAFKA_PATH}/bin/kafka-server-start ${CONFLUENT_KAFKA_PATH}/etc/kafka/server.properties'
ExecStop=/bin/sh -c '${CONFLUENT_KAFKA_PATH}/bin/kafka-server-stop'

[Install]
WantedBy=multi-user.target
EOF"    
    fi
    ### systemd 정상 등록 여부 확인
    systemctl daemon-reload
    if ! $(systemctl list-unit-files kafka.service |grep -q kafka.service); then
        return 1
    fi

    if [ ! -f /usr/lib/systemd/system/zookeeper.service ]; then
        run_command "cat <<EOF >/usr/lib/systemd/system/zookeeper.service
[Unit]
Description=zookeeper
After=syslog.target
After=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/bin/sh -c '${CONFLUENT_KAFKA_PATH}/bin/zookeeper-server-start ${CONFLUENT_KAFKA_PATH}/etc/kafka/zookeeper.properties'
ExecStop=/bin/sh -c '${CONFLUENT_KAFKA_PATH}/bin/zookeeper-server-start'

[Install]
WantedBy=multi-user.target
EOF"
    fi
    ### systemd 정상 등록 여부 확인
    systemctl daemon-reload
    if ! $(systemctl list-unit-files zookeeper.service |grep -q zookeeper.service); then
        return 1
    else
        return 0
    fi
}

main() {
    install_kafka
    if [ $? -eq 0 ]; then
        setup_kafka
    else
        logging "ERROR" "Install failed."
        exit 1
    fi

    # # [ $# -eq 0 ] && help_usage
    # # set_opts "$@"

    # if ! $(javac --version |grep -Eq '8|11|17'); then
    #     logging "ERROR" "Supported Java version 8,11,17, please check java."
    #     exit 1 
    # fi

    # EXTERNAL_IP=$(ip route get $(ip route |awk '/default/ {print $3}') |awk -F'src ' 'NR==1{split($2,a," "); print a[1]}')
    # if [ ${#CLUSTER_IPS[@]} -le 1 ]; then
    #     logging "ERROR" "You must enter at least two --cluster-ips list element."
    #     exit 1
    # fi

    # if ! $(printf '%s\n' "${CLUSTER_IPS[@]}" |grep -q "${EXTERNAL_IP}"); then
    #     logging "ERROR" "--cluster-ips list is not include server ip."
    #     exit 1
    # fi

    # case ${MODE} in
    #     "install" )
    #         install_kafka
    #         if [ $? -eq 0 ]; then
    #             if [ ${#CLUSTER_IPS[@]} -ge 2 ]; then
    #                 setup_kafka_cluster
    #                 [ $? -eq 0 ] && setup_kafka_systemd
    #                 [ $? -eq 0 ] && setup_kafka_storage
    #             else
    #                 KRAFT_UUID="standalone"
    #                 setup_kafka_systemd
    #                 setup_kafka_storage
    #             fi

    #             if [ $? -eq 0 ]; then
    #                 if [ ${KAFKA_ACTIVE} -eq 0 ]; then
    #                     [ -f /usr/lib/systemd/system/kafka.service ] && run_command "systemctl daemon-reload"
    #                     run_command "systemctl start kafka"

    #                     if [ $? -eq 0 ]; then
    #                         sleep 3
    #                         if $(jps |grep -iq 'kafka'); then
    #                             logging "INFO" "Install completed."
    #                             exit 0
    #                         else
    #                             logging "ERROR" "Running fail kafka"
    #                             exit 1
    #                         fi
    #                     else
    #                         exit 1
    #                     fi    
    #                 else
    #                     logging "INFO" "The installation is complete, please perform the command below."
    #                     logging "INFO" "systemctl start kafka && jps |grep -i kafka"
    #                 fi
    #             else
    #                 logging "ERROR" "Setup fail kafka."
    #                 exit 1
    #             fi
    #         else
    #             exit 1
    #         fi
    #     ;;
    #     "remove" )
    #         remove_kafka
    #     ;;
    # esac
}
main $*