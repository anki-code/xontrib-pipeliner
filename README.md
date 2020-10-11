<p align="center">  
Easily process the lines using pipes in <a href="https://xon.sh">xonsh shell</a>. Multicore processing supported.
</p>

<p align="center">  
If you like the idea of pipeliner click ⭐ on the repo and stay tuned.
</p>


## Install
```bash
xpip install -U xontrib-pipeliner
echo 'xontrib load pipeliner' >> ~/.xonshrc
# Reload xonsh
```

## Usage
Let your pipe lines flow thru the Python code:
```bash
<cmd> | ... | pl "<lambda expression>" | <cmd> | ...
```
There are two variables available in lambda expression:
* `line` from pipe.
* `num` of the line starts with 0.

#### Experimental features:
* `ppl` is to run multicore `pl`.
* `plx` is the shorter way to execute the commands with pipe lines.

## Examples

### Python way to line modification
```bash
ls -1 / | pl "line + ' is here'" | head -n 3
```
```
bin is here
boot is here
dev is here
```

### Line number
```bash
ls -1 / | head -n 4 | pl "f'{num} {line}'"
```
```
0 bin
1 boot
2 cdrom
3 dev
```

### Ignore line
```bash
$ ls -1 / | head -n 4 | pl "f'{num} {line}' if num%2 == 0 else None"
```
```
0 bin
2 cdrom
```

### Splitting
```bash
cat /etc/passwd | head -n 3 | pl "line.split(':')[6]"
```
```
/bin/bash
/usr/sbin/nologin
/usr/sbin/nologin
```

### Imports
```bash
import re
cat /etc/passwd | head -n 3 | pl "re.sub('/bin/bash', '/usr/bin/xonsh', line)"
```
```
root:x:0:0:root:/root:/usr/bin/xonsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
```

### Arrays
```bash
cat /etc/passwd | head -n 3 | pl "line.split(':')" | grep nologin | pl "':'.join(eval(line)[::-1])"
```
```
/usr/sbin/nologin:/usr/sbin:daemon:1:1:x:daemon
/usr/sbin/nologin:/bin:bin:2:2:x:bin
```

### Python head
```bash
pl "'\\n'.join(list('ABCDEFG'))" | pl "line + ('!' if num%2 else '?')" | grep '!'
```
```
B!
D!
F!
```

### Variables and operations chaining
Expression is a lambda function so using variables and operations chaining since Python 3.8+ are available by trick with the walrus operator and the list:
```bash
ls -1 / | head -n3 | pl "[s:='b', line.replace(s, s.upper()+')')][-1]"
```
```
B)in
B)oot
dev
```

### Execute command with the line
```bash
ls / | head -n 3 | pl "execx('du -sh /'+line) or 'Done command with /'+line"
```
```
0       /bin
Done command with /bin
840M    /boot
Done command with /boot
4,0K    /cdrom
Done command with /cdrom
```
Note! If you do the operations with files (i.e. `pl "execx(f'mv {line} prefix-{line}')"`) you could catch `TypeError: an integer is required` error that relates to wrong access rights to files. Fix it with `chmod` and `chown` before pipelining.

## Wrap pipeliner to get your own magic
```python
aliases['my_lovely_pl'] = lambda a,i,o: aliases['pl'](["'My lovely ' + "+a[0]], i, o)
aliases['my_parallel_ppl'] = lambda a,i,o: aliases['ppl'](["'My parallel ' + "+a[0]], i, o)
```
```bash
$ ls / | head -n 3 | my_lovely_pl "line + '!'"
My lovely bin!
My lovely boot!
My lovely cdrom!

$ ls / | head -n 3 | my_parallel_ppl "line + '!'"
My parallel boot!
My parallel cdrom!
My parallel bin!
```
Add your most useful solutions to xontrib-pipeliner. PRs are welcome!

## Experimental

### Syntax highlighting using xonsh prompt

If you're using xonsh prompt and want to use pipeliner with syntax highlighting instead of string there is experimental 
feature that catch `pl @(<python>)` calls and uses the expression from the xonsh python substitution as pipeliner argument.
Example:

```bash
echo echo | pl @(line + '!')
# In the xonsh prompt it's equals to:
echo echo | pl "line + '!'" 
```

### Syntax highlighting using xonsh macros
To avoid writing Python inside the string and get the syntax highlighting there is a tricky way with using [xonsh macro](https://xon.sh/tutorial_macros.html):
```python
def py(code):
    return code

echo 123 | pl @(py!(line + '2'))
```

### Multicore pipelining
By default pipeliner works using one CPU core. To use them all in parallel try `ppl` command:
```bash
head /etc/passwd | ppl "str(num) + ' ' + line.split(':')[0]"
```
```
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

### Pipeliner exec
There are `plx` and `pplx` commands to run `execx(f"{plx_command}")` most shorter way.

For example when you want to rename files you can do it Pythonic way:
```bash
$ mkdir -p /tmp/plx-test && cd /tmp/plx-test
$ touch 111 222 333 && ls
111 222 333

$ ls | plx "mv {line} prefix-{line}"
mv 111 prefix-111
mv 222 prefix-222
mv 333 prefix-333

$ ls
prefix-111 prefix-222 prefix-333
```
Echo example:
```bash
$ ls | plx 'echo {line} # {num}'
echo prefix-111 # 0
prefix-111
echo prefix-222 # 1
prefix-222
echo prefix-333 # 2
prefix-333
```

## Pipeliner in xsh scripts
By default xsh scripts haven't rc-file with xontribs loading. To add pipeliner to your script just do `xontrib load pipeliner` before usage.

## Future

Pipeliner should be a part of xonsh and has shortcut and syntax highlighting. For example:
```bash
echo 'Pipeliner should be ' | @{line + 'a part of xonsh!'}
```
```
Pipeliner should be a part of xonsh!
```
