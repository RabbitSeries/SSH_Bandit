# !/usr/bin/bash
# domain='bandit.labs.overthewire.org'
# port=2220
# echo "bandit0@$domain"
# echo "$port"
# ssh bandit0@"$domain" -p "$port"
# sshpass -p "bandit0" ssh -o StrictHostKeyChecking=no bandit0@"$domain" -p "$port" $1 && exit

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
    sshpass -p $2 ssh -o StrictHostKeyChecking=no $1@"$domain" -p "$port" "$3"
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
level=0
level1_pwd=$(extract_last_segment "$(ssh_comand bandit${level} bandit${level} "cat readme")")
echo "Level 1 password: ${level1_pwd}" > ./passwords

level=$((level+1))
level2_pwd=$(extract_last_segment "$(ssh_comand bandit${level} ${level1_pwd} "cat ./-")")
echo "Level 2 password: ${level2_pwd}" >> ./passwords

level=$((level+1))
level3_pwd=$(extract_last_segment "$(ssh_comand bandit${level} ${level2_pwd} "cat './--spaces in this filename--'")")
echo "Level 3 password: ${level3_pwd}" >> ./passwords

level=$((level+1))
level4_filename=$(extract_last_segment "$(ssh_comand bandit${level} ${level3_pwd} 'ls ./inhere -a')")
level4_pwd=$(extract_last_segment "$(ssh_comand bandit${level} ${level3_pwd} "cat ./inhere/${level4_filename}")")
echo "Level 4 password: ${level4_pwd}" >> ./passwords


humman_raedable(){
	if [ -z "$1" ]; then
		exit 0
	fi
	

}

# level=$((level+1))
# level2_pwd=$(extract_last_segment "$(ssh_comand bandit${level} level1_pwd 'cat ./-')")
