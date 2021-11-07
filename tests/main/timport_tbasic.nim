discard """
joinable: false
"""
import ./tbasic

var soa: MyObjSoA
soa.setLen(1)
assert soa.len == 1
soa[0].field1 = 3
assert soa[0].field1 == 3

var aos = newSeq[MyObj](10) 
for i in 0..<aos.len:
  aos[i] =  MyObj(field1: i, field2: i / 10, field3: @[i mod 2 == 0])

toMyObjSoA(aos, soa)
for i in 0..<aos.len:
  assert soa[i].toMyObj == aos[i]
