# Array of Structures to Structure of Arrays


This library allows to generate a SoA (Structure of Arrays) type from a Nim object, and use
 syntax like ``a[i].field`` on it as if it were an AoS (Array of Structures).


![Github Actions](https://github.com/guibar64/aossoa/workflows/Github%20Actions/badge.svg)


## Installation

With nimble:
```
nimble install https://github.com/guibar64/aossoa
```

Or in a .nimble file put the line:
```
requires "https://github.com/guibar64/aossoa"
```


## Example

We start from an object ``MyObj``
```nim
type
  MyObj = object
    field1: int
    field2: float

var aos = @[MyObj(field1: 1, field2: 1.2), MyObj(field1: 2, field2: 2.1)]
echo aos[1].field2 # 2.1
```

and define an SoA
```nim
import aossoa
declareSoA(MyObj, MyObjSoA)

var soa: MyObjSoA
soa.setLen(2)
soa[1].field1 = 2
echo soa[1].field2, " ", soa.field2[1] # 2 2
```

The macro ``declareSoA``  expands conceptually to
```nim
type
  MyObjSoA = object
    field1: seq[int]
    field2: seq[float]

template `[]`(s: MyObjSoA, i: int): IntermediateType

macro field1(temp: IntermediateType): int
macro field1(temp: IntermediateType): float

proc setLen(s: MyObjSoA, len: int)
  ## (re)sets all internal arrays

proc len(s: MyObjSoA, len: int)
  ## shared len of internal arrays

proc toMyObjSoA(s: MyObjSoA, a: sink openArray[MyObj])
  ## converts an array of MyObj to its SoA representation

proc toMyObj(temp: IntermediateType, a: sink openArray[MyObj])
  ## converts an array of MyObj to its SoA representation

```

Note that ``s[i].field`` is transformed at compile-time to ``s.field[i]`` `ÌntermediateType`` is “consumed” by the macros.

One can converts from Aos to SoA with the generated proc ``to${SoAType}``:
```nim
let soa = toMyObjSoA(aos)
```

Due to the current implementation, “naked” indexing ``soa[i]``  is meaningless and gives a compile-time error on purpose. 
To get a value of the type of the original object as one could expect wrap it like this:
```nim
echo soa[i].toMyObj
``` 

Note also that ``declareSoA`` exports the generated type to the world,
one can ``declareSoAPrivate`` to limit its scope to the current module

Currently, only plain non-generic objects are supported.

## License

MIT