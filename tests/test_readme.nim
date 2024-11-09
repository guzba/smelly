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
