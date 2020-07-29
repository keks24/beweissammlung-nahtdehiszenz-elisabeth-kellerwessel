#!/bin/bash
if [[ $(/usr/bin/id --user --name) != "ramon" ]]
then
    /bin/echo -e "\e[01;31mExecute this script as user 'ramon'.\e[0m"
    exit 1
fi

command_list=(awk b2sum diff ls patch rm)
checkCommands()
{
    for current_command in "${command_list[@]}"
    do
        unalias ${current_command} 2>/dev/null
        if [[ ! $(command -v ${current_command} 2>/dev/null) ]]
        then
            /bin/echo -e "\e[01;31mCould not find command '${current_command}'.\e[0m"
            exit 1
        fi
    done
}

checkCommands

# define global variables
IFS=$'\n'
email_filename="Beschwerde und Entschädigung: Operation, Katze, EKH, Schmusi, 18.07.2020.eml"
current_email_file="${email_filename}"
# bad use of "ls" here, but it does its job. :)
new_email_file="$(/bin/ls /home/$(/usr/bin/id --user --name)/downloads/*${email_filename})"
email_patch_file="${email_filename}.patch"
declare -a email_file_list
email_file_list=("${current_email_file}" "${new_email_file}")

checkIfFileExists()
{
    local file_list=("${!1}")
    local file=

    for file in ${file_list[@]}
    do
        if [[ ! -f "${file}" ]]
        then
            /bin/echo -e "\e[01;31mCould not find file '${file}'.\e[0m"
            exit 1
        fi
    done
    unset file
}

cleanUp()
{
    local file_list="${1} ${2}"

    for file in ${file_list}
    do
        if [[ -f "${file}" ]]
        then
            /bin/rm "${file}"
        fi
    done
}

compareChecksums()
{
    local file_list=("${!1}")
    local file1="${file_list[0]}"
    local file2="${file_list[1]}"

    local checksum_file1=$(generateChecksum "${file1}" | /usr/bin/awk '{ print $1 }')
    local checksum_file2=$(generateChecksum "${file2}" | /usr/bin/awk '{ print $1 }')

    if [[ "${checksum_file1}" == "${checksum_file2}" ]]
    then
        /bin/echo -e "\e[01;31mThe checksum of '${file1}' and '${file2}' are identical, nothing to do ...\e[0m"
        exit 1
    fi
}

generateChecksum()
{
    local file="${1}"

    /usr/bin/b2sum "${file}"
}

patchEmailFile()
{
    /usr/bin/diff --unified="3" "${current_email_file}" "${new_email_file}" > "${email_patch_file}"
    /usr/bin/patch --verbose --input="${email_patch_file}"
}

main()
{
    checkIfFileExists email_file_list[@]

    compareChecksums email_file_list[@]

    patchEmailFile

    cleanUp "${new_email_file}"
}

main
