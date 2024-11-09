import benchy, smelly

let s = readFile("tests/data/feed.xml")
# let s = readFile("tests/data/apkmirror.xml")

timeIt "smelly":
  doAssert parseXml(s) != nil

from std/xmlparser as std import nil
timeIt "std/xmlparser":
  doAssert std.parseXml(s) != nil
