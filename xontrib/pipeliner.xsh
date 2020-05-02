import os

def _pl(args, stdin, stdout):
    fn = eval('lambda line, num:'+args[0])
    num = 0
    for line in stdin.readlines():
        res = fn(line.rstrip(os.linesep), num)
        num += 1
        print(res, file=stdout, flush=True)


aliases['pl'] = _pl
del _pl
