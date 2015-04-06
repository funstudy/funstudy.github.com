---
layout: post
title:  "Git Summary"
date:   2015-04-06 22:19:00
categories: bryan update
---
git summary test doc


git init

1.项目克隆到本地
	git clone git://git.kernel.org/pub/scm/git/git.git
 2.设置自己的账号

	当前目录设置git 帐号

	git config user.name “BRYAN”

	git config  user.email nyd111@qq.com



	全局设置git帐号

	git config --global user.name "John Doe"

	git config --global user.email johndoe@example.com



3.添加新文件

	git add README

4.看暂存前后的变化

	git diff

 5.提交更新

	git commit

6.移除文件

 	git rm grit.gemspec

7.移除跟踪但不删除文件

	git rm --cached readme.txt

	git rm log/\*.log



8. 移动文件

	git mv file_from file_to

 9.查看提交历史

 	git	log

	git log -p 查看两次提交的对比信息

	git log -p -2



10.上传

	git commit -m 'initial commit’

	git add forgotten_file

	git commit --amend

 11.可以使用 git reset HEAD <file>... 的方式取消暂存

 	git reset HEAD benchmarks.rb

12.推送数据到远程仓库

	 git push [remote-name] [branch-name]

	如果要把 本地的 master 分支推送到 origin 服务器上(再次说明下,克隆操作会自动使用默认的 master 和 origin 名字),可以运行下面的命令

 13.查看远程仓库信息

	git remote show origin

 14.git push [remote-name] [branch-name]。如果要把 本地的 master 分支推送到 origin 服务器上

	git push origin master


mutual encouragement！！！


