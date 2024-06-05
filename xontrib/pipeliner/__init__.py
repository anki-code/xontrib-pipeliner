"""Let your pipe lines flow thru the Python code in xonsh. """

import os
import sys
import traceback
import ast
from xontrib.pipeliner.parallel import PipelinerParallel
from xonsh.tools import print_color
from xontrib_pipeliner_asttokens import asttokens

def _preset_drop(line, num, args):
    """Drop empty lines."""
    if args:
        return None if line == args[0] else line
    else:
        return line if line.strip() else None

def _preset_fromlist(line, num, args):
    """Read python list representation and return the element by index."""
    lst = eval(line)
    if lst:
        if args:
            n = int(args[0])
            return lst[n] if n >= 0 and n < len(lst) else ""
        return str(lst[0])
    else:
        return ""

_default_presets = {
    "drop": _preset_drop,
    "len": "len(line)",
    "strip": "line.strip()",
    "lstrip": "line.lstrip()",
    "rstrip": "line.rstrip()",
    "split": lambda line, num, args: line.split(args[0] if args else None),
    "fromlist": _preset_fromlist,
    "lower": "line.lower()",
    "upper": "line.upper()",
    "title": "line.title()",
    "startswith": lambda line, num, args: line.startswith(args[0]),
    "endswith": lambda line, num, args: line.endswith(args[0]),
}

def _pl(args, stdin, stdout):
    err = False
    if len(args) == 0:
        print('Error: Python code not found', file=sys.stderr)
        err = True

    presets = {**_default_presets, **__xonsh__.env.get('XONTRIB_PIPELINER_PRESETS', {})}
    if err:
        print('Usage: <command> | <command> | ... | pl "<Python code or preset name>"\n'
            + 'Example: echo "123" | pl "line[::-1]"\n'
            + 'Example: echo " 123 " | pl strip\n'
            + 'Presets:\n' + '\n'.join(f"  {p}: {repr(v) if type(v) is str else (getattr(v, '__doc__', 'func') or 'func')}" for p,v in presets.items())
        , file=sys.stderr)
        return

    if args[0] in presets:
        preset = presets[args[0]]
        if callable(preset):
            fn = preset
        elif isinstance(preset, str):
            fn = eval('lambda line, num, args:'+preset, __xonsh__.ctx)
        else:
            print_color('{YELLOW}'+f'Unsupported type: {preset!r}'+'{RESET}', file=sys.stderr)
            return
    else:
        fn = eval('lambda line, num, args:'+args[0], __xonsh__.ctx)

    fn_args = args[1:]
    
    if stdin is None:
        try:
            print(fn(None, 0, fn_args))
        except:
            print_color('{YELLOW}' + str(traceback.format_exc()) + '{RESET}', file=sys.stderr)
        return

    num = 0
    for line in stdin.readlines():
        try:
            res = fn(line.rstrip(os.linesep), num, fn_args)
        except Exception as e:
            print_color('{YELLOW}' + f'Error line {num+1}: {line!r}: {e}' + '{RESET}', file=sys.stderr)
            # print_color('{YELLOW}' + str(traceback.format_exc()) + '{RESET}', file=sys.stderr)
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

aliases['plx'] = lambda a,i,o: aliases['pl']([f'print(f"{a[0]}", file=sys.stderr) or execx(f"{a[0]}")'], i, o)
aliases['pplx'] = lambda a,i,o: aliases['ppl']([f'print(f"{a[0]}", file=sys.stderr) or execx(f"{a[0]}")'], i, o)


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
