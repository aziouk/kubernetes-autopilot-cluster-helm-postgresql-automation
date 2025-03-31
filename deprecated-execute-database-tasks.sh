# This is deprecated by GSM. Support for Helm postgres install/upgrades now

# execute the master script copy
#./gke-stateful-postgres/scripts/launch-master.sh

#cd gke-stateful-postgres
# if that fails you can copy manually the files clustername should be a $VAR ideally
#kubectl cp scripts postgresql-postgresql-ha-postgresql-0:/tmp/scripts -n postgresql

# Execute the script via automation on the remote cluster primary
#kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U postgres -d postgres -a -q -f /tmp/scripts/create-user.sql

# confirm user added
#kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U postgres -d postgres -a -q -f /tmp/scripts/create-user.sql
# output will report user already exists

#attempt to login with user to test
#echo "checking master"
#kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U px-user -d predictx -a -q
#echo "checking client/propogation"
# this appears broken probably improper syncing updating of the hba controller
##kubectl exec -it pg-client -n postgresql -- psql -U px-user -d predictx -a -q










