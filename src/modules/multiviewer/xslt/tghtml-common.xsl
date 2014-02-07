<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tgs="http://www.textgrid.info/namespaces/middleware/tgsearch" exclude-result-prefixes="xs tei tgs xi" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0"> 

<!-- 
	Contains common TextGrid specific TEI -> HTML conversions that are used for both
	HTML and EPUB output. Should not contain structural changes but rather formatting 
	stuff.	
-->
	
	<!-- subtler page references -->
    <xsl:template match="pb">
        <span class="pagebreak" title="{concat('Page ', @n)}">[<xsl:value-of select="@n"/>]</span>
    </xsl:template>
	
	<!-- milestones get rendered in 7.x!? -->
    <xsl:template match="milestone">
        <xsl:comment>milestone (<xsl:value-of select="@unit"/>) "<xsl:value-of select="@n"/>" #<xsl:value-of select="@xml:id"/>
        </xsl:comment>
    </xsl:template>
</xsl:stylesheet>