import os
from xontrib.pipeliner_parallel import PipelinerParallel

def _pl(args, stdin, stdout):
    fn = eval('lambda line, num:'+args[0], __xonsh__.ctx)
    num = 0
    for line in stdin.readlines():
        try:
            res = fn(line.rstrip(os.linesep), num)
        except:
            print(f'Error line {num+1}: {line}', file=sys.stderr)
            raise
        num += 1
        print(res, file=stdout, flush=True)


def _ppl(args, stdin, stdout):
    batch_size = 1000
    func_args = []
    num = 0
    for line in stdin.readlines():
        func_args.append([line.rstrip(os.linesep), num])
        num += 1

        if num % batch_size == 0:
            xppl = PipelinerParallel(args[0])
            xppl.go(func_args, stdout)
            func_args = []

    if func_args:
        xppl = PipelinerParallel(args[0])
        xppl.go(func_args, stdout)


aliases['pl'] = _pl
aliases['ppl'] = _ppl
del _pl, _ppl
