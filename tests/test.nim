import smelly

echo parseXml(readFile("tests/data/feed.xml"))


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
