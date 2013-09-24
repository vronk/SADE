xquery version "3.0";
(:~
 : This is a generic restxq caller, which will (by default) be called by controller.xql
 : to process restxq-based modules (currently only /smc/cx?) 
 :
 : It expects the $exist-path and $module-uri as parameters
 : $module-uri is used to dynamically resolve functions (via inspec:module-functions()
 :)

import module namespace restxq="http://exist-db.org/xquery/restxq" at "restxq.xql";

let $exist-path := request:get-parameter("exist-path", "")

(:~ either namespace (for registered functions)  or location :)
let $module-uri := request:get-parameter("module-uri", "")
    
(:DEPRECATED: let $functions := util:list-functions("http://clarin.eu/smc/cx"):)
let $functions := inspect:module-functions($module-uri)
    return
        (: All URL paths are processed by the restxq module :)
        restxq:process($exist-path, $functions)
