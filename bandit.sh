#!/usr/bin/env bash
ssh_comand(){
	confused_about="ssh_comand doesn't know"
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
	domain='bandit.labs.overthewire.org'
	port=2220
    sshpass -p $2 ssh -o StrictHostKeyChecking=no "bandit${1}@${domain}" -p "$port" "$3" 2>./exception.log
    # sshpass -p $2 ssh -o StrictHostKeyChecking=no $1@"$domain" -p "$port" <<-END_SSH_CMD
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
		# allwords+=("${words[@]}") # works the same
	done <<< "$1"
	# ✦ ❯ array=(a b c d)
	# ✦ ❯ echo "${array[@]}"
	# a b c d
	# ✦ ❯ echo "${#array[@]}"
	# 4
	# ✦ ❯ echo "$((${#array[@]}-1))"
	# 3
	if [ ${#allwords[@]} -eq 0 ]; then
		echo ""
	else
		echo "${allwords[${#allwords[@]}-1]}"
	fi
}

print_pwd_to_file(){
	echo "Level $1: $2" >> ./passwords
}

cache_passwords(){
	local level=0
	local pwd="bandit0"
	if [ -e ./passwords ]; then
		while read line; do
			pattern="^Level[[:space:]]+${level}:[[:space:]]+([a-zA-Z0-9]{32})$"
			if [[ $line =~ $pattern ]]; then
				level=$((level+1))
				pwd="${BASH_REMATCH[1]}"
			else
				break
			fi
		done < ./passwords
	fi
	echo "${level} ${pwd}"
}

read level pwd <<< "$(cache_passwords)"

if [ $level = 0 ]; then
	pwd=$(extract_last_segment "$(ssh_comand $level $pwd "cat ./readme")")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 1 ]; then
	pwd=$(extract_last_segment "$(ssh_comand $level $pwd "cat ./-")")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 2 ]; then
	pwd=$(extract_last_segment "$(ssh_comand $level $pwd "cat './--spaces in this filename--'")")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 3 ]; then
	# substitution happens inside the $() so use sigle quote to forbid passed ssh command's substitution 
	pwd=$(extract_last_segment "$(ssh_comand $level $pwd 'cat $(find ./inhere -type f)')") 
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

is_line_readable(){
	if [ -n "$1" ]; then
		read -a line <<< "$(echo "$1" | tr -d "\n" | sed 's/../& /g')"
		for char in ${line[@]}; do
			if [ $((0x$char)) = $((0x0a)) ]; then
				# Skip "\n" in the original file
				continue
			fi
			if [ $((0x$char)) -gt $((0x7E)) ] || [ $((0x$char)) -lt $((0x20)) ]; then
				return -1
			fi
		done
	else
		return -1
	fi
	return 0
}

if [ $level = 4 ]; then
	files=$(ssh_comand $level "$pwd" 'for file in $(find ./inhere -type f); do echo $(xxd -p $file | tr -d "\n" ); done')
	# echo "$res" > res
	# var=$(echo -e "1\n2\n3\n4")
	# echo $var # echo var_split to 1 2 3 4 # echo 1 2 3 4
	for file in $files; do
		# use parenthesis to execute command in a subshell, so that main process won't exit
		if (is_line_readable "$file"); then
			pwd="$(echo "$file" | xxd -r -p)"
			break
		fi
	done
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 5 ]; then
	files=$(ssh_comand $level "$pwd" 'for file in $(find ./inhere -type f -size 1033c ! -executable); do echo $(xxd -p $file | tr -d "\n" ); done')
	for file in $files; do
		# This check is not actually needed, but is consistant with the problem description 
		if (is_line_readable "$file"); then
			pwd=$(extract_last_segment "$(echo "$file" | xxd -r -p)")
			break
		fi
	done
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 6 ]; then
	# scanning certain files requires permissions  
	pwd=$(ssh_comand $level "$pwd" 'find / -type f -user bandit7 -group bandit6 -size 33c -exec cat {} \; 2>/dev/null')
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 7 ]; then
	# this data.txt looks like this:
	# name1 blablabla1
	# name2 blablabla2
	pwd=$(extract_last_segment "$(ssh_comand $level "$pwd" 'grep millionth ./data.txt')")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 8 ]; then
	# sort by lines
	pwd=$(ssh_comand $level "$pwd" 'sort ./data.txt | uniq --unique')
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 9 ]; then
	pattern='=+\s*([a-zA-Z0-9]{32})'
	# a: binary, o: ouptut the matched group 0, E: POSIX extended regular expression
	pwd=$(extract_last_segment "$(ssh_comand $level "$pwd" "grep -aoE '$pattern' ./data.txt")")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi

if [ $level = 10 ]; then
	pwd=$(extract_last_segment "$(ssh_comand $level "$pwd" 'base64 -d ./data.txt')")
	print_pwd_to_file $level "$pwd"
	level=$((level+1))
fi
