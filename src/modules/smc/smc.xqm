xquery version "1.0";
module namespace smc = "http://clarin.eu/smc";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "../../core/repo-utils.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "../aqay/crday.xqm";
import module namespace fcs = "http://clarin.eu/fcs/1.0" at "../fcs/fcs.xqm";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $smc:termsets := doc("data/termsets.xml");
declare variable $smc:dcr-terms := doc("data/dcr-terms.xml");
declare variable $smc:cmd-terms := doc("data/cmd-terms.xml");
declare variable $smc:cmd-terms-nested := doc("data/cmd-terms-nested.xml");
declare variable $smc:dcr-cmd-map := doc("data/dcr-cmd-map.xml");
declare variable $smc:xsl-smc-op := doc("xsl/smc_op.xsl");
declare variable $smc:xsl-terms2graph := doc("xsl/terms2graph.xsl");
declare variable $smc:xsl-graph2json := doc("xsl/graph2json-d3.xsl");
declare variable $smc:structure-file  := '_structure';
declare variable $smc:config := config:module-config('smc');


(:~ mappings overview
only process already created maps (i.e. (for now) don't run mappings on demand, 
because that would induce ay-xml - which takes very long time and is not safe 
:)
declare function smc:mappings-overview($config, $format as xs:string) as item()* {

let $cache_path := repo-utils:config-value($config, 'cache.path'),
    $mappings := collection($cache_path)/map[*]
    


let $overview := if (contains($format, "table")) then
                       <table class="show"><tr><th>index |{count(distinct-values($mappings//index/xs:string(@key)))}|</th>
                         {for $map in $mappings return <th>{concat($map/@profile-name, ' ', $map/@context, ' |', count($map/index), '/', count($map/index/path), '|')}</th> } 
                         </tr>                    
                        { for $ix in distinct-values($mappings//index/xs:string(@key))
                             let $datcat := $smc:dcr-terms//Concept[Term[@type='id']/concat(@set,':',text()) = $ix],
                                  $datcat-label := $datcat/Term[@type='mnemonic'],
                                 $datcat-type := $datcat/@datcat-type,
                                 $index-paths := $mappings//index[xs:string(@key)=$ix]/path
                             return <tr><td valign="top">{(<b>{$datcat-label}</b>, concat(' |', count($index-paths/ancestor::map), '/', count($index-paths), '|'), <br/>, concat($ix, ' ', $datcat-type))}</td>
                                        {for $map in $mappings
                                                 let $paths := $map/index[xs:string(@key)=$ix]/path
                                        return <td valign="top"><ul>{for $path in $paths
                                                            return <li title="{$path/text()}" >{tokenize($path/text(), '\.')[last()]}</li>
                                                         }</ul></td> 
                                         }
                                      </tr>
                           }
                        </table>
                    else 
                       <ul>                  
                        { for $ix in distinct-values($mappings//index/xs:string(@key))
                             let $datcat := $smc:dcr-terms//Concept[Term[@type='id']/concat(@set,':',text()) = $ix],
                                  $datcat-label := $datcat/Term[@type='mnemonic'],
                                 $datcat-type := $datcat/@datcat-type
                             return <li><span>{(<b>{$datcat-label}</b>, <br/>, concat($ix, ' ', $datcat-type))}</span>
                                        {for $map in $mappings
                                                 let $paths := $map/index[xs:string(@key)=$ix]/path
                                        return <td valign="top"><ul>{for $path in $paths
                                                            return <li>{$path/text()}</li>
                                                         }</ul></td> 
                                         }
                                      </li>
                           }
                        </ul> 
                    
       return if ($format eq 'raw') then
                   $overview
                else            
                   repo-utils:serialise-as($overview, $format, 'html', $config, ())                   
};


(:~
generates mappings for individual collections, 
by invoking get-mappings for each collection individually (as x-context)

@returns a summary of generated stuff
:)
declare function smc:gen-mappings($config, $x-context as xs:string+, $run-flag as xs:boolean, $format as xs:string) as item()* {

(:         let $mappings := doc(repo-utils:config-value($config, 'mappings')),:)
    let $context-mapping := fcs:get-mapping('',$x-context, $config),
          (: if not specific mapping found for given context, use whole mappings-file :)
          $mappings := if ($context-mapping/xs:string(@key) = $x-context) then $context-mapping 
                    else doc(repo-utils:config-value($config, 'mappings')) 
    
   
   let $mapsummaries := for $map in $mappings/descendant-or-self::map[@key]
                let $map := smc:get-mappings($config, $map/xs:string(@key), $run-flag, 'raw')
                return <map count_profiles="{count($map/map)}" count_indexes="{count($map//index)}" >{($map/@*,
                            for $profile-map in $map/map 
                            return <map count_indexes="{count($profile-map/index)}" count_paths="{count($profile-map/index/path)}">{$profile-map/@*}</map>)}</map>
(:                return $map:)
   
   return <map empty_maps="{count($mapsummaries[xs:integer(@count_indexes)=0])}">{$mapsummaries}</map>

};

(:~ create and store mapping for every profile in given nodeset 
expects the CMD-format

calls crday:get-ay-xml which may be very time-consuming

@param $format [raw, htmlpage, html] - raw: return only the produced table, html* : serialize as html
@param $run-flag if true - re-run even if in cache
:)
declare function smc:get-mappings($config, $x-context as xs:string+, $run-flag as xs:boolean, $format as xs:string) as item()* {

let $scan-profiles :=  fcs:scan('cmd.profile', $x-context, 1, 50, 1, 1, "text", '', $config),
    $target_path := repo-utils:config-value($config, 'cache.path')

(: for every profile in the data-set :)
let $result := for $profile in $scan-profiles//sru:term
                    let $profile-name := xs:string($profile/sru:displayTerm)    
                    let $map-doc-name := repo-utils:gen-cache-id("map", ($x-context, $profile-name), '')
                    
                    return 
                        if (repo-utils:is-in-cache($map-doc-name, $config) and not($run-flag)) then 
                            repo-utils:get-from-cache($map-doc-name, $config)
                        else
                            let $ay-data := crday:get-ay-xml($config, $x-context, $profile-name, $crday:defaultMaxDepth, $run-flag, 'raw')    
                            let $mappings := <map profile-id="{$profile/sru:value}" profile-name="{$profile-name}" context="{$x-context}"> 
                                                {smc:match-paths($ay-data, $profile)}
                                               </map>
                            return repo-utils:store-in-cache($map-doc-name, $mappings, $config)
    
   return if ($format eq 'raw') then
                   <map context="{$x-context}" >{$result}</map>
                else            
                   repo-utils:serialise-as(<map context="{$x-context}" >{$result}</map>, $format, 'default', $config, ())  
};

(:~ expects a summary of data, matches the resulting paths with paths in cmd-terms
and returns dcr-indexes, that have a path in the input-data

be kind and try to map on profile-name if profile-id not available (or did not match) 
:)
declare function smc:match-paths($ay-data as item(), $profile as node()) as item()* {

let $data-paths := $ay-data//Term/replace(replace(xs:string(@path),'//',''),'/','.')

let $profile-id := xs:string($profile/sru:value)
let $profile-name := xs:string($profile/sru:displayTerm)    
  
let $match-by-id := if ($profile-id ne '') then $smc:cmd-terms//Termset[@id=$profile-id and @type="CMD_Profile"]/Term[xs:string(@path) = $data-paths ] else ()
let $match := if (exists($match-by-id)) then $match-by-id
                    else $smc:cmd-terms//Termset[xs:string(@name)=$profile-name and @type="CMD_Profile"]/Term[xs:string(@path) = $data-paths ] 

let $mapping := for $datcat in distinct-values($match//xs:string(@datcat))
                    let $key := smc:shorten-uri($datcat) 
                    return <index key="{$key}" >
                                { for $path in $match[xs:string(@datcat) = $datcat]/xs:string(@path)                                    
                                    return <path count="">{$path}</path>
                                }
                            </index>
return $mapping
};

(:~ Generates a termset that contains only terms from termset1, that are not in termset2
expects ids that resolve to Termsets as input
:)
declare function smc:diff($id1 as xs:string, $id2 as xs:string, $config) as item()* {

    let $terms1 := smc:resolve($id1, $config)
    let $terms2 := smc:resolve($id2, $config)
  
let $diff-raw :=  $terms1//Term[not(data(@path) = $terms2//Term/data(@path))]
(: remove not top matching Terms - when deeper structures (dont) match, every level is processed and copied - creating duplicates :) 
let $diff-clean := $diff-raw[not(ancestor::Term intersect $diff-raw)]
let $diff :=  <Termset key="diff" count="{count($diff-clean/descendant-or-self::Term)}">{ $diff-clean }</Termset>

return $diff

};

(:~ try to resolve against smc-data, then cache
(to resolve from cache appropriate config has to be given as param:)

declare function smc:resolve($id as xs:string, $config) as item()?  {

    (:
    http://www.w3.org/TR/xpath-functions/#func-doc-available
    If $uri is not a valid URI according to the rules applied by the implementation of fn:doc, an error is raised [err:FODC0005].    
    if (doc-available($id)) then doc($id)
        else:) 
        
            let $terms := smc:list($id)
            
            return if ($terms/* instance of element(Termset)) then $terms
                        else repo-utils:get-from-cache($id, ($config, $smc:config)[1])
                        

};

(:~
 : List available contexts or terms
 : @param $context if $context = ('*', 'top') - lists available termsets. 
 :                  if $context = $termset-identifier then  lists available terms of given termset.
 : @param $format format of the response, allowed values: currently only xml, planned: json, skos/rdf?
 :)
declare function smc:list($context) {
      (: separate handling for isocat, because of lang :)

(:<answer term="{$context}" relset="{$format}" >
{ diag:diagnostics('unsupported-param-value',("context=", $context)) }
</answer>
:)
 let $data :=
   if ($context = ('*','top')) then
        $smc:termsets
   else if (starts-with($context, 'isocat')) then        
        let $lang := if (starts-with($context, 'isocat-')) then substring-after($context, 'isocat-') else ''
        let $terms := $smc:dcr-cmd-map//Term[@set='isocat' and (@xml:lang=$lang or ($lang='' and @type='mnemonic'))]
       return <Termset set="{$context}" xml:lang="{$lang}" count="{count($terms)}">
            { for $term in $terms 
                  return  <Term concept-id="{$term/ancestor::Concept/data(@id)}" >{($term/@*,$term/text())}</Term>
             }            
          </Termset>       
    else
   if ($context= 'cmd-profiles') then
            <Termset key="{$context}">   
    { $smc:termsets//Termset[key/text() = $context]/* }            
            </Termset>
    else
   if (exists($smc:cmd-terms-nested//Termset[data(@id) eq $context])) then
            <Termset key="{$context}">   
    { $smc:cmd-terms-nested//Termset[data(@id) eq $context] }            
            </Termset>
  
    else if (not(exists($smc:termsets//Termset[key=$context or @type=$context]))) then 
(:           diag:diagnostics('unsupported-param-value',("context=", $context)):)            
         <diagnostics>
            <diagnostic xmlns="http://www.loc.gov/zing/srw/diagnostic/" key="unsupported-param-value">
            <uri>info:srw/diagnostic/1/6</uri>
            <details>context= {$context}</details>
            <message>Unsupported parameter value</message>
            </diagnostic>
         </diagnostics>

    
    else
        let $terms := $smc:dcr-cmd-map//Term[@set=$context]
(:        format="{$format}" :)
        return <Termset set="{$context}" count="{count($terms)}">             
            { for $term in $terms
                  return  <Term concept-id="{$term/ancestor::Concept/data(@id)}" >{($term/@*,$term/text())}</Term>
            }
        </Termset>
            
  return $data

};

(:~ replace url_prefix in the url by the short key
based on definitions in $smc:termsets
:)
declare function smc:shorten-uri($url as xs:string) as xs:string {    
    let $termset := $smc:termsets//Termset[url_prefix][starts-with($url, url_prefix)][$url ne '']
    let $url-suffix := substring-after ($url, $termset/url_prefix)    
    return if (exists($termset)) then concat($termset/key, ':', $url-suffix) else $url
};

(:~ 
:)
declare function smc:gen-graph($config, $x-context as xs:string+) as item()* {

    let $model := map { "config" := $config}
    let $cache-path := config:param-value($model, 'cache.path')
    let $smc-browser-path := config:param-value($model, 'smc-browser.path')
    (:  beware of mixing in the already result (doc()/Termsets/Termset vs. doc()/Termset 
                    and the results from full analysis (whole tree starting from / - they have first level empty node! :)
    let $termsets := <Termsets>{collection($cache-path)/Termset[Term/xs:string(@path)!='']}</Termsets>
    
    
    
(:    let $termsets-doc := doc(concat($cache-path, $termsets-file)):)
   let $termsets-doc := repo-utils:store-in-cache(concat($smc:structure-file,".xml"), $termsets, $config)
   
let $graph := transform:transform($termsets, $smc:xsl-terms2graph,<parameters><param name="base-uri" value="/db/apps/cr-xq/modules/smc/data/" /></parameters> ),
    $graph-file := concat($smc:structure-file, "-graph"),
    $graph-doc := repo-utils:store-in-cache (concat($graph-file,".xml"), $graph,$config),    
    $graph-json := transform:transform($graph, $smc:xsl-graph2json,<parameters><param name="base-uri" value="/db/apps/cr-xq/modules/smc/data/" /></parameters> ),
    $graph-json-doc := repo-utils:store-in-cache(concat($graph-file,".json"), $graph-json, $config)  
    let $graph-copy := if ($smc-browser-path ne '') then  repo-utils:store($smc-browser-path,concat($graph-file,".json"), $graph-json, true(),$config) else ()
return <gen-graph>{string-join((document-uri($termsets-doc), document-uri($graph-doc), concat($graph-file,".json"), $smc-browser-path),', ')}</gen-graph> 

(:
 let $graph-termsets := for $t in $graph-doc//Termset/Term
                            return <term>{$t/@*}</term>
    return ($cache-path, count($termsets//Termset),count($termsets-doc//Termset), count(distinct-values($termsets-doc//Termset/Term/@name)), count($graph-doc//node[@type='Profile']),
   <profiles>{distinct-values($termsets-doc//Termset/Term/@name)}</profiles>,
   <graph-termsets>{$graph-termsets}</graph-termsets>,   
   <nodes>{distinct-values($graph-doc//node[@type='Profile']/xs:string(@name))}</nodes>)
:)
  
};