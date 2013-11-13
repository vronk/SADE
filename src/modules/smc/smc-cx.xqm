xquery version "3.0";

(: 
 : Defines the RestXQ endpoints of the service.
 :)
module namespace cx = "http://clarin.eu/smc/cx";
import module namespace smc="http://clarin.eu/smc" at "smc.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "/db/apps/cr-xq/modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "../../core/repo-utils.xqm";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $cx:map-formats := ('default','','schema','schemas','cmdid','id','datcat');


(:declare option exist:serialize "method=xml media-type=application/xml enforce-xhtml=yes";:)

(:~
 : List available contexts or terms
 : @param $context if $context = ('*', 'top') - lists available termsets. 
 :                  if $context = $termset-identifier then  lists available terms of given termset.
 : @param $format format of the response, allowed values: currently only xml, planned: json, skos/rdf?
 :)
declare 
    %rest:GET
    %rest:path("/smc/cx/list/{$context}")        
    %rest:query-param("format", "{$format}", "xml")
(:    %rest:produces("application/xml", "text/xml"):)
function cx:list($context, $format) {
 
 let $data := smc:list($context)
 
  let $result:= if (contains($format,'html')) then
(:                let $option := util:declare-option("exist:serialize", "method=html media-type=application/html"):)
        let $resp := <rest:response> <http:response status="200"> <http:header name="Content-Type" value="text/html; charset=utf-8"/> </http:response> </rest:response>
                return ($resp, repo-utils:serialise-as($data, $format, 'terms', $smc:config))
           else $data
            
  return $result

};

declare
    %rest:GET        
    %rest:path("/smc/cx/map/{$context}/{$term}/{$format}")
    (:%rest:path("/smc/cx/map/{$context}/{$term}")
    %rest:query-param("format", "{$format}", ""):)
    %rest:query-param("relset", "{$relset}", "")
(:    %rest:produces("application/xml", "text/xml"):)
function cx:map2($context, $term, $format, $relset) {
    cx:map($context, $term, $format, $relset)
   };

(:~
 : Perform the mapping:
 : @param $context  values from list/* 
 : @param $term smcIndex?
 : @param $format format of the response, allowed values: currently only xml, planned: json, skos/rdf?
 :)
declare
    %rest:GET        
(:    %rest:path("/smc/cx/map/{$context}/{$term}/{$format}"):)
    %rest:path("/smc/cx/map/{$context}/{$term}")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("relset", "{$relset}", "")
(:    %rest:produces("application/xml", "text/xml"):)
function cx:map($context, $term, $format, $relset) {

let $time1 :=  util:system-time()
(:[contains(.,$term)]:)
(:let  $answer := $smc:dcr-cmd-map//Term[xs:string(@set) = $context][ngram:ends-with(.,$term)]:)
(:/parent::Concept/Term:)

let $answer := if (not(exists($smc:termsets//Termset[key=$context or @type=$context]))) then 
         (:           diag:diagnostics('unsupported-param-value',("context=", $context)):)            
                  <diagnostics>
                     <diagnostic xmlns="http://www.loc.gov/zing/srw/diagnostic/" key="unsupported-param-value">
                     <uri>info:srw/diagnostic/1/6</uri>
                     <details>context= {$context}</details>
                     <message>Unsupported parameter value</message>
                     </diagnostic>
                  </diagnostics>
           else
           if (not($format= $cx:map-formats or empty($format))) then
                     <diagnostics>
                        <diagnostic xmlns="http://www.loc.gov/zing/srw/diagnostic/" key="unsupported-param-value">
                        <uri>info:srw/diagnostic/1/6</uri>
                        <details>format= {empty($format)}</details>
                        <message>Unsupported parameter value</message>
                        </diagnostic>
                     </diagnostics>
           else 
           
           let $termx := translate($term, '_', ' ')
           let  $match := ($smc:dcr-cmd-map//Term[xs:string(@set) = $context][.=$termx] | $smc:dcr-cmd-map//Term[xs:string(@set) = $context][ngram:ends-with(.,concat('.',$termx))])/parent::Concept

           return switch ($format) 
                case 'datcat'
                    return for $datcat in $match
                        let $mnemoTerm := $datcat/Term[ft:query(@type,'mnemonic')]
                        return <Term concept-id="{$datcat/data(@id)}" set="{$mnemoTerm/data(@set)}" type="datcat" >{$mnemoTerm/translate(text(),' ', '_')}</Term>

                case 'schema'
                case 'schemas'
(:                    return for $schema in distinct-values($match/Term/data(@schema)):)
                    return for $schema in $smc:cmd-terms//Termset[@id=distinct-values($match/Term/data(@schema))]
                           let $profile-name := $schema/data(@name)
                        return <Termset schema="{$schema/@id}" name="{$profile-name}" />                
                case 'cmdid'
                case 'id'
(:                    return for $id in distinct-values($match/Term/data(@id))
                    return <Term id="{$id}" />:)
                    return $smc:cmd-terms//Term[@id=$match/Term/data(@id)]                          
                                                            
                default                     
(:                     if (empty($format) or $format='' or $format='default') then:)
                    return $match
                    
 let $dur := util:system-time() - $time1
return <Termset context="{$context}" term="{$term}" format="{$format}" count="{count($answer/(descendant-or-self::Term|descendant-or-self::Termset))}" duration="{$dur}">{$answer}</Termset>
(:transform:transform ($smc:dcr-cmd-map, $smc:xsl-smc-op,
                        <parameters>
                            <param name="operation" value="map"/>
                            <param name="context" value="{$context}"/>
                            <param name="term" value="{$term}"/>        
                        </parameters>)
:)
};

(:
declare
    %rest:GET
    %rest:path("/smc/cx/map/{$context}/{$term}")
    %rest:query-param("relset", "{$relset}", "")
(\:    %rest:produces("application/xml", "text/xml"):\)
function cx:map($context, $term, $relset) {
 cx:map($context, $term, '', $relset)
};

:)

declare 
    %rest:GET
    %rest:path("/smc/cx/diff")        
    %rest:query-param("context", "{$context}", "smc")
    %rest:query-param("id1", "{$id1}", "")
    %rest:query-param("id2", "{$id2}", "")
    %rest:query-param("format", "{$format}", "xml")
(:    %rest:produces("application/xml", "text/xml"):)
function cx:diff($id1, $id2, $context, $format) {
 
 let $data := smc:diff($id1, $id2, config:config('mdrepo'))
 
  let $result:= if (contains($format,'html')) then
(:                let $option := util:declare-option("exist:serialize", "method=html media-type=application/html"):)
        let $resp := <rest:response> <http:response status="200"> <http:header name="Content-Type" value="text/html; charset=utf-8"/> </http:response> </rest:response>
                return ($resp, repo-utils:serialise-as($data, $format, 'terms', $smc:config))
           else $data
            
  return $result
(: let $terms1 := smc:resolve($id1, config:config($context))
return ($terms1, $data):)

};



(:~
 : Test: list all addresses in JSON format. For this function to be chosen,
 : the client should send an Accept header containing application/json.
 :)
(:declare:)
(:    %rest:GET:)
(:    %rest:path("/address"):)
(:    %rest:produces("application/json"):)
(:    %output:media-type("application/json"):)
(:    %output:method("json"):)
(:function demo:addresses-json() {:)
(:    demo:addresses():)
(:};:)
