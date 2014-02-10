xquery version "3.0";
module namespace fsearch = "http://sade/faceted-search" ;
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace bol="http://blumenbach-online.de/blumenbachiana";
declare namespace templates="http://exist-db.org/xquery/templates";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";


declare 
    %templates:wrap
function fsearch:results($node as node(), $model as map(*)) as map()* {

    let $page := xs:integer(request:get-parameter("page", "1"))

    let $target := config:param-value($model, "data-dir")
    let $hits := local:get-hits($model, $target)

    let $hitsordered :=
        for $hit in $hits
        order by ft:score($hit) descending
        return
           $hit
    
    let $num :=  xs:integer(config:module-param-value($model, "faceted-search",  "hits-per-page"))     
    let $pages := ceiling(count($hits) div $num)
    let $start := $page * $num - $num + 1
    
    return 
        map { 
            "facets" := fsearch:facets($model, $hits),
            "hits" := subsequence($hitsordered,$start,$num),
            "totalhits" := count($hits),
            "start" := $start,
            "page" := $page,
            "pages" := $pages
        }
};

declare 
    %templates:wrap
function fsearch:hitcount($node as node(), $model as map(*)) {
    $model("totalhits")
};

declare 
    %templates:wrap
function fsearch:hitstart($node as node(), $model as map(*)) {
    $model("start")
};

declare 
    %templates:wrap
function fsearch:hitend($node as node(), $model as map(*)) {
    let $num := xs:integer(config:module-param-value($model, "faceted-search",  "hits-per-page"))  
    let $res := $model("start") + $num - 1
    return if($res > $model("totalhits")) 
        then $model("totalhits")
        else $res
};

declare 
    %templates:wrap
function fsearch:page($node as node(), $model as map(*)) {
    $model("page")
};

declare 
    %templates:wrap
function fsearch:pages($node as node(), $model as map(*)) {
    $model("pages")
};

declare function fsearch:result-title($node as node(), $model as map(*)) {
    let $relloc := "/xml/data/" || util:document-name($model("hit"))
    let $absloc := config:param-value($model, "data-dir") || $relloc
    let $viewdoc := config:module-param-value($model,'faceted-search','viewer.html')
 
    return 
        <a href="{$viewdoc}{$relloc}">
            {
                for $titleQuery in $model("config")//module[@key="faceted-search"]/param[@key="result-title"]//xpath
                return util:eval("$model('hit')" || $titleQuery)
            }
        </a>
};

declare function fsearch:result-img($node as node(), $model as map(*)) {
    (:  TODO: could better be done in template, than by param :)
    if(xs:boolean(config:module-param-value($model, "faceted-search", "thumbnail"))) then
        (: TODO image-xpath should be configured by conf.xml:)
        let $src := $model("hit")//bol:kerndaten/bol:mediafiles//bol:mediafile[1]/@file_uri || ($model("hit")//tei:pb)[1]/@facs
        return
            if(string-length($src) > 0) then
                <img src="{config:param-value($model, "digilib.url")}{$src}{config:param-value($model, "digilib.thumbnailparam")}"/>
            else
                ()
        else
            ()
};

declare function fsearch:result-kwic($node as node(), $model as map(*)) {

    let $hit := $model("hit")
    let $expanded := kwic:expand($hit)
    order by ft:score($hit) descending
    return
        for $i in 1 to xs:integer(config:param-value($model, "kwic-hits"))
        return
            if(($expanded//exist:match)[$i]) then
                kwic:get-summary($expanded, ($expanded//exist:match)[$i], <config width="40"/>)
            else ()
};

declare function fsearch:result-source($node as node(), $model as map(*)) {

    let $docloc := config:param-value($model, "data-dir") || "/xml/data/" || util:document-name($model("hit"))
    return 
        <a href="/exist/rest{$docloc}">{$node/@class, $node/* }</a>
};

declare 
(:    %templates:wrap:)
function fsearch:result-id($node as node(), $model as map(*)) {
    element { node-name($node) } { attribute name { util:document-name($model("hit")) }, $node/@*, $node/* }
};

declare function fsearch:facets($model as map(*), $hits) as map() {
    
    map:new( 
        for $facet in $model("config")//module[@key="faceted-search"]//facet
        return
            map:entry(xs:string($facet/@key), local:facet($model, $hits, $facet/@key, $facet//xpath/text()))
    )
};

declare function fsearch:list-facets($node as node(), $model as map(*)) as map(*){
    map { "facetgroups" := $model("facet") }
};

declare 
function fsearch:facet-title($node as node(), $model as map(*)) {
    <li>{map:keys($model("facet"))}</li>
};


declare function fsearch:facet($node as node(), $model as map(*)) as item()* {

    for $facet in $model("config")//module[@key="faceted-search"]//facet
        return
            <li><strong>{xs:string($facet/@title)}</strong>
                <ul class="hideMore">{local:deselected-for-key($model, xs:string($facet/@key))}{$model("facets")(xs:string($facet/@key))}</ul>
            </li>
                
};

declare function local:facet($model as map(*), $hits as node()*, $key as xs:string, $types as xs:string*) as node()* {
    
    let $query := request:get-parameter("q", ())
    let $facetReq := local:facet-query-from-request()
    
    (: the link to the html page displaying this module :)
    let $search-html := config:param-value($model,'exist-resource')

    (:construct xpath, e.g. $hits//tei:persName | $hits//bol:a0 :)
    let $fqueries := for $type in $types
        return concat("$hits", "//", $type)
        
    let $fquery := string-join($fqueries, " |")

    (: normalize strings :)
    let $unnormal := for $x in util:eval($fquery)
        return <un>{normalize-space($x)}</un>
    
    let $deselected := local:deselected-for-key($model, $key)
        
    for $facet in distinct-values($unnormal)
        let $freq :=  count($unnormal[. eq $facet])
        order by $freq descending
        return
            if(local:facetSelected($key, $facet))
               then 
                   let $facetRemoveQuery := replace($facetReq, $key || ":" || xmldb:encode($facet) || "," , "")
                   return 
                       <li class="facetSelected">
                            <a class="facet-minus" href="{$search-html}?q={$query}&amp;facet={$facetRemoveQuery}">-</a>
                            {$facet} ({$freq}) 
                        </li>
               else 
                   <li>
                       <a class="facet-minus" href="{$search-html}?q={$query}&amp;facet={$key}:!{xmldb:encode($facet)},{$facetReq}">-</a>
                       <a href="{$search-html}?q={$query}&amp;facet={$key}:{xmldb:encode($facet)},{$facetReq}">{$facet}</a> ({$freq})
                   </li> 
            
        

};

declare function local:deselected-for-key($model, $key as xs:string) {
    
    let $query := request:get-parameter("q", ())
    
    (: the link to the html page displaying this module :)
    let $search-html := config:param-value($model,'exist-resource')
    
    let $facetReq := local:facet-query-from-request()
    
    for $fparts in tokenize($facetReq, ",")
        let $parts := tokenize($fparts, ":")
        return if($parts[1] eq $key) then
            if(starts-with($parts[2], "!"))
                    then
                        let $facetRemoveQuery := replace($facetReq, $key || ":" || $parts[2] || "," , "")
                        return 
                            <li class="facet-deselected">
                                <a class="facet-plus" href="{$search-html}?q={$query}&amp;facet={$facetRemoveQuery}">+</a>
                                {xmldb:decode(substring-after($parts[2], "!"))}
                            </li>
                    else
                        ()
            else ()
};

declare function local:get-hits($model as map(*), $target as xs:string) as node()*{
    
    let $query := request:get-parameter("q", ())
    let $fxquery := local:construct-facet-query($model)
 
    let $xqueries :=  for $query-root in $model("config")//module[@key="faceted-search"]/param[@key="query-root"]//xpath
        return 
            if($query) then
                "collection($target)" || $query-root || $fxquery || "[ft:query(., $query)]"
            else
                "collection($target)" || $query-root || $fxquery
 
    let $xquery := string-join($xqueries, " | ")
    return util:eval($xquery)
    
};

declare function local:construct-facet-query($model as map(*)) as xs:string {

    let $facet := local:facet-query-from-request()
    let $fxquery := 
        if ($facet) then
            for $fquery in tokenize($facet, ",")
                let $parts := tokenize($fquery, ":")
                let $select := 
                    for $xpath in $model("config")//module[@key="faceted-search"]//facet[@key = $parts[1]]//xpath
                       
                        let $val := xmldb:decode($parts[2])
                            let $op := if(starts-with($val, "!")) 
                                then " ne "
                                else " eq "
                        
                        let $val := replace($val, "!", "")
                        
                        return if(starts-with($xpath, ".") or starts-with($xpath, "/"))
                            then $xpath || $op || "'" || $val || "'" 
                            else ".//" || $xpath || $op || "'" || $val || "'" 
                            
                return 
                    if(not(empty($select))) then "[" || string-join($select, " or ") || "]"
                    else ()
        else
            ()

    return string-join($fxquery, "")
};

(: we need the facet uri encoded, so request-get parameter does not work :)
declare function local:facet-query-from-request() {
    (: remove trailing questionary mark :)
    let $querystring := substring(request:get-query-string(),1)
    (: tokenize at ampersand :)
    return for $part in tokenize($querystring, codepoints-to-string(38))
        let $query := tokenize($part, "=")
            return if ($query[1] eq "facet") then
                $query[2]
            else 
                ()

};

declare function local:facetSelected($key as xs:string, $value as xs:string) as xs:boolean {
    
    let $r := for $token in tokenize(local:facet-query-from-request(), ",")
        let $parts := tokenize($token, ":")
                return if($parts[1]=$key and xmldb:decode($parts[2])=$value)
                    then true()
                else ()
    
    return boolean($r)
};




