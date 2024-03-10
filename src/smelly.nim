import std/strutils, std/options

# https://www.w3.org/TR/xml/

type XmlNode* = object
  startTag: (int, int)
  endTag: Option[(int, int)]

  # either have kids or a value
  inner: Option[(int, int)]
  kids: seq[XmlNode]



template error(msg: string) =
  raise newException(CatchableError, msg)



proc skipWhitespace(input: string, i: var int) =
  while i < input.len:
    if input[i] in {' ', '\n', '\r', '\t'}:
      inc i
    else:
      break



proc parseXml*(input: string): XmlNode =
  var
    i: int
    stack: seq[XmlNode]
    root: Option[XmlNode]
  while true:
    skipWhitespace(input, i)

    if i == input.len:
      break

    if root.isSome:
      error("Unexpected non-whitespace character at " & $i)




    case input[i]:
    of '<':
      let tmp = input.find('>', start = i + 1)
      if tmp == -1:
        error("missing thing")
      # echo input[i .. tmp]
      let tagLen = tmp - i + 1
      if input[i + 1] == '/': # end tag
        if stack.len == 0:
          error("no stack")
        else:
          var popped = stack.pop()
          popped.endTag = some((i, tagLen))
          # need to validate start and end tags match
          if stack.len == 0:
            root = some(move popped)
          else:
            stack[^1].kids.add(move popped)
      else: # start tag
        if stack.len > 0 and stack[^1].inner.isSome:
          error("node already has inner")

        var node: XmlNode
        node.startTag = (i, tagLen)
        if input[tmp - 1] == '/': # self closing
          if stack.len == 0:
            root = some(move node)
          else:
            stack[^1].kids.add(move node)
        else:
          stack.add(move node)
      i = tmp + 1
    else:
      let tmp = input.find('<', start = i + 1)
      if tmp == -1:
        error("missing thing")
      # echo input[i ..< tmp]
      if stack.len == 0:
        error("no stack")
      else:
        if stack[^1].kids.len > 0:
          error("node with kids and inner?")
        stack[^1].inner = some((i, tmp - i))
      i = tmp




  if stack.len > 0 or not root.isSome:
    error("Unexpected EOF " & $stack.len & ' ' & $(root.isSome))

  return move root.get



proc dump*(root: XmlNode, input: string): string =
  block:
    let tmp = result.len
    result.setLen(result.len + root.startTag[1])
    copyMem(result[tmp].addr, input[root.startTag[0]].unsafeAddr, root.startTag[1])
  if root.inner.isSome:
    let tmp = result.len
    result.setLen(result.len + root.inner.unsafeGet[1])
    copyMem(result[tmp].addr, input[root.inner.unsafeGet[0]].unsafeAddr, root.inner.unsafeGet[1])
  for kid in root.kids:
    result.add dump(kid, input)
  if root.endTag.isSome:
    let tmp = result.len
    result.setLen(result.len + root.endTag.unsafeGet[1])
    copyMem(result[tmp].addr, input[root.endTag.unsafeGet[0]].unsafeAddr, root.endTag.unsafeGet[1])
