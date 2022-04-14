#!/usr/bin/env bash

export LC_ALL=C

endsnippet_str="endsnippet"
echo "Format: $endsnippet_str"

# initialize variables
home=$(cd $(dirname $0); pwd)
aws_cfn_doc_repo="${home}/aws-cloudformation-user-guide"
aws_cfn_doc_dir="${aws_cfn_doc_repo}/doc_source"

# update submodule(aws-cloudformation-user-guide)
git submodule foreach git pull origin main
mkdir -p "${home}/UltiSnips/"
rm -vrf "${home}"/UltiSnips/*


# main
cd "${aws_cfn_doc_dir}"
file_type=yaml
echo generating: $file_type
snip="${home}/UltiSnips/${file_type}.snippets"
# AWS Resource snippets
echo "### AWS Resource snippets" >> "${snip}"
for FILE in $(grep "^### ${file_type^^}" aws-resource* | awk -F: '{ print $1 }' | sort -u)
do
  name=$(sed -n 1P $FILE | sed -e 's/^# //g' -e 's/<a .*//g' -e 's/ /::/g' -e 's/\(.*\)/\L\1/' -e 's/::/-/g')
  echo $name
  echo "snippet $name" >> "${snip}"

  start=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==1 { print $1}')" + 1)
  end=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==2 { print $1}')" - 1)

  sed -ne "/^### ${file_type^^}/,\$p" "$FILE" \
    | sed -ne "${start},${end}p" \
    | sed -e "s/([^)]*)//g" \
    | sed -e "s/\[//g" -e "s/\]//g" >> "${snip}"
  echo -n "${endsnippet_str}" >> "${snip}"
  echo "" >> "${snip}"
  echo "" >> "${snip}"
done

echo ### Resource Properties snippets
echo "### Resource Properties snippets" >> "${snip}"
for FILE in $(grep "^### ${file_type^^}" aws-properties-* | awk -F: '{ print $1 }' | sort -u)
do
  name=$(sed -n 1P $FILE | sed -e 's/^# //g' -e 's/<a .*//g' -e 's/.* //g' )
  echo $name
  echo -n "snippet $name" >> "${snip}"
  echo "$FILE" | sed -e 's/aws-properties//g' -e 's/.md//g' >> "${snip}"

  start=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==1 { print $1}')" + 1)
  end=$(expr "$(sed -ne '/^### '${file_type^^}'/,$p' $FILE | grep -n '```' | awk -F: 'NR==2 { print $1}')" - 1)

  sed -ne "/^### ${file_type^^}/,\$p" "$FILE" \
    | sed -ne "${start},${end}p" \
    | sed -e "s/([^)]*)//g" \
    | sed -e "s/\[//g" -e "s/\]//g" >> "${snip}"
  echo -n "${endsnippet_str}" >> "${snip}"
  echo "" >> "${snip}"
  echo "" >> "${snip}"
done

    #| sed -e "s/^/  /g" \
    #| sed -e "s/^/  /g" \

# replace AWS::EC2::Instance as aws-ec2-instance for properities
sed -i -e '/snippet.*\:\:.*/{s/\(.*\)/\L\1/g;s/::/-/g}' ${home}/UltiSnips/yaml.snippets

# handle subtypes properly
# https://github.com/SirVer/ultisnips/issues/577
mv -v "${home}/UltiSnips/yaml.snippets" "${home}/UltiSnips/cloudformation.snippets" 

# for start
cat >> "${home}/UltiSnips/yaml.snippets" <<-EOS
snippet aws-start
AWSTemplateFormatVersion: "2010-09-09"
Description: A sample template
Resources:
  MyEC2Instance: # inline comment
    Type: "AWS::EC2::Instance"
    ...
${endsnippet_str}
EOS


