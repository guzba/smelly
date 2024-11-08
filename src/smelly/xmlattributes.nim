import std/typetraits

type XmlAttributes* = distinct seq[(string, string)]

converter toBase*(params: var XmlAttributes): var seq[(string, string)] =
  params.distinctBase

when (NimMajor, NimMinor, NimPatch) >= (1, 4, 8):
  converter toBase*(params: XmlAttributes): lent seq[(string, string)] =
    params.distinctBase
else: # Older versions
  converter toBase*(params: XmlAttributes): seq[(string, string)] =
    params.distinctBase

proc `[]`*(attributes: XmlAttributes, key: string): string =
  ## Gets the attribute value for the key.
  ## Returns an empty string if key is not present.
  ## Use a for loop if there may be multiple values for the same key.
  for (k, v) in attributes.toBase:
    if k == key:
      return v

proc `[]=`*(attributes: var XmlAttributes, key, value: string) =
  ## Sets the attribute value for the key.
  for pair in attributes.mitems:
    if pair[0] == key:
      pair[1] = value
      return
  attributes.add((key, value))

proc contains*(attributes: XmlAttributes, key: string): bool =
  ## Returns true if key is in the attributes.
  for pair in attributes:
    if pair[0] == key:
      return true

proc add*(attributes: var XmlAttributes, params: XmlAttributes) =
  for (k, v) in params:
    attributes.add((k, v))

proc getOrDefault*(attributes: XmlAttributes, key, default: string): string =
  if key in attributes: attributes[key] else: default

proc `$`*(attributes: XmlAttributes): string =
  $toBase(attributes)

proc emptyXmlAttributes*(): XmlAttributes =
  discard
