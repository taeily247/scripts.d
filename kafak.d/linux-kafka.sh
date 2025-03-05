#/bin/bash
### 프롬포트 색상
function SetColor() {
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
    BWhite='\033[1;37m'       # White
    UWhite='\033[4;37m'       # White
    IWhite='\033[3;37m'       # White
}

function RunCmd() {
    local COMMAND=$@

    case ${DEBUG_MODE} in
        "yes" )
            LogMsg "CMD" "${COMMAND}"
            eval "${COMMAND}" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                LogMsg "OK"
                return 0
            else
                LogMsg "FAIL"
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

function LogHelp() {
    echo -e "
${UWhite}Usage${ResetCl}: $0 [-i | -r] --path ${IWhite}<APP_PATH>${ResetCl}
                        [--data-path] [--cluster-ips] [--running] [--verbose]

${UWhite}Positional arguments${ResetCl}:
--path ${IWhite}<APP_PATH>${ResetCl}
                  Kafka, zookeeper download, application path
                  If you want to use /APP as APP_PATH, Caution! [kafka.d] directory will be created under the path you set.
                  ex) --path="/APP" => KAFKA_PATH="/APP/kafka.d"
--data-path ${IWhite}<DATA_PATH>${ResetCl}
                  Kafkam, Zookeeper data path
                  If you want to use /DATA as KAFKA_DATA_PATH, ZOOKEEPER_DATA_PATH, 
                  Caution! [kafka_data.d],[zookeeper_data.d] directory will be created under the path you set.
                  ex) --data-path="/DATA" => KAFKA_DATA_PATH="/DATA/kafka_data.d", ZOOKEEPER_DATA_PATH="/DATA/zookeeper_data.d"

${UWhite}Options${ResetCl}:
-h, --help        Show this hel message and exit
-i                Install binaray kafka
-r                Remove binaray kafka

--cluster-ips ${IWhite}<KAFKA_PATH>${ResetCl}
                  Kafka and Zookeeper cluster ips (Ex. "192.168.0.1,192.168.0.2...")
--running
                  When the Kafka setup is complete, The service will running.
--verbose
                  Prints in more detail about the script.
"
    exit 0
}

function set_opts() {
    arguments=$(getopt --options irh \
    --longoptions help,path:,data-path:,cluster-ips:,running,verbose \
    --name $(basename $0) \
    -- "$@")

    ### 기본 스크립트 옵션
    KAFKA_ACTIVE="off"
    DEBUG_MODE="no"
    CLUSTER_IPS=()
    eval set -- "${arguments}"
    # while true; do
    while [[ "$1" != "" ]]; do
        case "$1" in
            -h | --help ) help_usage    ;;
            -i ) MODE="install" ; shift ;;
            -r ) MODE="remove"  ; shift ;;
            --path      ) APP_PATH="$2" ; shift 2 ;;
            --data-path ) DATA_PATH="$2"  ; shift 2 ;;
            --cluster-ips     )
                IFS=',' read -r -a CLUSTER_IPS <<< "$2"
                #read -r -a CLUSTER_IPS <<< "$2"
                shift 2
            ;;
            --running     ) export KAFKA_ACTIVE="on"  ; shift   ;;
            --verbose     ) export DEBUG_MODE="yes"   ; shift   ;;
            -- ) shift ; break ;;
            *  ) help_usage ;;
        esac
    done

    if [ ! -n ${APP_PATH} ]; then
        printf "${Red}--path option NULL.${ResetCl}\n"
        help_usage
    fi
    shift $((OPTIND - 1))
}


function LogMsg() {
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

##################
### Kafak 바이너리 파일을 다운 및 링크 설정
##################
function Inst_Kafaka() {
    [ ! -d ${APP_PATH} ] && RunCmd "mkdir -p ${APP_PATH}"

    ### Kafka 파일 다운 및 기본 구성
    if [ ! -f ${APP_PATH}/kafka_2.13-3.9.0.tgz ]; then
        RunCmd "wget https://dlcdn.apache.org/kafka/3.9.0/kafka_2.13-3.9.0.tgz -P ${APP_PATH}"
        RunCmd "tar -zxf ${APP_PATH}/kafka_2.13-3.9.0.tgz -C ${APP_PATH}"
    fi

    if [ ! -d ${KAFKA_PATH} ]; then
        RunCmd "cd ${APP_PATH}; ln -s ./kafka_2.13-3.9.0 kafka.d"
    fi

    ### kafka.d/bin 파일 환경변수로 등록
    if ! grep -q 'kafka.d' ${HOME}/.bash_profile; then
        RunCmd "sed -i '/export PATH/i\PATH=\$PATH:${KAFKA_PATH}\/bin' ${HOME}/.bash_profile"
    fi
}

##################
### Kafka 설정
##################
function Set_Kafka() {
    [ ! -d ${KAFKA_DATA_PATH} ] && RunCmd "mkdir -p ${KAFKA_DATA_PATH}"

    if ! grep -q "zookeeper.connect=.*.${KAFKA_IP}:2181.*." ${KAFKA_CONFIG_PATH}; then
        RunCmd "cp -p ${KAFKA_CONFIG_PATH} ${KAFKA_CONFIG_PATH}_$(date +%y%m%d_%H%M%S)"

        ### --cluster-ips에 기재된 IP입력 순서를 기준으로 broker id 할당
        local _tmp_line=()
        local _num=0
        for (( idx=0;idx<${#CLUSTER_IPS[@]};idx++ )); do
            _num=$(expr $idx + 1)
            _tmp_line+=("${CLUSTER_IPS[${idx}]}:2181")
            if [ "${CLUSTER_IPS[${idx}]}" == "${KAFKA_IP}" ]; then
                ### Broker id 수정
                if ! grep "^broker.id=${_num}" ${KAFKA_CONFIG_PATH}; then
                    RunCmd "sed -i 's/^broker.id/#&/g' ${KAFKA_CONFIG_PATH}"
                    RunCmd "sed -i \"/^#broker.id/a\broker.id=${_num}\" ${KAFKA_CONFIG_PATH}"
                fi
            fi
        done

        ### listeners 수정
        if ! grep -q "^listeners=PLAINTEXT://${KAFKA_IP}:9092" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^listeners=PLAINTEXT/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i \"/^#listeners=PLAINTEXT/a\listeners=PLAINTEXT://${KAFKA_IP}:9092\" ${KAFKA_CONFIG_PATH}"
        fi

        ### advertised.listeners 수정
        if ! grep -q "^advertised.listeners=PLAINTEXT://${KAFKA_IP}:9092" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^advertised\.listeners=PLAINTEXT/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i \"/^#advertised\.listeners=PLAINTEXT/a\advertised.listeners=PLAINTEXT://${KAFKA_IP}:9092\" ${KAFKA_CONFIG_PATH}"
        fi

        ### log.dirs 수정
        if ! grep -q '${KAFKA_DATA_PATH}/logs' ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^log.dirs/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i '/^#log.dirs/a\log.dirs=${KAFKA_DATA_PATH}/logs' ${KAFKA_CONFIG_PATH}"
        fi

        ### num.partitions 수정
        if ! grep -q "num.partitions=${#CLUSTER_IPS[@]}" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^num.partitions/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i '/^#num.partitions/a\num.partitions=${#CLUSTER_IPS[@]}' ${KAFKA_CONFIG_PATH}"
        fi
    
        ### offsets.topic.replication.factor 수정
        if ! grep -q "offsets.topic.replication.factor=${#CLUSTER_IPS[@]}" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^offsets.topic.replication.factor/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i '/^#offsets.topic.replication.factor/a\offsets.topic.replication.factor=${#CLUSTER_IPS[@]}' ${KAFKA_CONFIG_PATH}"
        fi

        ### transaction.state.log.replication.factor 수정
        if ! grep -q "transaction.state.log.replication.factor=${#CLUSTER_IPS[@]}" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^transaction.state.log.replication.factor/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i '/^#transaction.state.log.replication.factor/a\transaction.state.log.replication.factor=${#CLUSTER_IPS[@]}' ${KAFKA_CONFIG_PATH}"
        fi

        ### transaction.state.log.min.isr 수정
        KAFKA_ISR_CNT=$(expr ${#CLUSTER_IPS[@]} - 1)
        if ! grep -q "transaction.state.log.min.isr=${KAFKA_ISR_CNT}" ${KAFKA_CONFIG_PATH}; then
            RunCmd "sed -i 's/^transaction.state.log.min.isr/#&/g' ${KAFKA_CONFIG_PATH}"
            RunCmd "sed -i '/^#transaction.state.log.min.isr/a\transaction.state.log.min.isr=${KAFKA_ISR_CNT}' ${KAFKA_CONFIG_PATH}"
        fi

        ### zookeeper.connect 수정
        RunCmd "sed -i 's/^zookeeper.connect=/#&/g' ${KAFKA_CONFIG_PATH}"
        RunCmd "sed -i \"/^#zookeeper.connect=/a\zookeeper.connect=$(echo "${_tmp_line[@]}" |sed 's/ /,/g')\" ${KAFKA_CONFIG_PATH}"
    fi
}

##################
### Zookeeper 설정
##################
function Set_Zookeeper() {
    ### Zookeeper 설정
    [ ! -d ${ZOOKEEPER_DATA_PATH} ] && RunCmd "mkdir -p ${ZOOKEEPER_DATA_PATH}"

    if ! grep -q '^#dataDir=/tmp/zookeeper' ${ZOOKEEPER_CONFIG_PATH}; then
        RunCmd "cp -p ${ZOOKEEPER_CONFIG_PATH} ${ZOOKEEPER_CONFIG_PATH}_$(date +%y%m%d_%H%M%S)"

        RunCmd "sed -i 's/^dataDir=\/tmp\/zookeeper/#&/g' ${ZOOKEEPER_CONFIG_PATH}"
        RunCmd "sed -i \"/^#dataDir/a\dataDir=\${ZOOKEEPER_DATA_PATH}\" ${ZOOKEEPER_CONFIG_PATH}"
        
        [ ! $(grep -q 'tickTime' ${ZOOKEEPER_CONFIG_PATH}) ] && RunCmd "sed -i $'\$a\tickTime=2000' ${ZOOKEEPER_CONFIG_PATH}"
        [ ! $(grep -q 'initLimit' ${ZOOKEEPER_CONFIG_PATH}) ] && RunCmd "sed -i $'\$a\initLimit=10' ${ZOOKEEPER_CONFIG_PATH}"
        [ ! $(grep -q 'syncLimit' ${ZOOKEEPER_CONFIG_PATH}) ] && RunCmd "sed -i $'\$a\syncLimit=5' ${ZOOKEEPER_CONFIG_PATH}"

        ### --cluster-ips에 기재된 IP입력 순서를 기준으로 server id 할당, zookeeper/myid에 매칭된 ID 생성
        local _num=0
        for (( idx=0;idx<${#CLUSTER_IPS[@]};idx++ )); do
            _num=$(expr $idx + 1)
            [ "${CLUSTER_IPS[${idx}]}" == "${KAFKA_IP}" ] && RunCmd "echo \"${_num}\" >${ZOOKEEPER_DATA_PATH}/myid"
            RunCmd "sed -i $'\$a\server.${_num}=${CLUSTER_IPS[${idx}]}:2887:3887' ${ZOOKEEPER_CONFIG_PATH}"
        done
    fi
}

##################
### Systemd 파일 생성
##################
function Create_Systemd() {
    ### zookeeper systemd파일 생성
    if [ ! -f /usr/lib/systemd/system/zookeeper.service ]; then
        RunCmd "cat <<EOF >/usr/lib/systemd/system/zookeeper.service
[Unit]
Description=zookeeper
After=syslog.target
After=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/bin/sh -c '${KAFKA_PATH}/bin/zookeeper-server-start.sh ${KAFKA_PATH}/config/zookeeper.properties'
ExecStop=/bin/sh -c '${KAFKA_PATH}/bin/zookeeper-server-stop.sh'

[Install]
WantedBy=multi-user.target
EOF"
    fi
    [ $? -eq 0 ] && RunCmd "systemctl daemon-reload"

    ### kafka systemd 파일 생성
    if [ ! -f /usr/lib/systemd/system/kafka.service ]; then
        RunCmd "cat <<EOF >/usr/lib/systemd/system/kafka.service
[Unit]
Description=kafka
Before=zookeeper.service
After=syslog.target
After=network.target

[Service]
Type=simple
Restart=on-failure

export KAFKA_OPTS="-Djava.net.preferIPv4Stack=True"
export KAFKA_HEAP_OPTS="-Xms2g -Xmx2g"

ExecStart=/bin/sh -c '${KAFKA_PATH}/bin/kafka-server-start.sh ${KAFKA_PATH}/config/server.properties'
ExecStop=/bin/sh -c '${KAFKA_PATH}/bin/kafka-server-stop.sh'

[Install]
WantedBy=multi-user.target
EOF"
    fi
    [ $? -eq 0 ] && RunCmd "systemctl daemon-reload"
}


function main() {
    SetColor
    [ $# -eq 0 ] && LogHelp
    set_opts "$@"

    [ -z ${DATA_PATH} ] && DATA_PATH="/DATA"
    KAFKA_DATA_PATH="${DATA_PATH}/kafka_data.d"
    ZOOKEEPER_DATA_PATH="${DATA_PATH}/zookeeper_data.d"
    KAFKA_PATH="${APP_PATH}/kafka.d"
    
    KAFKA_CONFIG_PATH="${KAFKA_PATH}/config/server.properties"
    ZOOKEEPER_CONFIG_PATH="${KAFKA_PATH}/config/zookeeper.properties"

    printf "===============================\n"
    printf "# 1. KAFKA_PATH                = %s\n" ${KAFKA_PATH}
    printf "# 2. KAFKA_DATA_PATH           = %s\n" ${KAFKA_DATA_PATH}
    printf "# 3. ZOOKEEPER_DATA_PATH       = %s\n" ${ZOOKEEPER_DATA_PATH}
    printf "# 4. KAFKA ip list             \n"

    KAFKA_IP=$(ip route get $(ip route |awk '/default/ {print $3}') |awk -F'src ' 'NR==1{split($2,a," "); print a[1]}')
    for ((_idx=0 ; ${_idx} < ${#CLUSTER_IPS[@]} ; _idx++)); do
        if [ "${KAFKA_IP}" ==  "${CLUSTER_IPS[${_idx}]}" ]; then
            printf "# 4-$(expr ${_idx} + 1). ${CLUSTER_IPS[${_idx}]} ${Red}(myIP)${ResetCl}\n"
        else
            printf "# 4-$(expr ${_idx} + 1). ${CLUSTER_IPS[${_idx}]}\n"
        fi
    done
    printf "# 5. KAFKA Service auto enable = %s\n" ${KAFKA_ACTIVE}
    printf "# 6. Script Debug mode         = %s\n" ${DEBUG_MODE}
    printf "===============================\n"

    read -p "Continue? (y/N)" _ans
    case ${_ans} in
        [Yy]| [Yy][Ee][Ss] )
            Inst_Kafaka
            if [ $? -eq 0 ]; then
                
                Set_Kafka
                if [ $? -eq 0 ]; then

                    Set_Zookeeper
                    if [ $? -eq 0 ]; then
                        
                        Create_Systemd
                        case ${KAFKA_ACTIVE} in
                            "on" )
                                RunCmd "systemctl start zookeeper kafka && systemctl enable --now zookeeper kafka"
                                if [ $? -eq 0 ]; then
                                    LogMsg "INFO" "Complete kafka and zookeeper."
                                    exit 0
                                else
                                    LogMsg "ERROR" "Service start fail kafka and zookeeper."
                                    exit 0
                                fi
                            ;;
                            "off" ) 
                                LogMsg "INFO" "Complete kafka and zookeeper, please excute command 'systemctl start zookeeper kafka && systemctl enable --now zookeeper kafka.'"
                                exit 0 
                            ;;

                        esac
                    else
                        LogMsg "ERROR" "Setup fail Zookeeper."

                    fi

                else
                    LogMsg "ERROR" "Setup fail Kafka."
                    exit 1
                fi

            else
                LogMsg "ERROR" "Install fail Kafka."
                exit 1
            fi
        ;;
        [Nn]| [Nn][Oo] )
            exit 0
        ;;
        * ) exit 0
    esac
}
main $*