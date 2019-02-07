set -e

function command {
	if [[ $# > 0 ]]
	then
		declare -A arguments
		
		declare -i count=2
		
		for argument in "$@"
		do
			if [[ ${argument} =~ ^\-\-(.*)=(.*)$ ]]
			then
				let ++count
				
				parameter="${BASH_REMATCH[1]}"
				value="${BASH_REMATCH[2]}"
				
				if [[ -v arguments["${parameter}"] ]]
				then
					arguments["${parameter}"]="${value}"
				fi
			else
				subcommand="${argument}"
				break
			fi
		done
		
		if [[ -v subcommand ]]
		then
			funcmd="command_${subcommand}"
			if [[ $(type -t -- "${funcmd}") = function ]]
			then
				for key in "${!arguments[@]}"
				do
					export -- "${key//-/_}=${arguments[${key}]}"
				done
				
				"${funcmd}" "${@:${count}}"
			else
				echo "error: unknown subcommand '${subcommand}'"
				return 1
			fi
		else
			echo 'error: missing subcommand'
			return 1
		fi
	else
		echo 'error: missing subcommand'
		return 1
	fi
}

exec > >(sed -e 's/^/git-gcs: /' >&2)

command "$@"
