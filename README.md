<p align="center">  
Easily process the lines using pipes in <a href="https://xon.sh">xonsh shell</a>. Multicore processing supported.
</p>

<p align="center">  
If you like the idea of pipeliner click ⭐ on the repo and <a href="https://twitter.com/intent/tweet?text=Nice%20xontrib%20for%20the%20xonsh%20shell!&url=https://github.com/anki-code/xontrib-pipeliner" target="_blank">tweet</a>.
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

#### Experimental features

* `ppl` is to run multicore `pl`. It tested mostly on Linux. See "Known issues" section.
* `plx` is the shorter way to execute the commands with pipe lines i.e. `ls /home | plx 'du -sh /home/{line}'`.

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

## Presets

There are default presets:
```xsh
echo "  1" | pl strip
# 1

echo "1,2,3" | pl split ,
['1', '2', '3']

echo "a,b,c" | pl split , | pl list 0
# a
```

You can set your own presets:
```xsh
$XONTRIB_PIPELINER_PRESETS = {
    "upper": "line.upper()",
    "repeat": lambda args: f"line*int({repr(args[0])})"
}

echo 'hello' | pl upper
# HELLO

echo 'hey \nhi ' | pl repeat 3
# hey hey hey
# hi hi hi
```

## Wrap pipeliner to get your own magic
```python
aliases['my_lovely_pl'] = lambda a,i,o: aliases['pl'](["'My lovely ' + "+a[0]], i, o)
aliases['my_parallel_ppl'] = lambda a,i,o: aliases['ppl'](["'My parallel ' + "+a[0]], i, o)
```
```bash
ls / | head -n 3 | my_lovely_pl "line + '!'"
# My lovely bin!
# My lovely boot!
# My lovely cdrom!

ls / | head -n 3 | my_parallel_ppl "line + '!'"
# My parallel boot!
# My parallel cdrom!
# My parallel bin!
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
mkdir -p /tmp/plx-test && cd /tmp/plx-test
touch 111 222 333 && ls
# 111 222 333

ls | plx "mv {line} prefix-{line}"
# mv 111 prefix-111
# mv 222 prefix-222
# mv 333 prefix-333

ls
# prefix-111 prefix-222 prefix-333
```
Echo example:
```bash
ls | plx 'echo {line} # {num}'
# echo prefix-111 # 0
# prefix-111
# echo prefix-222 # 1
# prefix-222
# echo prefix-333 # 2
# prefix-333
```

### Pipeliner in xsh scripts
By default xsh scripts haven't rc-file with xontribs loading. To add pipeliner to your script just do `xontrib load pipeliner` before usage.

## Known issues in experimental functions

### plx: "Bad file descriptor" on huge amount of lines

https://github.com/xonsh/xonsh/issues/4224

### ppl: [On MacOS global variables are not accessible from child processes](https://bugs.python.org/issue39931) in multicore pipelining

On Mac you can't access to the xonsh context (global variables and functions) in the expression. PR is welcome!

### ppl: On MacOS multicore pipelining freezes on end

Workaround is to add `cat` at the end: `echo 1 | ppl 'line' | cat`. PR is welcome!

## Future

Pipeliner should be a part of xonsh and has shortcut and syntax highlighting. For example:
```python
echo 'Pipeliner should be ' | pl @{line + 'a part of xonsh!'}
# or
echo 'Pipeliner should be ' | ~(line + 'a part of xonsh!')
```
```
Pipeliner should be a part of xonsh!
```

If you want to support this in xonsh add your Like and support message to [Python code substitution in subproc mode](https://github.com/xonsh/xonsh/issues/3945).

## Links 
* This package is the part of [rc-awesome](https://github.com/anki-code/xontrib-rc-awesome) - awesome snippets of code for xonshrc in xonsh shell.
* This package is the part of [ergopack](https://github.com/anki-code/xontrib-ergopack) - the pack of ergonomic xontribs.
* This package was created with [xontrib cookiecutter template](https://github.com/xonsh/xontrib-cookiecutter).
