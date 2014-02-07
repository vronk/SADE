<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tgs="http://www.textgrid.info/namespaces/middleware/tgsearch" exclude-result-prefixes="xs tei tgs xi" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:import href="./tei-stylesheets/html/html.xsl"/>
    <xsl:include href="tghtml-common.xsl"/>

    <!-- graphicsURLPattern == URL to use for graphics inclusion, i.e. get raw data. 
         The stylesheet will replace @URI@ with the actual URI reference and then 
         
    -->
    <xsl:param name="graphicsURLPattern"/>
    <xsl:param name="linkURLPattern"/>

    <!-- FIXME TODO document params to stylesheet -->
    <xsl:param name="verbose">true</xsl:param>
    <xsl:param name="graphicsPrefix"/>
    <xsl:param name="graphicsSuffix"/>
    <xsl:param name="parentURL"/>
    <xsl:param name="URLPREFIX"/>
    <xsl:param name="documentationLanguage"/>
    <xsl:param name="homeLabel"/>
    <xsl:param name="homeURL"/>
    <xsl:param name="homeWords"/>
    <xsl:param name="institution"/>
    <xsl:param name="searchURL"/>
    <xsl:param name="linkPanel">false</xsl:param>
    <xsl:param name="numberHeadings">false</xsl:param>
    <xsl:param name="autoToc">false</xsl:param>
    <xsl:param name="autoHead">false</xsl:param>
    <xsl:param name="showTitleAuthor">false</xsl:param>
    <xsl:param name="cssFile"/>        
        
    <!-- Copied from textstucture.xsl to remove the extra heading from the titleStmt -->
    <xsl:template name="stdheader">
        <xsl:param name="title">(no title)</xsl:param>
    </xsl:template>
            
    
    <!-- Aus textstructure.xsl (tei-xsl 6.17). 
    Das Originaltemplate erzeugt für jedes div eine überschrift und ruft dann das Header-Template auf,
    das auch aus unseren <desc>-Only-Divs dann überschriften macht (zu allem Überfluss noch auf max. 10 Zeichen 
    beschnitten und mit … versehen).
    -->
    <xsl:template name="divContents">
        <xsl:param name="Depth"/>
        <xsl:param name="nav">false</xsl:param>
        <xsl:variable name="ident">
            <xsl:apply-templates mode="ident" select="."/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="parent::tei:*/@rend='multicol'">
                <td style="vertical-align:top;">
                    <xsl:if test="not($Depth = '')">
                        <xsl:element name="h{$Depth + $divOffset}">
                            <xsl:for-each select="tei:head[1]">
                                <xsl:call-template name="makeRendition">
                                    <xsl:with-param name="default">false</xsl:with-param>
                                </xsl:call-template>
                            </xsl:for-each>
                            <xsl:if test="@xml:id">
                                <xsl:call-template name="makeAnchor">
                                    <xsl:with-param name="name">
                                        <xsl:value-of select="@xml:id"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:call-template name="header">
                                <xsl:with-param name="display">full</xsl:with-param>
                            </xsl:call-template>
                            <xsl:call-template name="sectionHeadHook"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:apply-templates/>
                </td>
            </xsl:when>
            <xsl:when test="@rend='multicol'">
                <xsl:apply-templates select="*[not(local-name(.)='div')]"/>
                <table>
                    <tr>
                        <xsl:apply-templates select="tei:div"/>
                    </tr>
                </table>
            </xsl:when>
            <xsl:when test="@rend='nohead'">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($Depth = '') and tei:head"> <!-- <- mod. hier -tv -->
                    <xsl:variable name="Heading">
                        <xsl:element name="{if (number($Depth)+$divOffset &gt;6) then 'div'                                                        else concat('h',number($Depth) +                                                        $divOffset)}">
                            <xsl:choose>
                                <xsl:when test="@rend">
                                    <xsl:call-template name="makeRendition"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="tei:head[1]">
                                        <xsl:call-template name="makeRendition">
                                            <xsl:with-param name="default">
                                                <xsl:choose>
                                                    <xsl:when test="number($Depth)&gt;5">
                                                        <xsl:text>div</xsl:text>
                                                        <xsl:value-of select="$Depth"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>false</xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:call-template name="header">
                                <xsl:with-param name="display">full</xsl:with-param>
                            </xsl:call-template>
                            <xsl:call-template name="sectionHeadHook"/>
                        </xsl:element>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$outputTarget='html5'">
                            <header>
                                <xsl:copy-of select="$Heading"/>
                            </header>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$Heading"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="$topNavigationPanel='true' and                                                $nav='true'">
                        <xsl:element name="{if ($outputTarget='html5') then 'nav'                                                        else 'div'}">
                            <xsl:call-template name="xrefpanel">
                                <xsl:with-param name="homepage" select="concat($masterFile,$standardSuffix)"/>
                                <xsl:with-param name="mode" select="local-name(.)"/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
                <xsl:apply-templates/>
                <xsl:if test="$bottomNavigationPanel='true' and                                        $nav='true'">
                    <xsl:element name="{if ($outputTarget='html5') then 'nav' else                                                'div'}">
                        <xsl:call-template name="xrefpanel">
                            <xsl:with-param name="homepage" select="concat($masterFile,$standardSuffix)"/>
                            <xsl:with-param name="mode" select="local-name(.)"/>
                        </xsl:call-template>
                    </xsl:element>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="generateTitle">
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="$useHeaderFrontMatter='true' and ancestor-or-self::tei:TEI/tei:text/tei:front//tei:docTitle">
                    <xsl:apply-templates select="ancestor-or-self::tei:TEI/tei:text/tei:front//tei:docTitle/tei:titlePart"/>
                </xsl:when>
                <xsl:when test="$useHeaderFrontMatter='true' and ancestor-or-self::tei:teiCorpus/tei:text/tei:front//tei:docTitle">
                    <xsl:apply-templates select="ancestor-or-self::tei:teiCorpus/tei:text/tei:front//tei:docTitle/tei:titlePart"/>
                </xsl:when>
                <xsl:when test="self::tei:teiCorpus">
                    <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type='subordinate')]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt">
                        <xsl:choose>
                            <xsl:when test="tei:title[@type='main']">
                                <xsl:apply-templates select="tei:title"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="tei:title"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="normalize-space(string($result)) = ''">(no title)</xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$result"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="desc">
        <xsl:comment>
            <xsl:apply-templates/>
        </xsl:comment>
    </xsl:template>
    <xsl:template name="copyrightStatement">
        <xsl:choose>
            <xsl:when test="/*/teiHeader/fileDesc/publicationStmt/availability">
                <div class="copyrightStatement">
                    <xsl:apply-templates select="/*/teiHeader/fileDesc/publicationStmt/availability"/>
                </div>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- copied and simplyfied from TEI's xhtml2/textstructure.xsl  to adapt for our needs -->
    <xsl:template name="stdfooter">
        <xsl:param name="style" select="'plain'"/>
        <xsl:param name="file"/>
        <div class="stdfooter">
            <xsl:if test="$linkPanel='true'">
                <div class="footer">
                    <xsl:if test="not($parentURL='')">
                        <a class="{$style}" href="{$parentURL}">
                            <xsl:value-of select="$parentWords"/>
                        </a> | </xsl:if>
                    <a class="{$style}" href="{$homeURL}">
                        <xsl:value-of select="$homeWords"/>
                    </a>
                    <xsl:if test="$searchURL">
                        <xsl:text>| </xsl:text>
                        <a class="{$style}" href="{$searchURL}">
                            <xsl:call-template name="i18n">
                                <xsl:with-param name="word">searchWords</xsl:with-param>
                            </xsl:call-template>
                        </a>
                    </xsl:if>
                    <xsl:if test="$feedbackURL"> | <a class="{$style}" href="{$feedbackURL}">
                            <xsl:call-template name="i18n">
                                <xsl:with-param name="word">feedbackWords</xsl:with-param>
                            </xsl:call-template>
                        </a>
                    </xsl:if>
                </div>
            </xsl:if>
            <address>
                <xsl:call-template name="copyrightStatement"/>
                <xsl:comment>
                    <xsl:text>
	  Generated </xsl:text>
                    <xsl:if test="not($masterFile='index')">
                        <xsl:text>from </xsl:text>
                        <xsl:value-of select="$masterFile"/>
                    </xsl:if>
                    <xsl:text> using an XSLT version </xsl:text>
                    <xsl:value-of select="system-property('xsl:version')"/> stylesheet
	  based on <xsl:value-of select="$teixslHome"/>
	  processed using <xsl:value-of select="system-property('xsl:vendor')"/>
	  on <xsl:call-template name="whatsTheDate"/>
                </xsl:comment>
            </address>
        </div>
    </xsl:template>
        
        <!-- This has been taken from xhtml2/figures.xsl to allow handling textgrid: and hdl: URIs in graphics references. I have only adapted the definition of $File at the beginning of the template, the rest has been copypasted verbatim. -->
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
        <desc>[html] display graphic file</desc>
    </doc>
    <xsl:template name="showGraphic">
        <xsl:variable name="File">
            <xsl:choose>
                <xsl:when test="self::tei:binaryObject"/>
                <xsl:when test="@url and ( starts-with(@url, 'textgrid:') or starts-with(@url, 'hdl:'))">
                    <xsl:value-of select="replace($graphicsURLPattern, '@URI@', @url)"/>
                </xsl:when>
                <xsl:when test="@url">
                    <xsl:value-of select="@url"/>
                    <xsl:if test="not(contains(@url,'.'))">
                        <xsl:value-of select="$graphicsSuffix"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Cannot work out how to do a graphic, needs a URL</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="Alt">
            <xsl:choose>
                <xsl:when test="tei:desc">
                    <xsl:for-each select="tei:desc">
                        <xsl:apply-templates mode="plain"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="tei:figDesc">
                    <xsl:for-each select="tei:figDesc">
                        <xsl:apply-templates mode="plain"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="tei:head">
                    <xsl:value-of select="tei:head/text()"/>
                </xsl:when>
                <xsl:when test="parent::tei:figure/tei:figDesc">
                    <xsl:for-each select="parent::tei:figure/tei:figDesc">
                        <xsl:apply-templates mode="plain"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="parent::tei:figure/tei:head">
                    <xsl:value-of select="parent::tei:figure/tei:head/text()"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$showFigures='true'">
                <xsl:choose>
                    <xsl:when test="@type='thumbnail'"/>
                    <xsl:when test="starts-with(@mimeType, 'video')">
                        <video src="{$graphicsPrefix}{$File}" controls="controls">
                            <xsl:if test="../tei:graphic[@type='thumbnail']">
                                <xsl:attribute name="poster">
                                    <xsl:value-of select="../tei:graphic[@type='thumbnail']/@url"/>
                                </xsl:attribute>
                            </xsl:if>
                        </video>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="sizes">
                            <xsl:if test="@width">
                                <xsl:text> width:</xsl:text>
                                <xsl:value-of select="@width"/>
                                <xsl:text>;</xsl:text>
                            </xsl:if>
                            <xsl:if test="@height">
                                <xsl:text> height:</xsl:text>
                                <xsl:value-of select="@height"/>
                                <xsl:text>;</xsl:text>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="i">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:choose>
                                        <xsl:when test="self::tei:binaryObject">
                                            <xsl:text>data:</xsl:text>
                                            <xsl:value-of select="@mimetype"/>
                                            <xsl:variable name="enc" select="if (@encoding) then @encoding else 'base64'"/>
                                            <xsl:text>;</xsl:text>
                                            <xsl:value-of select="$enc"/>
                                            <xsl:text>,</xsl:text>
                                            <xsl:copy-of select="text()"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat($graphicsPrefix,$File)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="alt">
                                    <xsl:value-of select="$Alt"/>
                                </xsl:attribute>
                                <xsl:call-template name="imgHook"/>
                                <xsl:if test="@xml:id">
                                    <xsl:attribute name="id">
                                        <xsl:value-of select="@xml:id"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:call-template name="makeRendition"/>
                            </img>
                        </xsl:variable>
                        <xsl:for-each select="$i/*">
                            <xsl:copy>
                                <xsl:copy-of select="@*[not(name()='style')]"/>
                                <xsl:choose>
                                    <xsl:when test="$sizes=''">
                                        <xsl:copy-of select="@style"/>
                                    </xsl:when>
                                    <xsl:when test="not(@style)">
                                        <xsl:attribute name="style" select="$sizes"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:attribute name="style" select="concat(@style,';' ,$sizes)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:copy>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <div class="altfigure">
                    <xsl:call-template name="i18n">
                        <xsl:with-param name="word">figureWord</xsl:with-param>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:for-each select="self::tei:figure|parent::tei:figure">
                        <xsl:number count="tei:figure[tei:head]" level="any"/>
                    </xsl:for-each>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$File"/>
                    <xsl:text> [</xsl:text>
                    <xsl:value-of select="$Alt"/>
                    <xsl:text>] </xsl:text>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        
        


    <!-- Spezialbehandlung für die Zeno-Variante der Fußnoten -->
    <xsl:template match="div[@type = 'footnotes']//note">
        <div class="note">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="note[@target]//ref[not(@target or @url)]">
        <a href="{ancestor::note[@target][1]/@target}">
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id" select="@xml:id"/>
            </xsl:if>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template match="/tei:teiCorpus">
        <html>
            <xsl:call-template name="addLangAtt"/>
            <head>
                <title>
                    <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()"/>
                </title>
                <xsl:call-template name="includeCSS"/>
                <xsl:call-template name="cssHook"/>
            </head>
            <body class="simple" id="TOP">
                <xsl:call-template name="bodyHook"/>
                <xsl:call-template name="bodyJavascriptHook"/>
                <div class="stdheader">
                    <xsl:call-template name="stdheader">
                        <xsl:with-param name="title">
                            <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </div>
                <xsl:call-template name="corpusBody"/>
                <xsl:call-template name="stdfooter"/>
                <xsl:call-template name="bodyEndHook"/>
            </body>
        </html>
    </xsl:template>
    <xsl:template name="corpusBody">
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>