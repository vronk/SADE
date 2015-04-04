xquery version "3.0";

module namespace dsk-t="http://semtonotes.github.io/SemToNotes/dsk-transcription";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function dsk-t:common() {

  <xsl:template match="tei:lb">
    <xsl:if test="not(exists(./ancestor::tei:cell)) or exists(./preceding-sibling::tei:lb)">
      <br xmlns="http://www.w3.org/1999/xhtml"/>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

};

declare function dsk-t:metadata($tei as element(tei:TEI), $projectdir as xs:string) {
let $xslt := if ($tei//tei:title[1] = 'Bellifortis')
                then doc($projectdir || '/xslt/SemToNotes-Bellifortis-meta.xslt')
                else doc($projectdir || '/xslt/SemToNotes-meta.xslt')
return 
    if ($tei/@corresp) then
      let $header := $dsk-data:teis[@n = $tei/@corresp]//tei:teiHeader
      let $corresp :=
      <tei:TEI>
        { $header }
        { $tei//tei:text }
        { $tei//tei:back }
      </tei:TEI>
      return
      transform:transform($corresp, $xslt, ())
    else 
      transform:transform($tei, $xslt, ())
};



declare function dsk-t:transcription($tei as element(tei:TEI), $type as xs:string, $projectdir as xs:string) {
    
let $xslt := 
                if ($tei//tei:title[1] = 'Bellifortis')
                    then doc($projectdir || '/xslt/SemToNotes-Bellifortis-'|| $type ||'.xslt')
                    else doc($projectdir || '/xslt/SemToNotes-'|| $type ||'.xslt')

return
    if (not($xslt//*)) then
        let $xslt :=
        <xsl:stylesheet 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:tei="http://www.tei-c.org/ns/1.0" 
                version="2.0">
                <xsl:output encoding="UTF-8" indent="yes"  method="xml"/>
                <xsl:preserve-space elements="*"/>
                <xsl:template match="/">
                    <xsl:apply-templates/>
                </xsl:template>
                <xsl:template match="tei:teiHeader"></xsl:template>
                <xsl:template match="tei:anchor">
                            <span xmlns="http://www.w3.org/1999/xhtml">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="@xml:id"/>
                                </xsl:attribute>
                                <xsl:value-of select="."/>
                            </span>
                </xsl:template>
                <xsl:template match="tei:body//text()">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="hover-text">
                        <xsl:value-of select="translate(., ' ', '&#160;')"/>
                    </span>
                </xsl:template>
        </xsl:stylesheet>
        return transform:transform($tei, $xslt, ())
        else
    transform:transform($tei, $xslt, ())
};

