<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:teidocx="http://www.tei-c.org/ns/teidocx/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:tbx="http://www.lisa.org/TBX-Specification.33.0.html" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:iso="http://www.iso.org/ns/1.0" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mml="http://www.w3.org/1998/Math/MathML" version="2.0" exclude-result-prefixes="ve o r m v wp w10 w wne mml tbx iso tei a xs pic fn tei teidocx">
    <!-- import conversion style -->
    <xsl:import href="../../default/docx/to.xsl"/>
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet">
        <desc>
            <p> TEI stylesheet for making Word docx files from TEI XML (see tei-docx.xsl) for Vesta </p>
            <p>This software is dual-licensed:

1. Distributed under a Creative Commons Attribution-ShareAlike 3.0
Unported License http://creativecommons.org/licenses/by-sa/3.0/ 

2. http://www.opensource.org/licenses/BSD-2-Clause
		
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

This software is provided by the copyright holders and contributors
"as is" and any express or implied warranties, including, but not
limited to, the implied warranties of merchantability and fitness for
a particular purpose are disclaimed. In no event shall the copyright
holder or contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of use,
data, or profits; or business interruption) however caused and on any
theory of liability, whether in contract, strict liability, or tort
(including negligence or otherwise) arising in any way out of the use
of this software, even if advised of the possibility of such damage.
</p>
            <p>Author: See AUTHORS</p>
            <p>Id: $Id: to.xsl 9646 2011-11-05 23:39:08Z rahtz $</p>
            <p>Copyright: 2008, TEI Consortium</p>
        </desc>
    </doc>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="tei:TEI">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="tei:teiHeader">
                <xsl:variable name="x">
                    <tei:TEI>
                        <xsl:copy-of select="tei:teiHeader"/>
                    </tei:TEI>
                </xsl:variable>
                <xsl:apply-templates select="$x"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="headerParts">
        <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc"/>
    </xsl:template>
</xsl:stylesheet>