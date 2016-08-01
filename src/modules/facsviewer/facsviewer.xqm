xquery version "3.0";

module namespace facs="http://www.oeaw.ac.at/icltt/cr-xq/facsviewer";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
(:import module namespace fx="http://www.functx.com" at "lib/functx.xqm";:)
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace ngram="http://exist-db.org/xquery/ngram";

(:~
 : Provides functions for extracting fragments ("pages") from xml/TEI-documents 
 : and parallel views with facsimile. 
 :)

declare function facs:common-ancestor($ms1 as element(),$ms2 as element()) as node()* {
    let $tree:=$ms1/ancestor::*[some $x in descendant::* satisfies $x is $ms2][1]
    return $tree
};

declare function facs:milestone-chunk-ns($ms1 as element(),$ms2 as element()) as node()* {
    let $tree:=facs:common-ancestor($ms1,$ms2)
    return 
        if (exists($tree)) 
        then facs:milestone-chunk-ns($ms1, $ms2, $tree) 
        else ()
};

(: see http://wiki.tei-c.org/index.php/Milestone-chunk.xquery :)
declare function facs:milestone-chunk-ns($ms1 as element(), $ms2 as element(), $node as node()*) as node()* {
    typeswitch ($node)
        case element() return
            if ($node is $ms1) 
            then $node
            else 
                if ( some $n in $node/descendant::* satisfies ($n is $ms1 or $n is $ms2) )
                then
                    element { QName(namespace-uri($node), name($node)) }
                            {(   
                                $node/@*,
                                for $i in $node/node()
                                return facs:milestone-chunk-ns($ms1, $ms2, $i) )}
                else 
                    if ( $node >> $ms1 and $node << $ms2 ) 
                    then $node
                    else ()
        case attribute() return 
            $node 
        default return 
            if ( $node >> $ms1 and $node << $ms2 ) 
            then $node
            else ()
};

(:declare function facs:page-by-matches($chunk) as node()* {
    let $matches-in-chunk:= util:expand($chunk)//exist:match,
        $pbs:=              facs:page-ids-from-matches($matches-in-chunk)
    return 
        for $p in $pbs
            let $pb1:=  $p,
                $pb2:=  $pb1/following::pb[1]
            return 
                <div type="page">{facs:milestone-chunk-ns($pb1,$pb2)}</div>
}; :)

(: main function: returns fragments of original pages possibly with highlighted ft:/ngram:matches. 
   important: $input must be a reference to the stored node() otherwise util:get-fragment-between
   won't work. :)
declare function facs:page($hit as node()?) as element(tei:div)* {
	let $default-expand:= util:expand($hit)
    let $match:=
	   typeswitch ($default-expand)
	       case attribute()    return ngram:add-match($default-expand)
  	       default             return $default-expand
  	let $page-ids-from-hit:= facs:page-ids-from-hit($hit)   
  	
  	
    (: get the nearest page break for the match - we support the following situations: 
        a) $input is a big chunk (maybe tei:text) with a lot of exist:matches 
        b) $input is a smaller chunk with one or a few exist:matches (mabe tei:p[ft:query(.,'...')])
        c) $input is a pb element itself
        
        depending on this we have to expect the relevant pb-Elements in different 
        positions: either 
            a) for sure inside of $input, 
            b) inside of OR before $input (tei:p _may_ have a pb before )
    :)	       
    let $from-expanded:= switch (true())
                            case ($input/self::pb)      return $input 
                            case ($match//exist:match)  return $match//exist:match/preceding::pb[1]
                            case ($match//pb)           return $match//pb[1]
                            default                     return $match/preceding::pb[1]
        
    let $from-id:=  if ($from-expanded/@xml:id)
                    then $from-expanded/@xml:id
                    else
                        if ($from-expanded/@facs)
                        then $from-expanded/@facs
                        else (), 
        (: get the original (stored) pb-Element via @xml:id or @facs :)
        $from:= $input//pb[@xml:id eq $from-id or @facs eq $from-id],
        (: fallback to positional lookup just in case pbs have no id or facs attribute - possibly costy :)
        $from-via-position:=
            if (exists($from)) then () 
            else 
                let $count-prec-pbs:=$from-expanded/count(preceding::pb)
                return $input//pb[position() eq xs:int($count-prec-pbs)+1],
        $to:=   $from/following::pb[1],
        $frag:= util:get-fragment-between($from,$to,true(),true()),
        $parse:=util:parse($frag)
        (:$pbInParse:=$parse//pb[1],:)
        (:$page:= facs:descend-to($parse, $pbInParse):)
    return 
        <div xmlns="http://www.tei-c.org/ns/1.0" type="page">{
            $from/@*,
            (:$page/*:)
            $parse//*[count(*)>1][1]
        }</div>
};

declare function facs:page-by-id($pageid as xs:string,$text as element()) as element()* {
    let $pb1:=      $text//pb[@facs = $pageid],
        $pb2:=      $pb1/following::pb[1],
        $frag:=     util:parse(util:get-fragment-between($pb1,$pb2,true(),true())),
        $content:=  $frag//*[count(*)>1][1]
    return facs:wrap-page($content)
};  

declare function facs:page-from-hit ($pageid as xs:string, $hit as element()) as element()* {
    let $expand:=           util:expand($hit)
    let $ms1:=              $expand//pb[@facs = $pageid],
        $ms2:=              $ms1/following::pb[1],
        $common:=           $ms1/ancestor::*[some $x in descendant::* satisfies $x is $ms2][1],
        $page-content:=     if (exists($ms1)) 
                            then facs:milestone-chunk-ns($ms1,$ms2,$common)
                            else ()
    return 
        if (exists($page-content)) 
        then facs:wrap-page($page-content)
        else ()
};

declare function facs:wrap-page($page-content as node()*) as element() {
    <div type="page">{$page-content}</div>
}; 

declare function facs:pages-from-hit ($hit as element()) as node()* {
    facs:pages-from-hit($hit, 1, 10)
};

declare function facs:pages-from-hit ($hit as element(), $startAtPage as xs:int, $howManyPages as xs:int) as node()* {
    let $matches:=  kwic:get-matches($hit),
        $pbs:=      distinct-values($matches!facs:page-id-from-match(.)),
        $subseq:=   subsequence($pbs,$startAtMatch,$howManyMatches)
    return ()
};


declare function facs:pb-from-match($match as element(exist:match)) as element()? {
    let $pbs := ($match/preceding::pb[1],$match/preceding::tei:pb[1])
    return $pbs[1]
};

declare function facs:page-id-from-match($match as element(exist:match)) as xs:string {
    let $pb:=   facs:pb-from-match($match)
    let $ids := ($pb/@xml:id,$pb/@facs,$pb/@n)
    return $ids[1]
};

declare function facs:pages-from-hit ($hit as element()) as map? {
    let $matches:=  util:expand($hit)//exist:match
    return
        if (exists($matches))
        then
            map:new(
                for $m in $matches 
                group by $pid:=$m/preceding::pb[1]/@facs
                return map:entry($pid, $m)
            )
        else ()
}; 

declare function facs:highlight-matches($page as element(tei:div)?) as element(tei:div)? {
    ()
}; 

(: returns distinct resourcefragment-pids = page-ids from a ft-/ngram-query :)
declare function facs:page-ids-from-hit($hit as element()) as xs:string* {
    (kwic:get-matches($hit)/preceding::pb[1]/@facs)
};

declare function facs:filename-to-path($filename as xs:string, $x-context, $config){
    let $facs-path:=    config:param-value((), $config, 'facsviewer', '', "facs.path"),
        $facs-prefix:=  if (config:param-value($config, "facs.prefix")) then config:param-value($config, "facs.prefix") else '',
        $facs-suffix:=  if (config:param-value($config, "facs.suffix")) then config:param-value($config, "facs.suffix") else ''
    return
        concat(
            (if (not(matches($facs-path,concat($x-context,'/?$'))))
            then $facs-path||$x-context||'/'
            else (if (ends-with($facs-path,'/')) then $facs-path else $facs-path||'/')),
            $facs-prefix,$filename,$facs-suffix
        )
};