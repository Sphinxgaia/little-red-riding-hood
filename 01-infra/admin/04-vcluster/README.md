
for (( i=0; i <= 20; i++ )); do cmd_prefix ./newcluster.sh app$i; done


# clean up

for (( i=0; i <= 20; i++ )); do cmd_prefix ./delcluster.sh app$i; done

