import unicody, smelly/xmlattributes, std/bitops

when defined(amd64):
  import nimsimd/sse2

from std/strutils import find, toLowerAscii, cmpIgnoreCase

export xmlattributes

# https://www.w3.org/TR/xml/

const
  whitespace = {' ', '\n', '\r', '\t'}
  ltEntity = "lt"
  gtEntity = "gt"
  ampEntity = "amp"
  aposEntity = "apos"
  quotEntity = "quot"
  cdataStart = "<![CDATA["
  cdataEnd = "]]>"
  doctypeStart = "<!DOCTYPE"
  commentStart = "<!--"
  piStart = "<?"
  piEnd = "?>"

type
  XmlNodeKind* = enum
    ElementNode, TextNode

  XmlNode* = ref object
    case kind*: XmlNodeKind
    of ElementNode:
      tag*: string
      attributes*: XmlAttributes
      children*: seq[XmlNode]
    of TextNode:
      content*: string

proc `$`*(node: XmlNode): string =
  case node.kind:
  of ElementNode:
    result.add '<' & node.tag
    for (name, value) in node.attributes:
      result.add ' ' & name & "=\"" & value & '"'
    if node.children.len == 0:
      result.add " />"
    else:
      result.add '>'
      for child in node.children:
        result.add $child
      result.add '<' & '/' & node.tag & '>'
  of TextNode:
    result.add node.content

template error(msg: string) =
  raise newException(CatchableError, msg)

template eof() =
  error("Unexpected end of XML input")

template missingRequiredWhitespace(input, i) =
  error("Missing required whitespace at byte offset " & $i)

template badXml(input, i) =
  error("Unexpected " & input[i] & " at byte offset " & $i)

template badEntity(input, i) =
  error("Bad entity at byte offset " & $i)

# when defined(release):
#   {.push checks: off.}

proc startsWith(a, b: openarray[char]): bool =
  if b.len == 0:
    true
  elif b.len > a.len:
    false
  else:
    equalMem(a[0].addr, b[0].addr, b.len)

proc startsWithXmlDeclaration(s: openarray[char]): bool =
  if s.len < 5:
    eof()
  elif not equalMem(s[0].addr, piStart.cstring, piStart.len):
    false
  elif s[2] notin {'x', 'X'}:
    false
  elif s[3] notin {'m', 'M'}:
    false
  elif s[4] notin {'l', 'L'}:
    false
  else:
    true

proc skipWhitespace(
  input: string,
  i: var int,
  required: static bool = false
) =
  let start = i
  while i < input.len and input[i] in whitespace:
    inc i
  if required and start == i:
    missingRequiredWhitespace(input, i)

proc decodeCharData(input: string, start, len: int): string =
  var offset = start
  while offset < start + len:

    when defined(amd64):
      while offset + 16 < start + len:
        let
          tmp = mm_loadu_si128(input[offset].addr)
          mask = mm_movemask_epi8(mm_cmpeq_epi8(tmp, mm_set1_epi8('&'.uint8)))
        if mask == 0:
          let z = result.len
          result.setLen(z + 16)
          mm_storeu_si128(result[z].addr, tmp)
          offset += 16
        else:
          offset += firstSetBit(mask) - 1
          break

    if input[offset] == '&':
      let x = input.find(';', start = offset + 1)
      if x == -1:
        eof()
      let entityLen = x - (offset + 1)
      if entityLen == 0:
        badXml(input, x)
      elif input[offset + 1] == '#':
        var
          asdf = offset + 2
          n: int
        while asdf < x:
          if asdf >= input.len:
            eof()
          let c = input[asdf]
          if c in {'0'..'9'}:
            n = n * 10 + (ord(c) - ord('0'))
          else:
            badEntity(input, offset)
          inc asdf
        if n > int32.high:
          badEntity(input, offset)
        let rune = Rune(cast[int32](n))
        if not rune.isValid:
          badEntity(input, offset)
        result.unsafeAdd rune
      elif entityLen == 2:
        if equalMem(input[offset + 1].addr, ltEntity.cstring, 2):
          result.add '<'
        elif equalMem(input[offset + 1].addr, gtEntity.cstring, 2):
          result.add '>'
        else:
          badEntity(input, offset)
      elif entityLen == 3:
        if equalMem(input[offset + 1].addr, ampEntity.cstring, 3):
          result.add '&'
        else:
          badEntity(input, offset)
      elif entityLen == 4:
        if equalMem(input[offset + 1].addr, quotEntity.cstring, 4):
          result.add '"'
        elif equalMem(input[offset + 1].addr, aposEntity.cstring, 4):
          result.add '\''
        else:
          badEntity(input, offset)
      else:
        badEntity(input, offset)
      offset = x + 1
    else:
      result.add input[offset]
      inc offset

proc readCdata(input: string, i: var int): string =
  if i + cdataStart.len > input.len:
    eof()
  elif not equalMem(input[i].addr, cdataStart.cstring, 9):
    badXml(input, i)

  i += cdataStart.len

  let e = input.find(cdataEnd, start = i)
  if e == -1:
    eof()

  let len = e - i
  result.setLen(len)
  copyMem(result.cstring, input[i].addr, len)

  i = e + cdataEnd.len

proc readValue(input: string, i: var int): string =
  if i >= input.len:
    eof()

  let q = input[i]

  if q notin {'\'', '"'}:
    badXml(input, i)

  inc i

  let e = input.find(q, start = i)

  result = decodeCharData(input, i, e - i)

  i = e + 1

proc readAttribute(input: string, i: var int): (string, string) =
  let e = input.find('=', start = i)
  if e == -1:
    eof()
  elif e == i:
    badXml(input, i)

  result[0].setLen(e - i)
  copyMem(result[0].cstring, input[i].addr, result[0].len)

  i = e + 1

  result[1] = readValue(input, i)

proc skipProcessingInstruction(input: string, i: var int) =
  if not startsWith(input.toOpenArray(i, input.high), piStart):
    badXml(input, i)

  if startsWithXmlDeclaration(input.toOpenArray(i, input.high)):
    error("Invalid processing instruction target at byte offset " & $i)

  i += 2

  let q = input.find('?', start = i)
  if q == -1:
    eof()

  if not startsWith(input.toOpenArray(q, input.high), piEnd):
    badXml(input, q)

  i = q + piEnd.len

proc skipComment(input: string, i: var int) =
  if not startsWith(input.toOpenArray(i, input.high), commentStart):
    badXml(input, i)

  i += 4

  while true:
    let x = input.find('-', start = i)
    if x == -1 or x + 2 > input.len:
      eof()

    if input[x + 1] != '-':
      i = x + 1
      continue

    if input[x + 2] != '>':
      i = x + 2
      continue

    if input[x - 1] == '-':
      badXml(input, x - 1)

    i = x + 3
    break

proc skipDoctypeDefinition(input: string, i: var int) =
  if not startsWith(input.toOpenArray(i, input.high), doctypeStart):
    badXml(input, i)

  i += doctypeStart.len

  skipWhitespace(input, i, required = true)

  let x = input.find('>', start = i)
  if x == -1:
    eof()

  i = x + 1

proc skipProlog(input: string, i: var int) =
  if not startsWithXmlDeclaration(input.toOpenArray(i, input.high)):
    # Optional
    return

  i += 5

  skipWhitespace(input, i, required = true)

  block:
    let
      start = i
      (name, value) = readAttribute(input, i)
    if cmpIgnoreCase(name, "version") != 0:
      badXml(input, start)
    elif not startsWith(value, "1."):
      badXml(input, i - value.len)

  # Skip any additional attributes
  while true:
    if i >= input.len:
      eof()

    let beforeSkippingWhitespace = i
    skipWhitespace(input, i)

    if input[i] == '?':
      break

    if i == beforeSkippingWhitespace:
      missingRequiredWhitespace(input, i)

    let
      start = i
      (name, value) = readAttribute(input, i)
    if cmpIgnoreCase(name, "encoding") == 0:
      discard
    elif cmpIgnoreCase(name, "standalone") == 0:
      discard
    else:
      error("Invalid attribute name at byte offset " & $start)

  if not startsWith(input.toOpenArray(i, input.high), piEnd):
    badXml(input, i)

  i += piEnd.len

  # Skip any processing instructions, comments and doctype definitions
  while true:
    skipWhitespace(input, i)

    if startsWith(input.toOpenArray(i, input.high), commentStart):
      skipComment(input, i)
    elif startsWith(input.toOpenArray(i, input.high), piStart):
      skipProcessingInstruction(input, i)
    elif startsWith(input.toOpenArray(i, input.high), doctypeStart):
      skipDoctypeDefinition(input, i)
    else:
      break

proc parseNode(input: string, i: var int, depth: int): XmlNode =
  const maxDepth = 100
  if depth > maxDepth:
    error("Child node depth exceeded max of " & $maxDepth)

  if i >= input.len:
    eof()
  elif input[i] != '<':
    badXml(input, i)

  inc i

  var tag: string
  block:
    let start = i
    while true:
      if i >= input.len:
        eof()
      elif input[i] in whitespace or input[i] in {'/', '>'}:
        break
      inc i
    let len = i - start
    if len == 0:
      badXml(input, i)
    tag.setLen(len)
    copyMem(tag.cstring, input[start].addr, len)

  var attributes = emptyXmlAttributes()
  while true:
    skipWhitespace(input, i)

    if i >= input.len:
      eof()
    elif input[i] in {'/', '>'}:
      break

    attributes.add(readAttribute(input, i))

  if input[i] == '/':
    if i + 1 > input.len:
      eof()
    elif input[i + 1] != '>':
      badXml(input, i + 1)
    i += 2
    return XmlNode(kind: ElementNode, tag: move tag, attributes: move attributes)
  elif input[i] == '>':
    inc i
  else:
    badXml(input, i)

  var children: seq[XmlNode]
  while true:
    skipWhitespace(input, i)

    if i + 1 >= input.len:
      eof()

    if input[i] == '<':
      let next = input[i + 1]
      case next:
      of '/':
        if i + tag.len + 2 >= input.len:
          eof()
        elif startsWith(input.toOpenArray(i + 2, input.high), tag):
          i += tag.len + 2
          skipWhitespace(input, i)
          if i >= input.len:
            eof()
          if input[i] != '>':
            badXml(input, i)
          inc i
          return XmlNode(
            kind: ElementNode,
            tag: move tag,
            attributes: move attributes,
            children: move children
          )
        else:
          badXml(input, i + 2)
      of '?':
        skipProcessingInstruction(input, i)
      of '!':
        if startsWith(input.toOpenArray(i, input.high), cdataStart):
          children.add(XmlNode(kind: TextNode, content: readCdata(input, i)))
        else:
          skipComment(input, i)
      else:
        children.add(parseNode(input, i, depth + 1))
    else:
      let x = input.find('<', start = i)
      if x == -1:
        eof()
      children.add(XmlNode(kind: TextNode, content: decodeCharData(input, i, x - i)))
      i = x

proc parseXml*(input: string): XmlNode {.gcsafe.} =
  let invalidAt = validateUtf8(input)
  if invalidAt != -1:
    error("Invalid UTF-8 character at " & $invalidAt)

  var i: int

  skipWhitespace(input, i)

  skipProlog(input, i)

  result = parseNode(input, i, 0)

  # Skip any trailing processing instructions and comments
  while true:
    skipWhitespace(input, i)

    if startsWith(input.toOpenArray(i, input.high), commentStart):
      skipComment(input, i)
    elif startsWith(input.toOpenArray(i, input.high), piStart):
      skipProcessingInstruction(input, i)
    else:
      break

  if i != input.len:
    badXml(input, i)

# when defined(release):
#   {.pop.}
