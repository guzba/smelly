import benchy, smelly

let feed = readFile("tests/data/feed.xml")

timeIt "smelly":
  doAssert parseXml(feed) != nil

# from std/xmlparser as std import nil
# timeIt "std/xmlparser":
#   doAssert std.parseXml(feed) != nil
