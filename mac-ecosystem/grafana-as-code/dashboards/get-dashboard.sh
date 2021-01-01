#! /bin/bash -e

# sets env
URL=35.225.247.177

# ensures that yq and jq are installed
which yq 2>&1 >/dev/null || (echo "Error, yq executable is required" && exit 1) || exit 1
which jq 2>&1 >/dev/null || (echo "Error, jq executable is required" && exit 1) || exit 1

# curls grafana and gets a list of dashboards
cu() {
TMPFILE=$(mktemp)
curl "https://$URL/api/search"|jq -r '.' > $TMPFILE
ARRY=$(jq -r '.[].title' $TMPFILE)
}




prompt() {
    echo "These are the current dashboards: "
    echo ""
    printf "$ARRY"
    echo ""
    read -p 'Do you want to make a configmap for one of these dashboards?[y/n] ' P2

}
# generates a configmap for the dashboard specified
name() {
   PRE=$(mktemp XXXXX)
   TMPFILE2="$(echo $PRE| awk '{print tolower($0)'}).json"
   read -p 'Enter in the name of the dashboard you wish to create a configmap for: ' DASH
   NAME=$(echo $DASH| sed 's/ //g'|awk '{print tolower($0)'})
   ID=$(jq -r --arg value "$DASH" '.[]| select(.title == $value) | .uid' $TMPFILE)
   curl "https://$URL/api/dashboards/uid/$ID/"|jq -r '.dashboard|del(.meta)|.id = null' > $TMPFILE2
   kubectl create configmap $NAME --namespace=cwow-prometheus --from-file=$TMPFILE2 --dry-run=true -o yaml|yq w - --tag '!!str' metadata.labels.grafana_dashboard '1' |grep -v creationTimestamp > "$NAME.yaml"
   echo "Generated: $NAME.yaml"
   rm $TMPFILE $TMPFILE2 $PRE
   exit 1
}


list() {
    read -p "Do want to you list current Grafana dashboards in $ENV?[y/n] "  P1
}

list

if [[ $P1 == "y" ]]
then
    cu
    prompt
fi

if [[ $P2 == "y" ]]
then
    name
fi

if [[  $P1 == "n" || $P2 == "n" ]]
then exit 1
fi

if [[ ($P1 != y||n) ]]
then
    echo "You did not enter a valid option."
    sleep 1
    exec bash "$0" "$@"
fi


