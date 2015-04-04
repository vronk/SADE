xquery version "3.0";
module namespace mviewer = "http://sade/multiviewer" ;
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xlink="http://www.w3.org/1999/xlink";

import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
import module namespace md="http://exist-db.org/xquery/markdown" at "/apps/markdown/content/markdown.xql";
import module namespace dsk-view="http://semtonotes.github.io/SemToNotes/dsk-view"
  at './SemToNotes.xqm';

(:import module namespace console="http://exist-db.org/xquery/console";:)

declare function mviewer:show($node as node(), $model as map(*), $id as xs:string) as item()* {

    let $data-dir := config:param-value($model, 'data-dir')
    let $docpath := $data-dir || '/' || $id

    return
        switch(tokenize($id, "\.")[last()])
            case "xml"
            return
                if (contains($id, '/tile/')) then mviewer:renderTILE($node, $model, $docpath)
                else
                mviewer:renderXml($node, $model, $docpath)
            case "md"
                return mviewer:renderMarkdown($node, $model, $docpath)
            case "html"
                return doc($docpath)
            default
                return mviewer:renderXml($node, $model, $docpath)
};

declare function mviewer:renderMarkdown($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    
    let $inputDoc := util:binary-doc( $docpath )
    let $input := util:binary-to-string($inputDoc)
    return
        md:parse($input)
        
};

declare function mviewer:renderXml($node as node(), $model as map(*), $docpath as xs:string) as item()* {

    let $doc := doc($docpath)
    
    (:todo: if tei :)
(:    let $page := xs:integer(request:get-parameter("page", -1)):)
(:    let $doc := mviewer:tei-paging($doc, $page):)
    let $html := mviewer:choose-xsl-and-transform($doc, $model)
    
    return if(local-name($html[1]) = "html") then
            <div class="teiXsltView">{$html/xhtml:body/*}</div>
        else
            <div class="teiXsltView">{$html}</div>
};
declare function mviewer:renderTILE($node as node(), $model as map(*), $docpath as xs:string) as item()* {
let $doc := doc($docpath)
let $i := $doc//tei:link[starts-with(@targets, '#shape')][1]
let $shape := substring-before(substring-after($i/@targets, '#'), ' ')
let $teiuri :=  if(contains(substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a'), '.'))
                                then substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a')
                                else 
                                    (: todo: find lates revision in collection :)
                                    substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a') || '.0'
let $imageuri := $doc//svg:image[following::svg:rect/@id eq $shape]/string(@xlink:href),
    $imgwidth := $doc//svg:image/@width/number()

let $teidoc := doc(substring-before($docpath, 'tile') || 'data/' || $teiuri || '.xml')/*
let $html := dsk-view:render($teidoc, $imageuri, $imgwidth, $docpath)//xhtml:body/*

return <div id="stn">
   {$html}
    </div>
};

declare function mviewer:renderTILEold($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    let $sid := doc(config:param-value($model, 'textgrid.webauth') || '?authZinstance='|| config:param-value($model, 'textgrid.authZinstance') || '&amp;loginname=' || config:param-value($model, 'textgrid.user') || '&amp;password=' || config:param-value($model, 'textgrid.password'))//xhtml:meta[@name='rbac_sessionid']/string(@content),
        $doc := doc($docpath)
    return
        <div>
        <!-- Achtung: Bootstrap! Hier wird nicht sauber zwischen Layout und Daten getrennt! -->
        <!-- TODO: Get Session ID from tgclient instead of $sid in this function -->
            {for $i in $doc//tei:link[starts-with(@targets, '#shape')]
                let $shape := substring-before(substring-after($i/@targets, '#'), ' '),
                    $teiuri :=  if(contains(substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a'), '.'))
                                then substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a')
                                else 
                                    (: todo: find lates revision in collection :)
                                    substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a') || '.0',
                                
                    $imageuri := $doc//svg:image[following::svg:rect/@id eq $shape]/string(@xlink:href),
                    $offset := '&amp;wx=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@x), '%')) div 100 || '&amp;wy=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@y), '%')) div 100,
                    $range := '&amp;ww=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@width), '%')) div 100 || '&amp;wh=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@height), '%')) div 100
                return
                    <div class="row">
                        <div class="col-md-6">
                            <img style="padding-top:10px" alt="detail" src="{config:param-value($model, 'textgrid.digilib') || '/'  || $imageuri};sid={$sid}?{config:param-value($model, 'textgrid.digilib.tile') || $range || $offset}" />
                        </div>
                        <div class="col-md-6">
                            {let    $data-dir := config:param-value($model, 'data-dir'),
                                    $docpath := $data-dir || '/xml/data/' || $teiuri || '.xml'
(:                                    TODO: Soll /xml/data/ aus config hervorgehen? :)
                            return
                                if (doc($docpath) != '')
                                then
                                    if(ends-with($i/@targets, 'end'))
                                    then 
                                        let $start := substring-after(substring-after(substring-before($i/string(@targets), '_start'), '#'), '#') || '_start',
                                            $end := substring-after(substring-after(substring-after(substring-before($i/string(@targets), '_end'), '#'), '#'), '#') || '_end'                                        return mviewer:choose-xsl-and-transform((util:parse(util:get-fragment-between(doc($docpath)//tei:anchor[@xml:id = $start], doc($docpath)//tei:anchor[@xml:id = $end], true(), true()))), $model)
                                    else 
                                        doc($docpath)//*[@xml:id = substring-after(substring-after($i/string(@targets), '#'), '#')]
                                else <span>The requested document is not available. Please resubmit/republish the object <b>{$teiuri}</b>.</span>
                            }
                        </div>
                    </div>
            }
            <br/>
            <div class="row">
                <button type="button" class="btn btn-info" data-toggle="collapse" data-target="#tile">show TILE-Object</button>
                <div id="tile" class="collapse out"><pre>{serialize($doc)}</pre></div>
            </div>
        </div>
};

(: TODO: tei-specific :)
declare function mviewer:tei-paging($doc, $page as xs:integer) {
    
    let $doc := if ($page > 0 and ($doc//tei:pb)[$page]) then
            util:parse(util:get-fragment-between(($doc//tei:pb)[$page], ($doc//tei:pb)[$page+1], true(), true()))
            (: Kann das funktionieren, wenn page als integer übergeben wird? müsste man nicht tei:pb/@n auswerten? :)
        else
            $doc
            
    return $doc
    
};

declare function mviewer:choose-xsl-and-transform($doc, $model as map(*)) {
    
    let $namespace := namespace-uri($doc/*[1])
    let $xslconf := $model("config")//module[@key="multiviewer"]//stylesheet[@namespace=$namespace][1]

    let $xslloc := if ($xslconf/@local = "true") then
            config:param-value($model, "project-dir")|| "/" ||  $xslconf/@location
        else
            $xslconf/@location
    
    let $xsl := doc($xslloc)
    let $html := transform:transform($doc, $xsl, $xslconf/parameters)
    
    return $html
};
