xquery version "3.0";

(: 
 : Defines the RestXQ endpoints of the service.
 :)
module namespace cx = "http://clarin.eu/smc/cx";
import module namespace smc="http://clarin.eu/smc" at "smc.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "/db/apps/cr-xq/modules/diagnostics/diagnostics.xqm";

(:import module namespace config="http://exist-db.org/xquery/apps/config" at "../../modules/config.xqm";:)

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
      (: separate handling for isocat, because of lang :)

(:<answer term="{$context}" relset="{$format}" >
{ diag:diagnostics('unsupported-param-value',("context=", $context)) }
</answer>
:)
   if ($context = ('*','top')) then
        $smc:termsets
   else if (starts-with($context, 'isocat')) then        
        let $lang := if (starts-with($context, 'isocat-')) then substring-after($context, 'isocat-') else ''
        let $terms := $smc:dcr-cmd-map//Term[@set='isocat' and (@xml:lang=$lang or ($lang='' and @type='mnemonic'))]
       return <Termset set="{$context}" xml:lang="{$lang}" format="{$format}" count="{count($terms)}">
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
        return <Termset set="{$context}" format="{$format}" count="{count($terms)}">             
            { for $term in $terms
                  return  <Term concept-id="{$term/ancestor::Concept/data(@id)}" >{($term/@*,$term/text())}</Term>
            }
        </Termset>

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
(:~
 : Search addresses using a given field and a (lucene) query string.
 :)
declare 
    %rest:GET
    %rest:path("/search/{$query}")
    (:%rest:form-param("query", "{$query}", "")
    %rest:form-param("field", "{$field}", "name"):)
function cx:search($query as xs:string*) {
    <TODO><q>{$query}</q></TODO>
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
