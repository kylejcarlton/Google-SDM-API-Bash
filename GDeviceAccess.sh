#!/bin/bash
# DEPENDENCIES:
# curl - https://curl.se/download.html
# jq - https://stedolan.github.io/jq/download/
# weather-util - http://fungi.yuggoth.org/weather/

BASE_PATH="/home/ubuntu/Google-SDM-API"
PROJECT_ID=$(cat $BASE_PATH/project-id)
DEVICE_ID=$(cat $BASE_PATH/device-id)
AUTHORIZATION_CODE=$(cat $BASE_PATH/authorization-code)
OAUTH2_CLIENT_ID=$(cat $BASE_PATH/oauth2-client-id)
OAUTH2_CLIENT_SECRET=$(cat $BASE_PATH/oauth2-client-secret)
WEATHER_STATION=kord

alwaysRun(){
    #Called at the end of ALL functions unconditionally
    if [[ $1 == "" ]]; then echo "Call with required arguments. Available functions are setAuthorizationCode, getAccessRefreshTokens, accessTokenRefresh, and nestValues." && exit 1; fi
    if [[ $1 == "setAuthorizationCode" ]]; then setAuthorizationCode $2; fi
    if [[ $1 == "getAccessRefreshTokens" ]]; then getAccessRefreshTokens; fi
    if [[ $1 == "accessTokenRefresh" ]]; then accessTokenRefresh; fi
    if [[ $1 == "nestValues" ]]; then nestValues; fi
}

setAuthorizationCode(){
    if [[ $1 == "" ]]; then echo "Call with required arguments. When calling setAuthorizationCode the second argument should be authorization-code." && exit 1; fi
    echo -n $1 > $BASE_PATH/authorization-code
    sleep 3s
    getAccessRefreshTokens
    sleep 3s
    nestValues
    tail $BASE_PATH/conditionsHistory.log
}

getAccessRefreshTokens(){
    curl -L -X POST "https://www.googleapis.com/oauth2/v4/token?client_id=${OAUTH2_CLIENT_ID}&client_secret=${OAUTH2_CLIENT_SECRET}&code=${AUTHORIZATION_CODE}&grant_type=authorization_code&redirect_uri=https://www.google.com" > $BASE_PATH/refreshTokenResponse
    cat $BASE_PATH/refreshTokenResponse | jq -r '.access_token' > $BASE_PATH/access-token
    cat $BASE_PATH/refreshTokenResponse | jq -r '.refresh_token' > $BASE_PATH/refresh-token
}

accessTokenRefresh(){
    # crontab - */54 * * * * /home/ubuntu/nestLogger/GDeviceAccess.sh accessTokenRefresh
    REFRESH_TOKEN=$(cat $BASE_PATH/refresh-token)
    curl -L -X POST "https://www.googleapis.com/oauth2/v4/token?client_id=${OAUTH2_CLIENT_ID}&client_secret=${OAUTH2_CLIENT_SECRET}&refresh_token=${REFRESH_TOKEN}&grant_type=refresh_token" | jq -r '.access_token' > $BASE_PATH/access-token 
    { echo "Script Run @ "$(date); } >> $BASE_PATH/tokenRefresh.log
}

nestValues(){
    # crontab - */10 * * * * /home/ubuntu/nestLogger/GDeviceAccess.sh nestValues
    curl -X GET "https://smartdevicemanagement.googleapis.com/v1/enterprises/${PROJECT_ID}/devices/${DEVICE_ID}" -H 'Content-Type: application/json' -H 'Authorization: Bearer '$(cat $BASE_PATH/access-token)'' > $BASE_PATH/nestValues
    {
        echo -n "$(date "+%m/%d/%Y %T")|";
        echo -n  "humidity%:"$(cat $BASE_PATH/nestValues | jq -r '.traits."sdm.devices.traits.Humidity".ambientHumidityPercent')"|";
        echo -n  "tempC:"$(cat $BASE_PATH/nestValues | jq -r '.traits."sdm.devices.traits.Temperature".ambientTemperatureCelsius')"|";
        echo -n  "ecoTempC:"$(cat $BASE_PATH/nestValues | jq -r '.traits."sdm.devices.traits.ThermostatEco".heatCelsius')"|";
        echo -n "setTempC:"$(cat $BASE_PATH/nestValues | jq -r '.traits."sdm.devices.traits.ThermostatTemperatureSetpoint".heatCelsius')"|";
        echo -n "outsideTempC:"$(weather-util -q --headers=temperature $WEATHER_STATION | grep -oP '(?<=\().*(?=\))'| tr -d " C")"|";
        echo "outsideHumidity%:"$(weather-util -q --headers=relative_humidity $WEATHER_STATION | grep -oP '(?<=Humidity: )[^ ]*'| tr -d %)"|";
    } >> $BASE_PATH/conditionsHistory.log
    tail $BASE_PATH/conditionsHistory.log
}

alwaysRun $1 $2