#!/bin/bash
# ./gitApi_create.sh /Users/comeontom/Desktop/testGit2 https://github.com/comeontom/testGit4.git fasdfa


set -e
echo "刚创建github时进行代码上传"

#参数获取
INDEX=0
for param in $*
do
  # echo $INDEX "--" $param
  array[$INDEX]=$param
  INDEX=$[ $INDEX+1 ]
done

path=${array[0]}
url=${array[1]}
describe=${array[2]}

if [ -z "$path" ]; then
  echo "请输入地址"
  exit 1
fi

if [ -z "$url" ]; then
  echo "请输入url"
  exit 1
fi

if [ -z "$url" ]; then
  $describe="describe"
fi

cd $path
git init
git add .
git commit -m "$describe"
git remote add origin $url
git push -u origin master
