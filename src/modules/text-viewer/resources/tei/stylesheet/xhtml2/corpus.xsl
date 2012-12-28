<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:teix="http://www.tei-c.org/ns/Examples" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:fo="http://www.w3.org/1999/XSL/Format" exclude-result-prefixes="a fo rng tei teix" version="2.0"><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet"><desc><p> TEI stylesheet dealing with elements from the corpus module,
      making HTML output. </p><p>This software is dual-licensed:

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
</p><p>Author: See AUTHORS</p><p>Id: $Id: corpus.xsl 9646 2011-11-05 23:39:08Z rahtz $</p><p>Copyright: 2011, TEI Consortium</p></desc></doc><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl"><desc>Process element catRef</desc></doc><xsl:template match="tei:catRef"><xsl:variable name="W"><xsl:choose><xsl:when test="starts-with(@target,'#')"><xsl:value-of select="substring(@target,2)"/></xsl:when><xsl:otherwise><xsl:value-of select="@target"/></xsl:otherwise></xsl:choose></xsl:variable><xsl:if test="preceding-sibling::tei:catRef"><xsl:text> 
    </xsl:text></xsl:if><em><xsl:value-of select="@scheme"/></em>: <xsl:apply-templates select="id($W)/catDesc"/></xsl:template><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl"><desc>Process element teiCorpus</desc></doc><xsl:template match="tei:teiCorpus"><xsl:element name="html" namespace="{$outputNamespace}"><xsl:call-template name="addLangAtt"/><head><title><xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()"/></title><xsl:call-template name="includeCSS"/><xsl:call-template name="cssHook"/></head><body class="simple"><xsl:call-template name="bodyMicroData"/><xsl:call-template name="bodyHook"/><xsl:call-template name="bodyJavascriptHook"/><div class="stdheader"><xsl:call-template name="stdheader"><xsl:with-param name="title"><xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title"/></xsl:with-param></xsl:call-template></div><xsl:call-template name="corpusBody"/><xsl:call-template name="stdfooter"/><xsl:call-template name="bodyEndHook"/></body></xsl:element></xsl:template><xsl:template match="tei:teiCorpus" mode="split"><xsl:variable name="BaseFile"><xsl:value-of select="$masterFile"/><xsl:call-template name="addCorpusID"/></xsl:variable><xsl:if test="$verbose='true'"><xsl:message>TEI HTML: run start hook template teiStartHook</xsl:message></xsl:if><xsl:call-template name="teiStartHook"/><xsl:if test="$verbose='true'"><xsl:message>TEI HTML in corpus splitting mode, base file is <xsl:value-of select="$BaseFile"/></xsl:message></xsl:if><xsl:variable name="outName"><xsl:call-template name="outputChunkName"><xsl:with-param name="ident"><xsl:value-of select="$BaseFile"/></xsl:with-param></xsl:call-template></xsl:variable><xsl:if test="$verbose='true'"><xsl:message>Opening file <xsl:value-of select="$outName"/></xsl:message></xsl:if><xsl:result-document doctype-public="{$doctypePublic}" doctype-system="{$doctypeSystem}" encoding="{$outputEncoding}" href="{$outName}" method="{$outputMethod}"><xsl:element name="html" namespace="{$outputNamespace}"><xsl:call-template name="addLangAtt"/><head><title><xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()"/></title><xsl:call-template name="includeCSS"/><xsl:call-template name="cssHook"/></head><body class="simple"><xsl:call-template name="bodyMicroData"/><xsl:call-template name="bodyJavascriptHook"/><xsl:call-template name="bodyHook"/><div class="stdheader"><xsl:call-template name="stdheader"><xsl:with-param name="title"><xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]"/></xsl:with-param></xsl:call-template></div><xsl:call-template name="corpusBody"/><xsl:call-template name="stdfooter"/><xsl:call-template name="bodyEndHook"/></body></xsl:element></xsl:result-document><xsl:if test="$verbose='true'"><xsl:message>Closing file <xsl:value-of select="$outName"/></xsl:message></xsl:if><xsl:if test="$verbose='true'"><xsl:message>TEI HTML: run end hook template teiEndHook</xsl:message></xsl:if><xsl:call-template name="teiEndHook"/><xsl:apply-templates select="tei:TEI" mode="split"/></xsl:template><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl"><desc>[html] </desc></doc><xsl:template name="corpusBody"><xsl:call-template name="mainTOC"/></xsl:template></xsl:stylesheet>