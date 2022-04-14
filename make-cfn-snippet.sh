#!/usr/bin/env bash

export LC_ALL=C

function usage() {
  cat <<EOF
Usage: ./$0 [Option]

Option:
  -u,--ultisnip     (default) format for UltiSnip
  -n,--neosippet    format for NeoSnippet 
  -h,--help         display this message.
EOF
}

# option for below snippet plugins
# - neosnippet
# - Ultisnip
target="${1:-u}"
case "${target#-}" in
    u|-ultisnip)
        endsnippet_str="endsnippet"
        ;;
    n|-neosnippet)
        endsnippet_str=""
        ;;
    h|--help)
        usage
        exit 1
        ;;
    *)
        usage
        exit 1
        ;;
esac

echo "Format: $endsnippet_str"

# initialize variables
home=$(cd $(dirname $0); pwd)
aws_cfn_doc_repo="${home}/aws-cloudformation-user-guide"
aws_cfn_doc_dir="${aws_cfn_doc_repo}/doc_source"

# update submodule(aws-cloudformation-user-guide)
git submodule foreach git pull origin main
mkdir -p "${home}/snippets/"
rm -vrf "${home}"/snippets/*


# main
cd "${aws_cfn_doc_dir}"
for file_type in yaml
do
  echo generating: $file_type
  snip="${home}/snippets/${file_type}.snippets"
  # AWS Resource snippets
  echo "### AWS Resource snippets" >> "${snip}"
  for FILE in $(grep "^### ${file_type^^}" aws-resource* | awk -F: '{ print $1 }' | sort -u)
  do
    echo "snippet $(sed -n 1P $FILE | sed -e 's/^# //g' -e 's/<a .*//g' -e 's/ /::/g')" >> "${snip}"

    start=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==1 { print $1}')" + 1)
    end=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==2 { print $1}')" - 1)

    sed -ne "/^### ${file_type^^}/,\$p" "$FILE" \
      | sed -ne "${start},${end}p" \
      | sed -e "s/^/  /g" \
      | sed -e "s/([^)]*)//g" \
      | sed -e "s/\[//g" -e "s/\]//g" >> "${snip}"
    echo -n "${endsnippet_str}" >> "${snip}"
    echo "" >> "${snip}"
    echo "" >> "${snip}"
  done

  # Resource Properties snippets
  echo "### Resource Properties snippets" >> "${snip}"
  for FILE in $(grep "^### ${file_type^^}" aws-properties-* | awk -F: '{ print $1 }' | sort -u)
  do
    echo -n "snippet $(sed -n 1P $FILE | sed -e 's/^# //g' -e 's/<a .*//g' -e 's/.* //g')" >> "${snip}"
    echo "$FILE" | sed -e 's/aws-properties//g' -e 's/.md//g' >> "${snip}"

    start=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==1 { print $1}')" + 1)
    end=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==2 { print $1}')" - 1)

    sed -ne "/^### ${file_type^^}/,\$p" "$FILE" \
      | sed -ne "${start},${end}p" \
      | sed -e "s/^/  /g" \
      | sed -e "s/([^)]*)//g" \
      | sed -e "s/\[//g" -e "s/\]//g" >> "${snip}"
    echo -n "${endsnippet_str}" >> "${snip}"
    echo "" >> "${snip}"
    echo "" >> "${snip}"
  done
done

mv -vf "${home}/snippets/yaml.snippets" "${home}/snippets/yaml_cloudformation.snippets"

cat >> "${home}/snippets/yaml.snippets" <<-EOS
	snippet AWSTemplateFormatVersion
	  AWSTemplateFormatVersion: "2010-09-09"
	  Description: A sample template
	  Resources:
	    MyEC2Instance: # inline comment
	      Type: "AWS::EC2::Instance"
	      ...
	${endsnippet_str}

EOS


