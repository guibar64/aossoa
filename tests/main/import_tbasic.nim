import ./tbasic

var soa: MyObjSoA
soa.setLen(1)
soa[0].field1 = 3
assert soa[0].field1 == 3
