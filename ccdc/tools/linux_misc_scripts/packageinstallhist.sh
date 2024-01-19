(zcat /var/log/apt/history.log.1.gz; cat /var/log/apt/history.log) | grep --color=no -E "^(Start-Date|Commandline):" | paste - - | sed -r 's/Start-Date: (.*?)\s*Commandline: (.*)/\2 # Started: \1/g' | tee packagelogstat

