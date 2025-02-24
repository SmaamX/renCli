import std/[sequtils, strutils, os, times], illwill, winregistry

# del list is unstable

#terminal.eraseScreen()
var cust = @["0", "\x1B[30;1m", "\x1B[40;1m", "1", "\x1B[31;1m", "\x1B[41;1m", "2", "\x1B[32;1m", "\x1B[42;1m"]
var fp = 0
var backlog = ""
var bol = false
var mand = true

proc termget_win(): auto =
  var
   faceName: string
   WindowSize: int32
   fontWeight: int32
   h: RegHandle
  try:
    h = open("HKEY_CURRENT_USER\\Console\\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe", samRead)
    return [h.readInt32("WindowSize"), h.readInt32("FontWeight")]
  except OSError:
    try:
      h = open("HKEY_CURRENT_USER\\Console\\%%SystemRoot%%_system32_cmd.exe", samRead)
      return [h.readInt32("WindowSize"), h.readInt32("FontWeight")]
    except OSError:
      echo "e -> ", getCurrentExceptionMsg()
  finally:
    close(h)

proc refs(dela: int = 1) =
  sleep(dela)
  if not mand:
   echo "\033[2K\r"
  else:
   try:
     if hostOS == "windows":
       discard os.execShellCmd("cls")
     else:
       discard os.execShellCmd("clear")
   except:
     discard

proc addLists(list1: seq[string], list2: seq[string]): seq[string] =
  var intlist1: seq[int] = @[]
  var intlist2: seq[int] = @[]
  for i in list1:
    intlist1.add(parseInt(i))
  for i in list2:
    intlist2.add(parseInt(i))
  var outlist: seq[int] = zip(intlist1, intlist2).mapIt(it[0] + it[1])
  var outlist_str: seq[string] = @[]
  for i in outlist:
    outlist_str.add(intToStr(i))
  outlist_str

proc addLists(list1: seq[seq[string]], list2: seq[seq[string]]): seq[seq[string]] =
  var out1: seq[seq[string]]
  for i in countup(0, len(list1)-1):
    out1.add(addLists(list1[i], list2[i]))
  out1

proc delLists(list1: seq[string], list2: seq[string]): seq[string] =
  var intlist1: seq[int] = @[]
  var intlist2: seq[int] = @[]
  for i in list1:
    intlist1.add(parseInt(i))
  for i in list2:
    intlist2.add(parseInt(i))
  var outlist: seq[int] = zip(intlist1, intlist2).mapIt(it[0] - it[1])
  var outlist_str: seq[string] = @[]
  for i in outlist:
    outlist_str.add(intToStr(i))
  outlist_str

proc delLists(list1: seq[seq[string]], list2: seq[seq[string]]): seq[seq[string]] =
  var out1: seq[seq[string]]
  for i in countup(0, len(list1)-1):
    out1.add(delLists(list1[i], list2[i]))
  out1

proc color_char(char: string, shadow: int = 0): string =
  var vj: string  
  case shadow  
  of 0: vj = "█"  
  of 1: vj = "▓"  
  of 2: vj = "▒"  
  of 3: vj = "░"  
  else:  
   echo "\x1B[31mBSConf: ", shadow
   quit()
  if char == "-2":
    return  "\x1B[0m\n"
  elif char == "-1":
    refs(fp); return "\x1B[0m\r"
  elif char in cust:
    backlog = cust[cust.find(char)+2]
    return "\x1B[0m" & (if shadow == 0: cust[cust.find(char)+2] else: "") & cust[cust.find(char)+1] & vj & "\x1B[0m"
  else:
    if backlog != "":
      return "\x1B[0m" & "\x1B[1m" & backlog & cust[cust.find(char)+2] & char & "\x1B[0m"
    else:
      return "\x1B[0m" & "\x1B[1m" & "\x1B[7m" & cust[cust.find(char)+2] & char & "\x1B[0m"

proc colz(chars: auto, shadow: int = 0, mand: bool = false, lfix: bool = false): string =
  var check_list: seq[string]
  if lfix:  
   for i in chars:  
    if i != "0":
     check_list.add(i)  
    else:  
      check_list = check_list[0 ..< check_list.high]  
      check_list.add(i)  
   try:  
    return check_list.mapIt(color_char(it, shadow)).join()  
   except IOError:
    echo "\x1B[31mNanType"
    quit()  
  else:  
   try:  
    return chars.mapIt(color_char(it, shadow)).join()  
   except IOError:
    echo "\x1B[31mNanType"
    quit()  

proc ren_colz(local: seq[seq[auto]], refs: bool = false, shadow: int = 0): string =
  var data_temp_2 = ""  
  for r in local:  
   for i in r:  
    data_temp_2.add(color_char(i, shadow))
   data_temp_2.add("\n")
  if refs == true:
   data_temp_2.add(color_char("-1"))
   return data_temp_2
  return data_temp_2

proc echx(import_l: seq[seq[auto]], refs = true, sha = 0) =
  echo ren_colz(import_l, refs = refs, shadow = sha)

proc lmove(import_l: var seq[string], mmod: int, targ: string = "0"): seq[string] =
  if mmod == 0:
    if targ == "0":
      let eend = import_l[0]
      import_l.delete(0)
      import_l.add(eend)
    else:
      if import_l[0] == targ:
        return import_l
      else:
        let eend = import_l[0]
        import_l.delete(0)
        import_l.add(eend)
  elif mmod == 180:
    if targ == "0":
      let eend = import_l[len(import_l)-1]
      import_l.delete(len(import_l)-1)
      import_l.insert(eend,0)
    else:
      if import_l[len(import_l)-1] == targ:
        return import_l
      else:
        let eend = import_l[len(import_l)-1]
        import_l.delete(len(import_l)-1)
        import_l.insert(eend,0)
  import_l

proc actouch(import_l: seq[string], import_l2: seq[string], lmove: int, main_targ: string, sec_targ: string): bool =
  if import_l.find(main_targ)+lmove == import_l2.find(sec_targ):
    return true
  else:
    return false

proc actouch(import_l: seq[seq[string]], import_l2: seq[seq[string]], lmove: int, main_targ: string, sec_targ: string, lmod:bool = true): bool =
  for i in countup(0, len(import_l)-1):
    if main_targ in import_l[i]:
      if lmod == false:
        try:
          if import_l[i].find(main_targ) == import_l2[i+lmove].find(sec_targ):
            return true
          else:
            return false
        except IndexDefect:
          return false
      else:
        for iv in countup(0, len(import_l2)-1):
          if sec_targ in import_l2[iv]:
            try:
              if import_l[i].find(main_targ)+lmove == import_l2[iv].find(sec_targ) and i == iv:
                return true
              else:
                return false
            except IndexDefect:
              return false

proc lmove(import_l: var seq[seq[string]], mmod: int, targ: string = "0", lrev:int = 0): seq[seq[string]] =
  for j in countup(0,lrev):
    if mmod == 180:
      for i in import_l:
        if targ in i:
          var import_ll = import_l[import_l.find(i)]
          if targ == "0":
            let eend = import_ll[0]
            import_ll.delete(0)
            import_ll.add(eend)
          else:
            if targ in import_ll[0]:
              if j == lrev:
                return import_l
            else:
              let eend = import_ll[0]
              import_ll.delete(0)
              import_ll.add(eend)
          let eend = import_l.find(i)
          import_l.delete(import_l.find(i))
          import_l.insert(import_ll, eend)
          if j == lrev:
            return import_l
    if mmod == 0:
      for i in import_l:
        if targ in i:
          var import_ll = import_l[import_l.find(i)]
          if targ == "0":
            let eend = import_ll[len(import_ll)-1]
            import_ll.delete(len(import_ll)-1)
            import_ll.insert(eend,0)
          else:
            if targ in import_ll[len(import_l)-1]:
              if j == lrev:
                return import_l
            else:
              let eend = import_ll[len(import_ll)-1]
              import_ll.delete(len(import_ll)-1)
              import_ll.insert(eend,0)
          let eend = import_l.find(i)
          import_l.delete(import_l.find(i))
          import_l.insert(import_ll, eend)
          if j == lrev:
            return import_l
    if mmod == 270:
      if targ == "0":
        let eend = import_l[len(import_l)-1]
        import_l.delete(len(import_l)-1)
        import_l.insert(eend,0)
      else:
        if targ in import_l[len(import_l)-1]:
          if j == lrev:
            return import_l
        else:
          let eend = import_l[len(import_l)-1]
          import_l.delete(len(import_l)-1)
          import_l.insert(eend,0)
    if mmod == 90:
      if targ == "0":
        let eend = import_l[0]
        import_l.delete(0)
        import_l.add(eend)
      else:
        if targ in import_l[0]:
          if j == lrev:
            return import_l
        else:
          let eend = import_l[0]
          import_l.delete(0)
          import_l.add(eend)
    if j == lrev:
      return import_l

proc lmove(import_lv: seq[seq[string]], mmod: int, targ: string = "0", lrev:int = 0): seq[seq[string]] =
  var import_l = import_lv
  for j in countup(0,lrev):
    if mmod == 180:
      for i in import_l:
        if targ in i:
          var import_ll = import_l[import_l.find(i)]
          if targ == "0":
            let eend = import_ll[0]
            import_ll.delete(0)
            import_ll.add(eend)
          else:
            if targ in import_ll[0]:
              if j == lrev:
                return import_l
            else:
              let eend = import_ll[0]
              import_ll.delete(0)
              import_ll.add(eend)
          let eend = import_l.find(i)
          import_l.delete(import_l.find(i))
          import_l.insert(import_ll, eend)
          if j == lrev:
            return import_l
    if mmod == 0:
      for i in import_l:
        if targ in i:
          var import_ll = import_l[import_l.find(i)]
          if targ == "0":
            let eend = import_ll[len(import_ll)-1]
            import_ll.delete(len(import_ll)-1)
            import_ll.insert(eend,0)
          else:
            if targ in import_ll[len(import_l)-1]:
              if j == lrev:
                return import_l
            else:
              let eend = import_ll[len(import_ll)-1]
              import_ll.delete(len(import_ll)-1)
              import_ll.insert(eend,0)
          let eend = import_l.find(i)
          import_l.delete(import_l.find(i))
          import_l.insert(import_ll, eend)
          if j == lrev:
            return import_l
    if mmod == 270:
      if targ == "0":
        let eend = import_l[len(import_l)-1]
        import_l.delete(len(import_l)-1)
        import_l.insert(eend,0)
      else:
        if targ in import_l[len(import_l)-1]:
          if j == lrev:
            return import_l
        else:
          let eend = import_l[len(import_l)-1]
          import_l.delete(len(import_l)-1)
          import_l.insert(eend,0)
    if mmod == 90:
      if targ == "0":
        let eend = import_l[0]
        import_l.delete(0)
        import_l.add(eend)
      else:
        if targ in import_l[0]:
          if j == lrev:
            return import_l
        else:
          let eend = import_l[0]
          import_l.delete(0)
          import_l.add(eend)
    if j == lrev:
      return import_l

proc echdraw(import_l: seq[seq[string]], x:seq[int], y:seq[int], xslp:seq[int] = @[], targ:string = "0", layer: bool = false, disrange:int = -1, deoverflow:bool = true): seq[seq[string]] =
  var varlayer = false
  if xslp != @[]:
    var varlayer = true
  var import_lll = import_l
  var import_v = import_l
  var i = 0
  for xn in x:
    for yn in y:
      if deoverflow == true and xn == yn:
        continue
      if yn != -1:
        i += 1
        if i >= disrange and disrange != -1:
          discard lmove(import_v, xn, targ=targ)
          discard lmove(import_v, yn, targ=targ)
          import_lll = delLists(import_lll,import_v)
        var import_ll = import_l
        discard lmove(import_ll, xn, targ=targ)
        discard lmove(import_ll, yn, targ=targ)
        import_lll = addLists(import_lll,import_ll)
        if layer == true or varlayer == true:
          echx import_lll
          if xslp != @[]:
            sleep(xslp[i])
  import_lll
