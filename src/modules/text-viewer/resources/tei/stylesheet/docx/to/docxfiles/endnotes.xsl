<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:teidocx="http://www.tei-c.org/ns/teidocx/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:teix="http://www.tei-c.org/ns/Examples" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:tbx="http://www.lisa.org/TBX-Specification.33.0.html" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:contypes="http://schemas.openxmlformats.org/package/2006/content-types" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:iso="http://www.iso.org/ns/1.0" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:cals="http://www.oasis-open.org/specs/tm9901" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="cp ve o r m v wp w10 w wne mml tbx iso      tei a xs pic fn xsi dc dcterms dcmitype     contypes teidocx teix html cals">
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet">
        <desc>
            <p> TEI stylesheet for making Word docx files from TEI XML </p>
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
            <p>Id: $Id: endnotes.xsl 9646 2011-11-05 23:39:08Z rahtz $</p>
            <p>Copyright: 2008, TEI Consortium</p>
        </desc>
    </doc>
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
        <desc>
        Create the endnotes file
    </desc>
    </doc>
    <xsl:template name="write-docxfile-endnotes-file">
        <xsl:if test="$debug='true'">
            <xsl:message>Writing out <xsl:value-of select="concat($wordDirectory,'/word/endnotes.xml')"/>
            </xsl:message>
        </xsl:if>
        <xsl:result-document href="{concat($wordDirectory,'/word/endnotes.xml')}">
            <w:endnotes>
                <w:endnote w:type="separator" w:id="-1">
                    <w:p>
                        <w:pPr>
                            <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
                        </w:pPr>
                        <w:r>
                            <w:separator/>
                        </w:r>
                    </w:p>
                    <w:p/>
                    <w:p/>
                </w:endnote>
                <w:endnote w:type="continuationSeparator" w:id="0">
                    <w:p>
                        <w:pPr>
                            <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
                        </w:pPr>
                        <w:r>
                            <w:continuationSeparator/>
                        </w:r>
                    </w:p>
                    <w:p/>
                    <w:p/>
                </w:endnote>
                <xsl:for-each select="key('ENDNOTES',1)">
                    <xsl:variable name="id" select="position()+1"/>
                    <w:endnote w:id="{$id}">
                        <xsl:call-template name="block-element">
                            <xsl:with-param name="pPr">
                                <w:pPr>
                                    <w:pStyle w:val="EndnoteText"/>
                                </w:pPr>
                                <w:r>
                                    <w:rPr>
                                        <w:rStyle w:val="EndnoteReference"/>
                                    </w:rPr>
                                    <w:endnoteRef/>
                                </w:r>
                                <w:r>
                                    <w:t xml:space="preserve"> </w:t>
                                </w:r>
                            </xsl:with-param>
                        </xsl:call-template>
                    </w:endnote>
                </xsl:for-each>
            </w:endnotes>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>