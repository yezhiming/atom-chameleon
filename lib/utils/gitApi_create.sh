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
# username=${array[2]}
# password=${array[3]}
describe=${array[2]}


echo "path:$path"
echo "url:$url"
echo "describe:$describe"

if [ -z "$path" ]; then
  echo "请输入地址"
  exit 1
fi

if [ -z "$url" ]; then
  echo "请输入url"
  exit 1
fi

if [ -z "$describe" ]; then
  describe="describe"
fi

cd $path
# touch ~/.git-credentials 777 && echo https://$username:$password@github.com > ~/.git-credentials
# git config --global credential.helper store
# git config --global credential.helper osxkeychain
git init
git add .
git commit -m "$describe"
git remote add origin $url
git push -u origin master
