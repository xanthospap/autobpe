#! /bin/bash

echo "Hallo from bash!"

python - <<END
class Foo:

  def __init__(self, i=1):
    self.__i = i

  def bar(self):
    print 'function bar:', str(self.__i)

  def fun(self):
    print 'function fun:', str(self.__i + 10)

mf_dict = { 'f1': Foo.bar, 'f2': Foo.fun }

def use_member_fun(f_str='f1'):
  f = Foo(5)
  mf_dict[f_str](f)

use_member_fun()
END

echo "Exit from Python ok!"
exit 0
