#!/bin/bash

# Create directory if doesn't exist yet.
function create_dir() {
    local name=$(echo $1 | sed -e "s/.md//g")
    local project_name=$(echo "project_"$name)

    # Create main project directory.
    if [[ ! -e "$project_name" ]]
    then
        mkdir $project_name
    fi

    # Create language subdirectory.
    if [[ ! -e `echo $project_name"/lang"` ]]
    then
        mkdir `echo $project_name/lang`
    fi

    # Create resource subdirectory.
    if [[ ! -e `echo $project_name"/resources"` ]]
    then
        mkdir `echo $project_name/resources`
    fi

    echo "$project_name"
}

function images() {
    if [[ -z "$1" ]]
    then
        echo "Failed to extract images: No input given."
        exit
    fi

    local filename=$1
    local arr=$(sed "s/\!\[/\n\!\[/g" `echo "docs/"$filename` | grep static/img | sed "s/.*(//" | sed "s/).*//")

    for i in ${arr[@]}; do
        cp $i $2
    done
}

# Get main file.
function get_main_file() {
    if [[ -e `echo "docs"/$name` ]]
    then
        cp `echo "docs"/$name` `echo $project_name/$name`
    else
        vim `echo $project_name/$name`
    fi
}

function get_lang_files() {
    locales=`grep locales docusaurus.config.js|cut -c 14-`
    localesstring=$(echo $locales | sed -e 's/\[//g' -e 's/\]//g' -e 's/\,//g')
    arr=( $localesstring )

    for i in ${arr[@]}; do
        i=$(echo $i | sed -e "s/'//g")
        locale_wd=$(echo "i18n/"$i"/docusaurus-plugin-content-docs/current")

        # Copy the localized file to the project /lang directory
        # with the locale code prefixed e.g., fi_hello.md.
        if [[ -e `echo $locale_wd/$name` ]]
        then
            cp `echo $locale_wd/$name` `echo $project_name"/lang/"$i"_"$name`
        fi
    done
}

function open() {

    # Prompt for file name if not given.
    if [[ -z "$1" ]]
    then
        name=`ls -a docs|grep -E ".*.md"|fzf --print-query|tail -1`
    elif [[ -e "$1" ]]
    then
        name=$($1)
    else
        echo $("Given filename $1 is not valid.")
        exit
    fi

    # Initialize project directory if does not exist.
    project_name=$(create_dir $name)

    # Copy the main file to the project directory.
    get_main_file

    # Copy the localized files to the project directory.
    get_lang_files

    # Copy the image files to the project directory.
    images $name `echo $project_name`
}

function commit() {
    dirname="project_hello.md"
    filename=$(echo $dirname | sed -e "s/project_//g")

    # Copy main file.
    cp `echo $dirname/$filename` `echo "docs/"$filename`

    # Copy localized files.
    if [[ -d `echo $dirname"/lang"` ]]
    then
        arr=($(ls `echo $dirname/lang`))

        for i in ${arr[@]}; do
            locale=$(echo $i | cut -c -2)
            locale_wd=$(echo "i18n/"$locale"/docusaurus-plugin-content-docs/current")

            if [[ ! -d $locale_wd ]]
            then
                mkdir -p $locale_wd
            fi

            cp `echo $dirname/lang/$i` $locale_wd
        done
    fi

    # Delete the project directory.
    if [[ $1 == "-rm" ]]
    then
        rm -r $dirname
    fi
}

function display_help() {
    echo "IDU Iressa Docusaurus Utility
usage: idu [command] [-h] [-rm]

  -h --help : Show this message.
  open      : Open a project for a file. Does not have to exist yet.
  commit    : Commit project files to the main Docusaurus directory.
    -rm     : Delete the IDU project directory after commit."
}

if [[ $1 == "open" ]]
then
    open $2
elif [[ $1 == "commit" ]]
then
    commit $2
elif [[ $1 == "-h" ]]||[[ $1 == "--help" ]]
then
    display_help
else
    echo "Use -h or --help for help."
fi
