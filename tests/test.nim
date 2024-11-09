# import std/xmlparser, std/xmltree

# block:
#   let root = parseXml("<thing>1 &lt; 2</thing>")
#   echo root.tag # thing
#   echo root.len # 4 ?????
#   echo '"', root[0], '"' # "1 " ?????

# block:
#   let root = parseXml("<thing>1 or 2</thing>")
#   echo root.tag # thing
#   echo root.len # 1
#   echo '"', root[0], '"' # "1 or 2"

# import smelly

# block:
#   let root = parseXml("<thing>1 &lt; 2</thing>")
#   echo root.tag # thing
#   echo root.children.len # 1
#   echo '"', root.children[0].content, '"' # "1 < 2"

# block:
#   let root = parseXml("<thing>1 or 2</thing>")
#   echo root.tag # thing
#   echo root.children.len # 1
#   echo '"', root.children[0].content, '"' # "1 or 2"

import smelly

# block:
#   let root = parseXml("<thing>a<b></b>c</thing>")
#   echo root




# echo parseXml(readFile("tests/data/ellipse01.svg"))
echo parseXml(readFile("tests/data/feed.xml"))
# echo parseXml(readFile("tests/data/apkmirror.xml"))

# block:
#   let s = """
#   <?xml version="1.0" encoding="UTF-8" ?>
#   <root>
#     <tag>
#       <test arg="blah" arg2="test"/>
#       <test2>
#         bla ah absy hsh
#         hsh
#         &woohoo;
#         sjj
#       </test2>
#       <test><teh>bla</teh></test>
#     </tag>
#   </root>
#   """
#   echo parseXml(s)


# <?xml version="1.0"?>
# <?xml   version="1.0" ?>
# <?xml version="1.0" standalone="no"?>
# <?XML version="1.0" standalone="no"   ?>


# let input1 = """
# <note/>
# """

# let input2 = """
# <note/>
# <note/>
# """

# let input5 = """
# asdf
# """

# let input6 = """
# asdf</asdf>
# """

# let input3 = """
# <note>
#   <to>Tove</to>
#   <from>Jani</from>
# </note>
# """

# let input4 = """
# <note>
#   <br/>
#   <to>Tove</to>
#   <from>Jani</from>
# </note>
# """

# let input7 = """
# <a>asdf<b/></a>
# """

# let input8 = """
# <a><b>c</b>d</a>
# """

# let input9 = """
# <CATALOG>
#   <CD>
#     <TITLE>Empire Burlesque</TITLE>
#     <ARTIST>Bob Dylan</ARTIST>
#     <COUNTRY>USA</COUNTRY>
#     <COMPANY>Columbia</COMPANY>
#     <PRICE>10.90</PRICE>
#     <YEAR>1985</YEAR>
#   </CD>
#   <CD>
#     <TITLE>Hide your heart</TITLE>
#     <ARTIST>Bonnie Tyler</ARTIST>
#     <COUNTRY>UK</COUNTRY>
#     <COMPANY>CBS Records</COMPANY>
#     <PRICE>9.90</PRICE>
#     <YEAR>1988</YEAR>
#   </CD>
#   <CD>
#     <TITLE>Greatest Hits</TITLE>
#     <ARTIST>Dolly Parton</ARTIST>
#     <COUNTRY>USA</COUNTRY>
#     <COMPANY>RCA</COMPANY>
#     <PRICE>9.90</PRICE>
#     <YEAR>1982</YEAR>
#   </CD>
#   <CD>
#     <TITLE>Still got the blues</TITLE>
#     <ARTIST>Gary Moore</ARTIST>
#     <COUNTRY>UK</COUNTRY>
#     <COMPANY>Virgin records</COMPANY>
#     <PRICE>10.20</PRICE>
#     <YEAR>1990</YEAR>
#   </CD>
# </CATALOG>
# """

# block:
#   let input = input9
#   echo dump(parseXml(input), input)
