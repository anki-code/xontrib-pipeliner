<p align="center">  
Easily process the lines using pipes in <a href="https://xon.sh">xonsh shell</a>. Multicore processing supported.
</p>

<p align="center">  
If you like the idea of pipeliner click ⭐ on the repo and stay tuned.
</p>


## Install
```
xpip install -U xontrib-pipeliner
echo 'xontrib load pipeliner' >> ~/.xonshrc
# Reload xonsh
```

## Use cases

### Python way to line modification
```
$ ls -1 / | head -n5
bin
boot
dev
etc
home

$ ls -1 / | head -n5 | pl "line + ' is here'" | head -n 3
bin is here
boot is here
dev is here
```

### Splitting
```
$ cat /etc/passwd | head -n 3
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin

$ cat /etc/passwd | head -n 3 | pl "line.split(':')[6]"
/bin/bash
/usr/sbin/nologin
/usr/sbin/nologin
```

### Imports
```
$ import re
$ cat /etc/passwd | head -n 3 | pl "re.sub('/bin/bash', '/usr/bin/xonsh', line)"
root:x:0:0:root:/root:/usr/bin/xonsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
```

### Arrays
```
$ cat /etc/passwd | head -n 3 | pl "line.split(':')" | grep nologin | pl "':'.join(eval(line)[::-1])"
/usr/sbin/nologin:/usr/sbin:daemon:1:1:x:daemon
/usr/sbin/nologin:/bin:bin:2:2:x:bin
```

### Operations chaining (Python 3.8)
Expression is lambda function and chaining of operations in Python 3.8 looks as:
```
$ ls -1 / | head -n3 | pl "[s:='b', line.replace(s, s.upper()+')')][-1]"
B)in
B)oot
dev
```

### Line number
```
$ ls -1 / | head | pl "'*'*len(line) if num%3 == 0 else line"
***
boot
dev
***
home
initrd.img
**************
lib
lib32
*****
```

### Getting lines from pipe and execute new command with the line
Getting the size of three directories from `ls` command:
```
$ ls / | head -n 3 | pl "execx('du -sh /'+line) or 'Done command with /'+line"
0       /bin
Done command with /bin
840M    /boot
Done command with /boot
4,0K    /cdrom
Done command with /cdrom
```

### Multicore pipelining
By default pipeliner works using one CPU core. To use them all in parallel try `ppl` command:
```
$ head /etc/passwd | ppl "str(num) + ' ' + line.split(':')[0]"                                                                                                                                                                         
1 daemon
0 root
2 bin
4 sync
5 games
8 mail
9 news
6 man
7 lp
3 sys
```
Note! The order of result lines is unpredictable because lines will be processed in parallel. 
The `num` variable contains the real line number. 

### How to avoid Python code as a string
To avoid writing Python inside string and get syntax highlighting there is a tricky way with using [xonsh macro](https://xon.sh/tutorial_macros.html):
```python
def py(code):
    return code

echo 123 | pl @(py!(line + '2'))
```

## Thanks
* @laloch in https://github.com/xonsh/xonsh/issues/3366
