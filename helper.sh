
export VAULT_ADDR="http://$(ipconfig getifaddr en0):8200"

function c1_kctl {
    kubectl config use-context cluster-1
    kubectl $*
}

function c2_kctl {
    kubectl config use-context cluster-2
    kubectl $*
}

function c1_kctx {
    kubectl config use-context cluster-1
}
function c2_kctx {
    kubectl config use-context cluster-2
}

# PATH TO YOUR HOSTS FILE
ETC_HOSTS=/etc/hosts
function removehost() {
    HOSTNAME=$1
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
    then
        echo "$HOSTNAME Found in your $ETC_HOSTS, Removing now...";
        sudo sed -i".bak" "/$HOSTNAME/d" $ETC_HOSTS
    else
        echo "$HOSTNAME was not found in your $ETC_HOSTS";
    fi
}

function addhost() {
    HOSTNAME=$1
    IP=$2
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
            fi
    fi
}
