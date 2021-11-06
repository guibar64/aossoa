discard """
  matrix: "--gc:refc; --gc:orc"
"""
import aossoa

type
  MyObj* = object
    field1*: int
    field2*: float
    field3*: seq[bool] 

var aos = newSeq[MyObj](10) 
for i in 0..<aos.len:
  aos[i] =  MyObj(field1: i, field2: i / 10, field3: @[i mod 2 == 0])

declareSoA(MyObj, MyObjSoA)
var soa = toMyObjSoA(aos)
assert soa.len == aos.len

for i in 0..<aos.len:
  assert soa[i].field1 == aos[i].field1
  assert soa[i].field2 == aos[i].field2
  assert soa[i].field3 == aos[i].field3
  assert soa[i].toMyObj == aos[i]

soa[0].field1 = 3
assert soa[0].field1 == 3


block:  
  declareSoAPrivate(MyObj, MyObjSoA)
  var soa = toMyObjSoA(aos)
  assert soa.len == aos.len
  for i in 0..<aos.len:
    assert soa[i].field1 == aos[i].field1
    assert soa[i].field2 == aos[i].field2
    assert soa[i].field3 == aos[i].field3
    assert soa[i].toMyObj == aos[i]

  soa[0].field1 = 3
  assert soa[0].field1 == 3
