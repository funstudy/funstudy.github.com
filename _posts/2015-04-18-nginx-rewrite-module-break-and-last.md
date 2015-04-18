---
layout: post
title:  "nginx重写模块last和break区别"
date:   2015-04-18 23:18:12
---

在使用nginx重写(rewrite)机制时,经常会看到last和break, 这两个指令有什么作用了
===

网友的给力解释：

* last：重新将rewrite后的地址在server标签中执行
* break：将rewrite后的地址在当前location标签中执行

nginx官方解释：
> * last：
stops processing the current set of  ngx_http_rewrite_module directives followed by a search for a new location matching     
    the changed URI;
* break：
    stops processing the current set of  ngx_http_rewrite_module directives;

其实网友的解释更容易懂一些，nginx官方的解释则是从偏重实现的角度来说的，说到这里，许多人可能还是对这两个指令的使用不是太自信，感觉心里没底，说实话我当初也是这么感觉的，那么就让我们打破沙锅问到底，看看代码到底是怎么实现的，毕竟，”代码面前无秘密“。
为了方便我们的讨论我们做出以下的假想配置：

	location /download/ { 
	    rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3 break;
	    rewrite ^(/download/.*)/audio/(.*)\..*$ $1/mp3/$2.ra  break;
	    return  403;
	}
	
在分析之前，看官们需要熟悉nginx各个phase handler的处理，以及nginx变量的基本原理，不熟悉的同学看起来可能会有点难度，那么这里给出了相关的连接，方面不熟悉的同学学习。前两个是关于handler的，后一个是关于变量的：

* http://simohayha.iteye.com/blog/670326
* http://simohayha.iteye.com/blog/679314
* http://blog.lifeibo.com/?p=346

现在进入正题：
在函数ngx_http_rewrite中：

	if (cf->args->nelts == 4) {
        if (ngx_strcmp(value[3].data, "last") == 0) {
            last = 1;
 
        } else if (ngx_strcmp(value[3].data, "break") == 0) {
            regex->break_cycle = 1;
            last = 1;
 
        }  
        ...// 其余处理省略
	}
重点在于last = 1的处理，在稍后：

	if (last) {
	    code = ngx_http_script_add_code(lcf->codes, sizeof(uintptr_t), ®ex);
	    if (code == NULL) {
	        return NGX_CONF_ERROR;
	    }
 
 	   *code = NULL;
	}
lcf->codes是个数组里面保存了当前各个rewrite执行对应的相关操作(即各种handler)和数据，这里的操作是在这个数组中添加一个null，这个null的意义重大，在rewrite实际执行时，如ngx_http_rewrite_handler的调用，就会对事先放置在这个数组里的handler进行处理：lcf->codes是个数组里面保存了当前各个rewrite执行对应的相关操作(即各种handler)和数据，这里的操作是在这个数组中添加一个null，这个null的意义重大，在rewrite实际执行时，如ngx_http_rewrite_handler的调用，就会对事先放置在这个数组里的handler进行处理：

	e->ip = rlcf->codes->elts;
	...
	// 在这个while循环中，上面的那个null，就会终止rewrite一系列操作的执行
	// 可以看到，“last”和“break”在这点上作用是相同的，当前codes数组中有剩余的
	// rewrite指令，那么由于这里的null的存在，也就跳过不管了。
	while (*(uintptr_t *) e->ip) {
	    code = *(ngx_http_script_code_pt *) e->ip;
	    code(e);
	}
比如在开始的配置里面，我们写成：

	location /download/ {
	    rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3;
	    rewrite ^(/download/.*)/audio/(.*)\..*$ $1/mp3/$2.ra;
	    return  403;
	}
即不写last和break，那么流程就是依次执行这些rewrite，直到最后以403结束这次请求，这种情况下codes数组中的handler都得以执行了，而由于
last和break的出现，处理可能在中间的某个位置终止，后面的rewrite，就不会执行了。

在rewrite阶段的处理结束之后，则会转到find config阶段，这个阶段本来是在rewrite阶段之前的，这样的过程也刻画了rewrite的基本流程，url经过rewrite阶段被改变了，而一个请求处理的关键步骤之一就是要确定对应的server conf和location conf，而find config的作用恰恰就是如此，重写之后url可以看做是一个新的请求，所以这些关键步骤需要走一遍就是理所当然了。

另一个问题，在ngx_http_rewrite函数中break_cycle的设置，也就是在出现break的时候，这个变量会被置1，而这个变量的设置，最终会导致r->uri_changed被置为0，那么它的直接影响可以在下面的地方看到：

	// 这个函数之所以名为“post”，意思就是为rewrite处理做一些善后工作
	ngx_http_core_post_rewrite_phase
	{   
	    // 在通常情况下，即r->uri_changed > 0，r->phase_handler会设置为ph->next，
	    // 而这个ph->next，在开始初始化phase的时候，已经设置为ph->next = 	find_config_index，
	    // 所以在非break或者last情况下，之后的phase就是所谓find config阶段了，而这里却是
	    // r->phase_handler++，意味着将会执行接下来的处理，不会再去走find config的过程了
	    if (!r->uri_changed) {
 	       r->phase_handler++;
 	       return NGX_AGAIN;
 	   }
	    ... // 此处省略其他处理部分
	}
关于r->uri_changed被置为0的操作，可以参考：

ngx_http_script_regex_start_code和ngx_http_script_break_code

所以这里概括下：

last其实就相当于一个新的url，对nginx进行了一次请求，需要走一遍大多数的处理过程，最重要的是会做一次find config，提供了一个可以转到其他location的配置中处理的机会，

而break则是在一个请求处理过程中将原来的url(包括uri和args)改写之后，在继续进行后面的处理，这个重写之后的请求始终都是在同一个location中处理。