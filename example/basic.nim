import aossoa

type
  MyObj = object
    field1: int
    field2: float

var aos = @[MyObj(field1: 1, field2: 1.2), MyObj(field1: 2, field2: 2.1)]
echo aos[1].field2 # 2.1

declareSoA(MyObj, MyObjSoA)

var soa: MyObjSoA
soa.setLen(2)
soa[0].field1 = 1
soa[0].field2 = 1.2
soa[1].field1 = 2
soa[1].field2 = 2.1
echo soa.field1[1], " ", soa.field1[1] # 2 2

let soa2 = toMyObjSoA(aos)
echo soa2[1].toMyObj # (field1: 2, field2: 2.1)
