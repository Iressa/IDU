#!/bin/bash

# Create directory if doesn't exist yet.
function create_dir() {
    if [[ ! -e project_$1 ]]
    then
        mkdir `echo project_$1`
    fi

    if [[ ! -e project_$1/lang ]]
    then
        mkdir `echo project_$1/lang`
    fi

    if [[ ! -e project_$1/resources ]]
    then
        mkdir `echo project_$1/resources`
    fi
}

function open() {
    # Get name of file to open.
    name=`ls -a docs|grep -E ".*.md"|fzf --print-query|tail -1`

   create_dir $name

    if [[ -e `echo "docs"/$name` ]]
    then
        cp `echo "docs"/$name` `echo "project_"$name/$name`
    else
        vim `echo "docs"/$name`
    fi

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
            cp `echo $locale_wd/$name` `echo project_$name/lang/$i"_"$name`
        fi
    done
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
    open
elif [[ $1 == "commit" ]]
then
    commit $2
elif [[ $1 == "-h" ]]||[[ $1 == "--help" ]]
then
    display_help

else
    echo "Use -h or --help for help."
fi
