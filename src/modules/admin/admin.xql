xquery version "1.0";


import module namespace config="http://exist-db.org/xquery/apps/config" at "/db/apps/cr-xq/core/config.xqm";
import module namespace cmdcheck = "http://clarin.eu/cmd/check" at "../cmd/cmd-check.xqm";
import module namespace smc  = "http://clarin.eu/smc" at "../smc/smc.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";

declare option exist:serialize "method=html5 media-type=text/html";

let $format := request:get-parameter("x-format",'htmlpage'),
    $op := request:get-parameter("operation", ""),
    $x-context := request:get-parameter("x-context", "mdrepo"),
    $config := config:config($x-context)


let $result := if ($op eq 'init') then
                    (cmdcheck:collection-to-mapping($config, ""),
                     smc:gen-mappings($config, $x-context, true(), 'raw'),
                    smc:gen-graph($config, $x-context))
                    else ()
                (:else 
                    diag:diagnostics("unsupported-operation", $op)
:)


return <div><h3>Admin</h3>
               <a href="?operation=init" >initialize</a>
            <div id="result">{$result}</div>
        </div>