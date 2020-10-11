import os, sys, traceback, ast
from xontrib.pipeliner_parallel import PipelinerParallel
from xonsh.tools import print_color
from xontrib_pipeliner_asttokens import asttokens

def _pl(args, stdin, stdout):
    err = False
    if len(args) == 0:
        print('Error: Python code not found', file=sys.stderr)
        err = True
    if err:
        print('Usage: <command> | <command> | ... | pl "<Python code>"', file=sys.stderr)
        print('Example: echo "123" | pl "line[::-1]"', file=sys.stderr)
        return

    fn = eval('lambda line, num:'+args[0], __xonsh__.ctx)

    if stdin is None:
        try:
            print(fn(None, 0))
        except:
            print_color('{YELLOW}' + str(traceback.format_exc()), file=sys.stderr)
        return

    num = 0
    for line in stdin.readlines():
        try:
            res = fn(line.rstrip(os.linesep), num)
        except:
            print_color('{YELLOW}' + f'Error line {num+1}: {line}', file=sys.stderr)
            print_color('{YELLOW}' + str(traceback.format_exc()), file=sys.stderr)
            return
        num += 1
        if res is not None:
            print(res, file=stdout, flush=True)


def _ppl(args, stdin, stdout):
    err = False
    if stdin is None:
        print('Error: Command output not found', file=sys.stderr)
        err = True
    elif len(args) == 0:
        print('Error: Python code not found', file=sys.stderr)
        err = True
    if err:
        print('Usage: <command> | <command> | ... | ppl "<Python code>"', file=sys.stderr)
        print('Example: echo "123" | ppl "line[::-1]"', file=sys.stderr)
        return

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

#
# Experimental
#

aliases['plx'] = lambda a,i,o: aliases['pl']([f'print(f"{a[0]}") or execx(f"{a[0]}")'], i, o)
aliases['pplx'] = lambda a,i,o: aliases['ppl']([f'print(f"{a[0]}") or execx(f"{a[0]}")'], i, o)


@events.on_transform_command
def on_transform_command_pipeliner(cmd, **kw):
    prefix = 'pl @('
    if cmd.strip() and "| "+prefix in cmd:
        try:
            atok = asttokens.ASTTokens(
                tree=__xonsh__.execer.parse(cmd, ctx=__xonsh__.ctx),
                source_text=cmd,
                parse=False,
                mark_node_specific_methods=False
            )
        except Exception:
            return cmd
        nodes = {}
        for node in ast.walk(atok.tree):
            if hasattr(node, 'lineno'):
                nodes[atok.get_text(node)] = atok.get_text_range(node)

        for n, pos in nodes.items():
            if n.startswith(prefix) and n.endswith(')'):
                start, end = pos
                cmd = cmd[:start] + 'pl ' + repr(n[len(prefix):-1]) + cmd[end:]
        return cmd
    return cmd
