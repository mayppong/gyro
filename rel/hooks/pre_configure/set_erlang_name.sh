# /rel/hooks/pre_configure/set_erlang_name.sh
export ERLANG_NAME=$(echo $K8S_POD_IP | sed 's/\./-/g').gyro.default.svc.cluster.local.