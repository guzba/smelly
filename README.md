# Smelly

`nimble install smelly`

[API reference](https://guzba.github.io/smelly/)

Sometimes you need to parse XML. Pinch your nose and get it over with.

This package is an alternative to Nim's standard library XML parser (std/xmlparser + std/xmltree).

## Using Smelly

```nim
import smelly

let s = """
<?xml version="1.0" encoding="UTF-8"?>
<svg viewBox="0 0 1200 400" xmlns="http://www.w3.org/2000/svg" version="1.1">
  <rect x="1" y="1" width="1198" height="398" fill="none" stroke="blue" stroke-width="2" />
  <ellipse transform="translate(900 200) rotate(-30)" rx="250" ry="100" fill="none" stroke="blue" stroke-width="20"  />
  Some text content here
</svg>
"""

let root = parseXml(s)

for child in root.children:
  case child.kind:
  of ElementNode:
    echo child.tag, ' ', child.attributes["stroke-width"]
  of TextNode:
    echo child.content
```

```
rect 2
ellipse 20
Some text content here
```

## Why create an alternative?

After working with Nim's standard lib XML parsing for a while I have found some sources of frustration that I want to avoid.

Nim's std/xmltree uses `[]` on a node to access it's children and uses `.attr[]` to access attributes. This isn't so bad (it makes accessing deep into a node tree easy), however I always have to re-learn if `[]` accesses children or attributes after I've been away from XML parsing for a bit. With Smelly there is no amibguity, it's just `.children[]` and `.attributes[]`.

Even more annoyingly, Nim's std/xml considers every single entity encoding (eg `&lt;`) to be independent elements in the node tree instead of just a text encoding detail.

If an encoded entity is present:

```nim
import std/xmlparser, std/xmltree

let root = parseXml("<thing>1 &lt; 2</thing>")
echo root.tag # thing
echo root.len # 4 ?????
echo '"', root[0], '"' # "1 " ?????
```

And if an encoded entity is not present:

```nim
import std/xmlparser, std/xmltree

let root = parseXml("<thing>1 or 2</thing>")
echo root.tag # thing
echo root.len # 1
echo '"', root[0], '"' # "1 or 2"
```
This drastic difference in behavior based on the presence of an encoded entity is not cool with me.

Here is how Smelly handles this:

```nim
import smelly

let root = parseXml("<thing>1 &lt; 2</thing>")
echo root.tag # thing
echo root.children.len # 1
echo '"', root.children[0].content, '"' # "1 < 2"
```

And if an encoded entity is not present:

```nim
import smelly

let root = parseXml("<thing>1 or 2</thing>")
echo root.tag # thing
echo root.children.len # 1
echo '"', root.children[0].content, '"' # "1 or 2"
```

## Performance

Smelly is between 2x and 7x faster than `std/xmlparser` depending on the XML input.

See `tests/bench.nim` to test this for yourself.

## Testing

`nimble test`
