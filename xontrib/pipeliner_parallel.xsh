import sys, traceback
from multiprocessing import Pool, cpu_count
from xonsh.tools import print_color

class PipelinerParallel(object):
   def __init__(self, code):
       self.code = code

   def f(self, args):
       ctx = __xonsh__.ctx
       ctx['line'] = args[0]
       ctx['num'] = args[1]
       try:
           return eval(self.code, ctx)
       except:
           print_color('{YELLOW}' + f'Error line {args[1]+1}: {args[0]}', file=sys.stderr)
           print_color('{YELLOW}' + str(traceback.format_exc()), file=sys.stderr)           
           return None

   def go(self, func_args, stdout):
       with Pool(cpu_count()) as p:
           parallel_tasks = p.imap_unordered(self, func_args)
           for result in parallel_tasks:
               if result is not None:
                   print(result, file=stdout, flush=True)

   def __call__(self, x):
     return self.f(x)

if __name__ == '__main__':
    import sys
    ppl = PipelinerParallel("'this is parallel ' + line", globals())
    lines = []
    for num in range(0,10):
        lines.append([f'test line {num}', num])
    ppl.go(lines, sys.stdout)
