import macros

# Needed for the gen'ed field macros
export macros.newTree, macros.newAssignment

type
  NakedIndexingIsForbidden = object

template declareSoAField(T, field, Tfield: untyped) =
  macro field*(o: (T, int, NakedIndexingIsForbidden)): untyped =
    expectKind(o, nnkTupleConstr)
    result = nnkBracketExpr.newTree(nnkDotExpr.newTree(o[0], ident astToStr(field)), o[1])

  macro `field=`*(o: (T, int, NakedIndexingIsForbidden), val: Tfield): untyped =
    expectKind(o, nnkTupleConstr)
    let lval = nnkBracketExpr.newTree(nnkDotExpr.newTree(o[0], ident astToStr(field)), o[1])
    result = newAssignment(lval, val)

template declareSoAFieldPrivate(T, field, Tfield: untyped) =
  macro field(o: (T, int, NakedIndexingIsForbidden)): untyped =
    expectKind(o, nnkTupleConstr)
    result = nnkBracketExpr.newTree(nnkDotExpr.newTree(o[0], ident astToStr(field)), o[1])

  macro `field=`(o: (T, int, NakedIndexingIsForbidden), val: Tfield): untyped =
    expectKind(o, nnkTupleConstr)
    let lval = nnkBracketExpr.newTree(nnkDotExpr.newTree(o[0], ident astToStr(field)), o[1])
    result = newAssignment(lval, val)

template declareSoAaccessors(T: untyped, f1: untyped) =
 
  template `[]`*(s: T , i: int): (T, int, NakedIndexingIsForbidden) = (s, i, NakedIndexingIsForbidden()) 
  proc len*(s: T): int = s.f1.len

template declareSoAaccessorsPrivate(T: untyped, f1: untyped) =
 
  template `[]`(s: T , i: int): (T, int, NakedIndexingIsForbidden) = (s, i, NakedIndexingIsForbidden()) 
  proc len(s: T): int = s.f1.len


template declareSoASetLen(s, newLen, T, body: untyped) =
  proc setLen*(s: var T, newLen: int) = body

template declareSoASetLenPrivate(s, newLen, T, body: untyped) =
  proc setLen(s: var T, newLen: int) = body


template declareSoAToSoA(s, old, j, T, oldT, body: untyped) =
  proc `to T`*(old: sink openArray[oldT], s: var T) = 
    setLen(s, old.len)
    for i in 0..<old.len:
      let j = i
      body
  proc `to T`*(old: sink openArray[oldT]): T = `to T`(old, result) 

template declareSoAToSoAPrivate(s, old, j, T, oldT, body: untyped) =
  proc `to T`(old: sink openArray[oldT], s: var T) = 
    setLen(s, old.len)
    for i in 0..<old.len:
      let j = i
      body
  proc `to T`(old: sink openArray[oldT]): T = `to T`(old, result) 


template declareSoAtoOldT(s, old, T, oldT, toOldT, body: untyped) =
  template toOldT*(s: (T, int, NakedIndexingIsForbidden)): oldT =
    var old: oldT
    body
    old

template declareSoAtoOldTPrivate(s, old, T, oldT, toOldT, body: untyped) =
  template toOldT(s: (T, int, NakedIndexingIsForbidden)): oldT =
    var old: oldT
    body
    old


proc declareSoAImpl(T, newT: NimNode, exported: bool): NimNode =
  let rec = T.getImpl[2][2]
  var fields: seq[tuple[f: NimNode, typ: NimNode, exported: bool]]
  for c in rec.items:
    if c.kind == nnkIdentDefs:
        for i in 0..<c.len-2:
          fields.add ((if c[i].kind == nnkPostFix: c[i][1] else: c[i]), c[^2], c[i].kind == nnkPostFix)
  if fields.len > 1:

    let newRec = nnkRecList.newTree()
    for f in fields:
      newRec.add nnkIdentDefs.newTree(if exported and f.exported: nnkPostFix.newTree(ident"*", f[0]) else: f[0], nnkBracketExpr.newTree(ident("seq"), f[1]), newEmptyNode())
    result = newStmtList()
    result.add nnkTypeSection.newTree(
      nnkTypeDef.newTree(
        newT,
        newEmptyNode(),
        nnkObjectTy.newTree(newEmptyNode(), newEmptyNode(), newRec)
      )
    )
    var setLenBody, toSoABody, toOldTBody = newStmtList()
    let paramId = ident"s"
    let newLenId = ident"newLen"
    let oldId = ident"old"
    let iId = ident"j"
    for f in fields:
      result.add  (if exported and f.exported: getAst declareSoAField(newT, f[0], f[1]) else: getAst declareSoAFieldPrivate(newT, f[0], f[1]))
      toSoABody.add newAssignment(nnkBracketExpr.newTree(nnkDotExpr.newTree(paramId, f[0]), iId), nnkDotExpr.newTree(nnkBracketExpr.newTree(oldId, iId), f[0]))
      setLenBody.add newCall(ident"setLen", nnkDotExpr.newTree(paramId, f[0]), ident"newLen")
      toOldTBody.add newAssignment(nnkDotExpr.newTree(oldId, f[0]), newCall(f[0], paramId))
    result.add (if exported: getAst declareSoAaccessors(newT,fields[0][0]) else: getAst declareSoAaccessorsPrivate(newT,fields[0][0]))
    result.add (if exported: getAst declareSoASetLen(paramId, newLenId, newT, setLenBody) else: getAst declareSoASetLenPrivate(paramId, newLenId, newT, setLenBody))
    result.add (if exported: getAst declareSoAToSoA(paramId, oldId, iId, newT, T, toSoABody) else: getAst declareSoAToSoAPrivate(paramId, oldId, iId, newT, T, toSoABody))
    let tooldT = ident("to" & $T)
    result.add (if exported: getAst declareSoAtoOldT(paramId, oldId, newT, T, toOldT, toOldTBody) else: getAst declareSoAtoOldTPrivate(paramId, oldId, newT, T, toOldT, toOldTBody))
    if exported:
      result.add nnkExportStmt.newTree(newT)

macro declareSoA*(T: typedesc[object], newT: untyped): untyped =
  ## Construct an object ``newT`` containing seqs of the fields of object ``T``,
  ## generate field accessors, ``len`` and ``setLen`` utilities, the proc ``tonewT`` to
  ## convert an array of ``T`` to a ``newT`` instance, and the proc ``toT`` to get a T
  ## from indexing a ``newT``.
  runnableExamples:
    type
      MyObj* = object
        field1*: int
        field2*: float

    declareSoA(MyObj, MyObjSoA)

    var aos = @[MyObj(field1: 1, field2: 1.2), MyObj(field1: 2, field2: 2.1)]
    var soa = toSoA(aos)

    assert soa.len == aos.len

    assert soa[0].field1 == 1
    assert soa[0].field2 == 1.2
    assert soa[1].field1 == 2
    assert soa[1].field2 == 2.1

    assert soa[0].toMyObj == aos[0]
    assert soa[1].toMyObj == aos[1]

  result = declareSoAImpl(T, newT, exported = true)

macro declareSoAPrivate*(T: typedesc[object], newT: untyped): untyped =
  ## Construct an object ``newT`` containing seqs of the fields of object ``T``,
  ## generate field accessors, ``len``, ``setLen`` utilities
  ## Same as ``declareSoA`` but ``newT`` is private to the calling module
  result = declareSoAImpl(T, newT, exported = false)
