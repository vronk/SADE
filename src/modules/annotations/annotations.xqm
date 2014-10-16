xquery version "3.0";

module namespace annotations = "http://aac.ac.at/content_repository/annotations";
import module namespace project = "http://aac.ac.at/content_repository/project" at "../../core/project.xqm";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace cr="http://aac.ac.at/content_repository";

(:~ This module allows annotating data in the repository on resource, resourcefragment and element level. 
 : 
~:)
 


(:~ Proxy setter function that routes to the actual setters by the function arguments
~:)
declare function annotations:set($projectPID as xs:string, $annotations:id as xs:string?, $className as xs:string?, $resourcePID as xs:string?, $resourcefragmentPID as xs:string?, $crID as xs:string?, $data as map()){
    switch(true())
        case (exists($annotations:id) and $annotations:id != "") return annotations:setByID($projectPID, $annotations:id, $data)
        case ($className = "resourcefragment" and ($resourcefragmentPID = "" or not($resourcefragmentPID))) return util:log-app("ERROR", $config:app-name, "missing parameter $resourcefragmentPID in setter function")
        (: if the annotation is _not_ specified via its ID (which is not the case since we tested for $annotations:id above), the parameter $resourcePID is mandadory :)
        case ($className = ("resourcefragment", "resource") and ($resourcePID = "" or not($resourcePID))) return util:log-app("ERROR", $config:app-name, "missing parameter $resourcePID in setter function")
        case ($className = "resourcefragment") return annotations:setByResourcefragmentPID($projectPID, $resourcePID, $resourcefragmentPID, $data)
        case ($className = "resource") return annotations:setByResourcePID($projectPID, $resourcePID, $data)
        case (exists($crID) and $crID != "") return annotations:setByCrID($projectPID, $resourcePID, $crID, $className, $data)
        default return util:log-app("ERROR", $config:app-name, "missing required parameter $crID in setter function")
};




(:~ setter for annotations by project-wide id ~:)
declare function annotations:setByID($projectPID as xs:string, $annotations:id as xs:string, $data as map()) as element(annotations:annotation)? {
    let $annotations:data := annotations:getByID($projectPID, $annotations:id)
    return 
        if (count($annotations:data) ge 1)
        then
            let $resourcePID :=  xs:string($annotations:data/@resourcePID),
                $resourcefragmentPID := xs:string($annotations:data/@resourcefragmentPID),
                $crID := xs:string($annotations:data/@crID),
                $className := xs:string($annotations:data/@class)
            return (
                annotations:doReplace($annotations:data[1],annotations:data2XML($projectPID, $resourcePID, $resourcefragmentPID, $crID, $className, $data)),
                if (count($annotations:data) gt 1)
                then util:log-app("WARN", $config:app-name, "more than one annotations found with ID "||$annotations:id||" in project "||$projectPID||" - updating only first")
                else ()
            )
        else util:log-app("ERROR", $config:app-name, "annotation with ID "||$annotations:id||" not found in project "||$projectPID)
};

declare function annotations:setByCrID($projectPID as xs:string, $resourcePID as xs:string, $crID as xs:string, $className as xs:string, $data as map()) {
    let $annotations:data := annotations:getByCrID($projectPID, $resourcePID, $crID, $className)
    return ()
};

declare function annotations:setByResourcePID($projectPID as xs:string, $resourcePID as xs:string, $data as map()) {
    ()
};

declare function annotations:setByResourcefragmentPID($projectPID as xs:string, $resourcePID as xs:string, $resourcefragmentPID as xs:string, $data as map()) {
    let $annotations:data := annotations:getByResourcefragmentPID($projectPID, $resourcePID, $resourcefragmentPID)
    return 
        if (count($annotations:data) ge 1)
        then (annotations:doReplace($annotations:data[1],annotations:data2XML($projectPID, $resourcePID, $resourcefragmentPID, (), $annotations:data/@class, $data)),
             if (count($annotations:data) gt 1)
             then util:log-app("WARN", $config:app-name, "more than one annotations found for resourcefragment "||$resourcefragmentPID||" in project "||$projectPID||" - updating only first")
             else ())
        else util:log-app("ERROR", $config:app-name, "annotation for resource fragment  "||$resourcefragmentPID||" not found in project "||$projectPID) 
        
};


(: update and helper functions :)
declare %private function annotations:doReplace($annotations:old as element(annotations:annotation), $annotations:new as element(annotations:annotation)) as empty() {
    update replace $annotations:old with $annotations:new
};

declare %private function annotations:doInsert($annotations:document as element(annotations:annotations), $annotations:new as element(annotations:annotation)) as empty() {
    update insert $annotations:new into $annotations:document
};

declare %private function annotations:doRemove($annotations:annotation as element(annotations:annotation)) as empty() {
    update delete $annotations:annotation
};

(:~
 : constructs a new annotations:annotation element to be inserted into the document
~:)
declare function annotations:data2XML($projectPID as xs:string, $resourcePID as xs:string, $resourcefragmentPID as xs:string?, $crID as xs:string?, $className as xs:string, $data as map()) as element(annotations:annotation)? {
    (: get the annotation class definition :)
    (: iterate over map:keys :)
    <annotation xmlns="http://aac.ac.at/content_repository/annotations" xml:id="ann_{$projectPID}_{util:uuid()}" class="{$className}" projectPID="{$projectPID}" created="{current-dateTime()}">{
        if ($crID != "") then attribute {"crID"} {$crID} else (),
        if ($resourcePID != "") then attribute {"resourcePID"} {$resourcePID} else (),
        if ($resourcefragmentPID != "") then attribute {"resourcefragmentPID"} {$resourcefragmentPID} else (),
        let $expectedParameters :=  annotations:class($projectPID, $className)/annotations:category
        for $p in $expectedParameters return
            switch(true())
                case ($p/@cardinality and $p/@cardinality != "1" and $p/@cardinality castable as xs:integer) return 
                    for $c at $pos in number($p/@cardinality)
                    let $content := map:get($data,$p/@name)
                    return
                        if (exists($content))
                        then 
                            let $valid := switch(true())
                                            case ($p/@values and not($content = tokenize($p/@values,'\s*,\s*'))) return false()
                                            case ($p/@values and $content = tokenize($p/@values,'\s*,\s*')) return true()
                                            default return true()
                            return
                                if ($valid) 
                                then <item name="{$p}" category="{$p/@name}">{$content}</item>
                                else ()
                        else ()
                        
                case ($p/@cardinality = 'unbound') return 
                    for $k in map:keys($data) 
                    where matches($k,'^'||$p/@name||'\d+$') 
                    return
                        let $content := map:get($data,$k)
                        return 
                            if (exists($content))
                            then 
                                let $valid := switch(true())
                                                case ($p/@values and not($content = tokenize($p/@values,'\s*,\s*'))) return false()
                                                case ($p/@values and $content = tokenize($p/@values,'\s*,\s*')) return true()
                                                default return true()
                                return 
                                    if ($valid)
                                    then <item name="{$k}" category="{$p/@name}">{$content}</item>
                                    else () 
                            else ()

                case (not($p/@cardinality) or $p/@cardinality = "1") return
                    let $content := map:get($data,$p/@name)
                    return 
                        if (exists($content))
                        then 
                            let $valid := switch(true())
                                case ($p/@values and not($content = tokenize($p/@values,'\s*,\s*'))) return false()
                                case ($p/@values and $content = tokenize($p/@values,'\s*,\s*')) return true()
                                default return true()
                            return 
                                if ($valid)
                                then <item name="{$p/@name}" category="{$p/@name}">{$content}</item>
                                else () 
                        else ()
                default return $p
    }</annotation>
};

(:~ creates a newly constructed annotation for the resource $resourcePID if it does not exist already: 
 : "resource" annotaions: only one per resource,
 : "resourcefragment" annotations: only one per resourcefragment,
 : "crID" (generic) annotations: only one per annotation class and cr-element,
 :)
declare function annotations:new($annotations:data as element(annotations:annotation)) as empty() {
    let $projectPID := xs:string($annotations:data/@projectPID),
        $resourcePID := xs:string($annotations:data/@resourcePID),
        $className := xs:string($annotations:data/@class),
        $resourcefragmentPID := xs:string($annotations:data/@resourcefragmentPID),
        $crID := xs:string($annotations:data/@crID)
    let $annotations:document := 
        if ($projectPID != "" and $resourcePID != "")
        then
            let $d:= annotations:getDocument($projectPID, $resourcePID)
            return if (exists($d)) then $d else annotations:createDocument($projectPID, $resourcePID)
        else ()
    return            
    switch(true())
        case ($projectPID = "") return util:log-app("ERROR", $config:app-name, "missing or empty attribute @projectPID on new annotation")
        case ($resourcePID = "") return util:log-app("ERROR", $config:app-name, "missing or empty attribute @resourcePID on new annotation")
        case ($className = "") return util:log-app("ERROR", $config:app-name, "missing or empty attribute @class on new annotation")
        case ($className = "resource") return
            if (exists(annotations:getByResourcePID($projectPID,$resourcePID)))
            then util:log-app("WARN",$config:app-name,"tried to create new annotation, which exists already (existing data was not altered): className='"||$className||"', resource='"||$resourcePID||"', project='"||$projectPID||"'")
            else annotations:doInsert($annotations:document, $annotations:data)
        case ($className = "resourcefragment") return
            switch (true())
                case ($resourcefragmentPID = "") return util:log-app("ERROR", $config:app-name, "missing or empty attribute @resourcefragmentPID on new annotation")
                case exists(annotations:getByResourcefragmentPID($projectPID,$resourcePID,$resourcefragmentPID)) return 
                    util:log-app("WARN",$config:app-name,concat("tried to create new annotation, which exists already (existing data was not altered): ", string-join((for $c in ("$className", "$resourcePID", "$resourcefragmentPID", "$projectPID") return concat($c,"=",util:eval($c))),', ')))
                default return annotations:doInsert($annotations:document, $annotations:data)
        default return
            switch (true())
                case ($crID = "") return util:log-app("ERROR", $config:app-name, "missing or empty attribute @crID on new annotation")
                case exists(annotations:getByCrID($projectPID, $resourcePID, $crID, $className)) return
                    util:log-app("WARN",$config:app-name,concat("tried to create new annotation, which exists already (existing data was not altered): ", string-join((for $c in ("$className", "$resourcePID", "crID", "$projectPID") return concat($c,"=",util:eval($c))),', ')))
                default return annotations:doInsert($annotations:document, $annotations:data)
};

declare function annotations:path($projectPID as xs:string) as xs:string? {
    let $annotations:path := project:path($projectPID, "annotations")
    return 
        if ($annotations:path != "")
        then $annotations:path
        else util:log-app("ERROR", $config:app-name, "project:path($projectPID, 'annotations') is not supposed to be empty.")
};


declare function annotations:createDocument($projectPID as xs:string, $resourcePID as xs:string) {
    let $annotations:path := annotations:path($projectPID),
        $annotations:filename := $resourcePID||".xml"
    return
        if ($annotations:path != "")
        then 
            let $col := 
                if (xmldb:collection-available($annotations:path)) 
                then ()
                else xmldb:create-collection(project:path($projectPID,"home"),replace($annotations:path, "^"||project:path($projectPID,"home")||"/?",''))
            return xmldb:store($annotations:path,$annotations:filename,<annotations xmlns="http://aac.ac.at/content_repository/annotations" resourcePID="{$resourcePID}" projectPID="{$projectPID}"/>)
        else util:log-app("ERROR", $config:app-name, "cannot create annotations document for resource "||$resourcePID||" in proejct "||$projectPID)
};

declare function annotations:getDocument($projectPID as xs:string, $resourcePID as xs:string) {
    let $annotations:path := annotations:path($projectPID),
        $annotations:filename := $resourcePID||".xml"
    return 
        if ($annotations:path != "")
        then doc($annotations:path||"/"||$annotations:filename)
        else util:log-app("ERROR", $config:app-name, "cannot load annotations document for resource "||$resourcePID||" in project " ||$projectPID)
};

(:~ HTML form generators 
 :)


(:~ generates an empty html form for the annotation class $className in project $projectPID.
 : @param $projectPID the PID of the current project
 : @param $className the name of the annotation class
 : @return an empty html form element
~:)
declare function annotations:form($projectPID as xs:string, $className as xs:string) as element(html:form)? {
    transform:transform(annotations:class($projectPID,$className), doc('form.xsl'), ())
};

(:~
 : generates a populated html form for the annotation class $className in project $project
 : annotation data is fetched based on the attributes supplied: 
 :    - if $className is 'resource' then annotations:getByResourcePID($projectPID, $resourcePID)
 :    - if $className is 'resourcefragment' then annottatiions:getByResourcefragmentPID($projectPID, $resourcePID, $resourcefragmentPID)
 :    - otherwise annotations:getByCrID($projectPID, $resourcePID, $crID)
 : 
 : @param $projectPID the PID of the current project
 : @param $className  the name of the annotation class
 : @param $resourcePID the PID of the current resource
 : @param $resourcefragmentPID the PID of the current resourcefragment
 : @param $crID the ID of the selected element
 : @return an empty html form element
~:)
declare function annotations:form($projectPID as xs:string, $annotations:id as xs:string?, $className as xs:string, $resourcePID as xs:string?, $resourcefragmentPID as xs:string?, $crID as xs:string?, $request as map()?) as element(html:form)? {
    let $data := annotations:get($projectPID, $annotations:id, $className, $resourcePID,$resourcefragmentPID,$crID)
    return
        if ($projectPID != "" and $className != "")
        then
            let $class := annotations:class($projectPID,$className),
                $params := <parameters>
                                <param name="projectPID" value="{$projectPID}"/>
                                {if ($resourcePID != "") then <param name="resourcePID" value="{$resourcePID}"/> else (),
                                 if ($resourcefragmentPID != "") then <param name="resourcefragmentPID" value="{$resourcefragmentPID}"/> else (),
                                 if ($crID != "") then <param name="crID" value="{$crID}"/> else (),
                                 if ($data) 
                                 then 
                                    element {"param"} {
                                        attribute {"name"} {"data"}, 
                                        attribute {"value"} {
                                            string-join(
                                                (for $d in $data return base-uri($data)||":"||$data/@xml:id),
                                                ";"
                                            )}
                                    }
                                 else ()
                                 }
                           </parameters>
            return transform:transform($class, doc('form.xsl'), $params)
        else ()
};



(:~ Proxy getter function that routes to the actual setters by the function arguments
~:)
declare function annotations:get($projectPID as xs:string, $annotations:id as xs:string?, $className as xs:string?, $resourcePID as xs:string?, $resourcefragmentPID as xs:string?, $crID as xs:string?) {
    switch(true())
        case (exists($annotations:id) and $annotations:id != "") return annotations:getByID($projectPID, $annotations:id)
        case ($className = "resourcefragment" and ($resourcefragmentPID = "" or not($resourcefragmentPID))) return util:log-app("ERROR", $config:app-name, "missing parameter $resourcefragmentPID in getter function")
        (: if the annotation is _not_ specified via its ID (which is not the case since we tested for $annotations:id above), the parameter $resourcePID is mandadory :)
        case ($className = ("resourcefragment", "resource") and ($resourcePID = "" or not($resourcePID))) return util:log-app("ERROR", $config:app-name, "missing parameter $resourcePID in getter function")
        case ($className = "resourcefragment") return annotations:getByResourcefragmentPID($projectPID, $resourcePID, $resourcefragmentPID)
        case ($className = "resource") return annotations:getByResourcePID($projectPID, $resourcePID)
        case (exists($crID) and $crID != "") return annotations:getByCrID($projectPID, $resourcePID, $crID, $className)
        default return util:log-app("ERROR", $config:app-name, "missing required parameter $crID in getter function")
};



declare function annotations:remove($projectPID as xs:string, $annotations:id as xs:string?, $className as xs:string?, $resourcePID as xs:string?, $resourcefragmentPID as xs:string?, $crID as xs:string?) {
    let $annotations:data := annotations:get($projectPID, $annID, $className, $resourcePID, $resourcefragmentPID, $crID)
    return 
        if ($annotations:data)
        then annotations:doRemove($annotations:data)
        else (util:log-app("ERROR", $config:app-name, "no annotation data found, cannot remove - parameters passed: "),
             for $p in ("$projectPID", "$annotations:id", "$className", "$resourcePID", "$resourcefragmentPID", "$crID") return util:log-app("ERROR", $config:app-name, concat($p,": ",util:eval($p))))
};





(:~ Getters for annotation class definitions ~:)
declare function annotations:class($projectPID as xs:string, $className as xs:string) as element()? {
    annotations:classes($projectPID)[@name = $className]
};

declare function annotations:classes($projectPID as xs:string) as element(annotations:class)* {
    let $annotations:config := config:config($projectPID)//module[@key='annotations']
    return
    if (xs:boolean($annotations:config/param[@key = 'annotations.enabled']))
    then $annotations:config/param[@key = 'annotations.classes']/annotations:class
    else util:log-app("WARN",$config:app-name,"annotations are not enabled for this project. Set parameter 'annotations.enabled=true' in config for module 'annotations'.")
};



(:~ Getters for annotation instances :)
(:~
 : Returns the data for an annotation by its project-wide unique xml:id
 : @param $projectPID the ID of the current project
 : @param $annotation-id the ID of the annotation (IDs for annotations are unique within a project)
:)
declare function annotations:getByID($projectPID as xs:string, $annotations:id as xs:string) as element(annotations:annotation)*{
    let $annotations:path := project:path($projectPID, "annotations")
    return collection($annotations:path)//annotations:annotation[@xml:id = $annotations:id]
};


(:~ Returns the data of an annotation by the cr:id of an arbitrary element in the given resource
: @param $projectPID the ID of the current project
: @param $resource-ipd the ID of the resource that contains the element
: @param $crID the cr:id of the element 
~:)
declare function annotations:getByCrID($projectPID as xs:string, $resourcePID as xs:string, $crID as xs:string, $className as xs:string) as element(annotations:annotation)*{
    annotations:getDocument($projectPID,$resourcePID)//annotations:annotation[@crID = $crID][@class = $className]
};


declare function annotations:getByResourcePID($projectPID as xs:string, $resourcePID as xs:string) as element(annotations:annotation)*{
    annotations:getDocument($projectPID,$resourcePID)//annotations:annotation[@class = "resource"]
};


declare function annotations:getByResourcefragmentPID($projectPID as xs:string, $resourcePID as xs:string, $resourcefragmentPID as xs:string) as element(annotations:annotation)*{
    annotations:getDocument($projectPID,$resourcePID)//annotations:annotation[@class = "resourcefragment"][@resourcefragmentPID = $resourcefragmentPID]
};