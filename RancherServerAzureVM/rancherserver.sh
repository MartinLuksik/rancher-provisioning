#!/bin/bash -x
export curlimage=appropriate/curl
export jqimage=stedolan/jq

if [ `command -v curl` ]; then
  curl -sL https://releases.rancher.com/install-docker/${docker_version_server}.sh | sh
elif [ `command -v wget` ]; then
  wget -qO- https://releases.rancher.com/install-docker/${docker_version_server}.sh | sh
fi

for image in $curlimage $jqimage "rancher/rancher:${rancher_version}"; do
  until docker inspect $image > /dev/null 2>&1; do
    docker pull $image
    sleep 2
  done
done


docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:${rancher_version}

while true; do
  docker run --rm --net=host $curlimage -sLk https://127.0.0.1/ping && break
  sleep 5
done

# Login
while true; do

    LOGINRESPONSE=$(docker run \
        --rm \
        --net=host \
        $curlimage \
        -s "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure)
    LOGINTOKEN=$(echo $LOGINRESPONSE | docker run --rm -i $jqimage -r .token)
    echo "Login Token is $LOGINTOKEN"
    if [ "$LOGINTOKEN" != "null" ]; then
        break
    else
        sleep 5
    fi
done


# Change password
docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"admin","newPassword":"${admin_password}"}' --insecure

# Create API key
APIRESPONSE=$(docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure)

# Extract and store token
APITOKEN=`echo $APIRESPONSE | docker run --rm -i $jqimage -r .token`

# Configure server-url
RANCHER_SERVER="https://$(docker run --rm --net=host $curlimage -s http://169.254.169.254/latest/meta-data/public-ipv4)"
docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_SERVER'"}' --insecure