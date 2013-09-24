xquery version "3.0";

(: 
 : Defines the RestXQ endpoints of the service.
 :)
module namespace cx = "http://clarin.eu/smc/cx";
import module namespace smc="http://clarin.eu/smc" at "smc.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "../diagnostics/diagnostics.xqm";

(:import module namespace config="http://exist-db.org/xquery/apps/config" at "../../modules/config.xqm";:)

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

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
      
   if ($context = ('*','top')) then
        $smc:termsets
   else if (not($smc:termsets//Termset[key=$context])) then 
           diag:diagnostics('unsupported-param-value',("context=", $context))
    else
(:   if (starts-with($context, 'isocat')) then:)
        let $set := if(starts-with($context, 'isocat')) then '' else $context
        let $lang := if(starts-with($context, 'isocat')) then substring-after($context, 'isocat-') else 'en'
        
       return <Termset set="{$context}" xml:lang="{$lang}" format="{$format}">
            { for $term in $smc:dcr-cmd-map//Term[(@set='isocat' and @xml:lang=$lang) or @set=$set]
                  return  <Term concept-id="{$term/ancestor::Concept/data(@id)}" >{($term/@*,$term/text())}</Term>
             }            
          </Termset>
    (:else
        <Termset set="{$context}">
            { $smc:dcr-cmd-map//Term[@set=$context]
                (\:<xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="concept-id" select="ancestor::Concept/@id"/>
                    <xsl:value-of select="."/>
                </xsl:copy>:\)
            }
        </Termset>
:)
};

(:~
 : Perform the mapping:
 : @param $context if $context = ('*', 'top') - lists available termsets. 
 :                  if $context = $termset-identifier then  lists available terms of given termset.
 : @param $term smcIndex?
 : @param $format format of the response, allowed values: currently only xml, planned: json, skos/rdf?
 :)
declare
    %rest:GET
    %rest:path("/smc/cx/map/{$context}/{$term}")
(:    %rest:produces("application/xml", "text/xml"):)
function cx:map($context, $term) {

transform:transform ($smc:dcr-cmd-map, $smc:xsl-smc-op,
                        <parameters>
                            <param name="operation" value="map"/>
                            <param name="context" value="{$context}"/>
                            <param name="term" value="{$term}"/>        
                        </parameters>)

};



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
