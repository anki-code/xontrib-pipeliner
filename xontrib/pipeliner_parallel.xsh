from multiprocessing import Pool, cpu_count

class PipelinerParallel(object):
   def __init__(self, code):
       self.code = code

   def f(self, args):
       line, num = args
       return eval(self.code, __xonsh__.ctx, locals())

   def go(self, func_args, stdout):
       with Pool(cpu_count()) as p:
           parallel_tasks = p.imap_unordered(self, func_args)
           for result in parallel_tasks:
               print(result, file=stdout, flush=True)

   def __call__(self, x):
     return self.f(x)

if __name__ == '__main__':
    import sys
    ppl = PipelinerParallel("'this is parallel ' + line")
    lines = []
    for num in range(0,10):
        lines.append([f'test line {num}', num])
    ppl.go(lines, sys.stdout)