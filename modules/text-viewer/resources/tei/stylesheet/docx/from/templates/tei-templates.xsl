<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:teidocx="http://www.tei-c.org/ns/teidocx/1.0" xmlns:mo="http://schemas.microsoft.com/office/mac/office/2008/main" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:iso="http://www.iso.org/ns/1.0" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:mv="urn:schemas-microsoft-com:mac:vml" xmlns:prop="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:tbx="http://www.lisa.org/TBX-Specification.33.0.html" xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships" version="2.0" exclude-result-prefixes="a cp dc dcterms dcmitype prop     iso m mml mo mv o pic r rel     tbx tei teidocx v xs ve w10 w wne wp"><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet"><desc><p> TEI stylesheet for converting Word docx files to TEI </p><p>This software is dual-licensed:

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
</p><p>Author: See AUTHORS</p><p>Id: $Id: tei-templates.xsl 9646 2011-11-05 23:39:08Z rahtz $</p><p>Copyright: 2008, TEI Consortium</p></desc></doc><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl"><desc>
    	simple teiHeader. For a more sophisticated header, think about overriding
        this template
    </desc></doc><xsl:template name="create-tei-header"><teiHeader><fileDesc><titleStmt><title><xsl:call-template name="getDocTitle"/></title><author><xsl:call-template name="getDocAuthor"/></author></titleStmt><editionStmt><edition><date><xsl:call-template name="getDocDate"/></date></edition></editionStmt><publicationStmt><p>unknown</p></publicationStmt><sourceDesc><p>Converted from a Word document </p></sourceDesc></fileDesc><encodingDesc><xsl:call-template name="generateAppInfo"/></encodingDesc><revisionDesc><change><date><xsl:text>$LastChangedDate: </xsl:text><xsl:value-of select="tei:whatsTheDate()"/><xsl:text>$</xsl:text></date><name><xsl:call-template name="getDocAuthor"/></name></change></revisionDesc></teiHeader></xsl:template><doc xmlns="http://www.oxygenxml.com/ns/doc/xsl"><desc>
     generates a section heading. If you need something specific, feel free
        to overwrite this template
    </desc></doc><xsl:template name="generate-section-heading"><xsl:param name="Style"/><head><xsl:apply-templates/></head></xsl:template></xsl:stylesheet>