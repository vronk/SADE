xquery version "3.0";
module namespace mviewer = "http://sade/multiviewer" ;
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
import module namespace md="http://exist-db.org/xquery/markdown" at "/apps/markdown/content/markdown.xql";


declare function mviewer:show($node as node(), $model as map(*), $id as xs:string) as item()* {

    let $data-dir := config:param-value($model, 'data-dir')
    let $docpath := $data-dir || '/' || $id

    return
        switch(tokenize($id, "\.")[last()])
            case "xml"
                return mviewer:renderXml($node, $model, $docpath)
            case "md"
                return mviewer:renderMarkdown($node, $model, $docpath)
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
    let $page := xs:integer(request:get-parameter("page", -1))
    let $doc := mviewer:tei-paging($doc, $page)
    let $html := mviewer:choose-xsl-and-transform($doc, $model)
    
    return if(local-name($html[1]) = "html") then
            <div class="teiXsltView">{$html/xhtml:body/*}</div>
        else
            <div class="teiXsltView">{$html}</div>

};

(: TODO: tei-specific :)
declare function mviewer:tei-paging($doc, $page as xs:integer) {
    
    let $doc := if ($page > 0 and ($doc//tei:pb)[$page]) then
            util:parse(util:get-fragment-between(($doc//tei:pb)[$page], ($doc//tei:pb)[$page+1], true(), true()))
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

