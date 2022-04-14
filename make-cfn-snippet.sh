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

mv -v "${home}/UltiSnips/yaml.snippets" "${home}/UltiSnips/yaml_cloudformation.snippets" 

cat >> "${home}/UltiSnips/yaml.snippets" <<-EOS
snippet AWSTemplateFormatVersion
AWSTemplateFormatVersion: "2010-09-09"
Description: A sample template
Resources:
  MyEC2Instance: # inline comment
    Type: "AWS::EC2::Instance"
    ...
${endsnippet_str}
EOS


