xquery version "3.0";
module namespace nav = "http://sade/tmpl-nav" ;
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";

declare variable $nav:module-key := "tmpl-nav";

declare
    %templates:wrap
function nav:navitems($node as node(), $model as map(*)) as map(*) {

    let $navitems :=  if(config:module-param-value($model, $nav:module-key, 'location') != "") then
            doc(config:param-value($model, 'project-dir') || config:module-param-value($model, $nav:module-key, 'location'))//navigation/*
        else
            $model("config")//module[@key=$nav:module-key]//navigation/*
        
    return map { "navitems" := $navitems }
    
};

declare function nav:head($node as node(), $model as map(*)) {
    
    switch(local-name($model("item")))
        case "submenu" return
            element { node-name($node) } {
                    $node/@*, string($model("item")/@label), for $child in $node/node() return $child
            }
        case "item" return
            element { node-name($node) } {
                    attribute href {$model("item")/@link}, string($model("item")/@label)
            }
        default return
            <b>not defined: {node-name($model("item"))}</b>
};

declare
    %templates:wrap
function nav:subitems($node as node(), $model as map(*)) as map(*) {
    map{ "subitems" := $model("item")/*} 
};

declare
function nav:subitem($node as node(), $model as map(*)) {
    if($model("subitem")/@class) then
        <span class="{$model("subitem")/@class}">&#160;</span>
    else if ($model("subitem")/name() != 'divider') then
        <a href="{string($model("subitem")/@link)}">{string($model("subitem")/@label)}</a>
        else <span>&#160;</span>
};
(: no call for subitemchoice...
declare
function nav:subitemchoice($node as node(), $model as map(*)) {

    let $item := $model("subitem")
    let $type := local-name($item)
    let $choosen := $node/*[@data-nav-choice=$type]
    
    return 
    switch($type)
        case "submenu" return
            <span>todo</span>
        case "item" return
            element { node-name($choosen) } {
                $choosen/@* , <a href="{string($item/@link)}">{string($item/@label)}</a>
            }
        case "divider" return
            element { node-name($choosen) } {
                $choosen/@* 
            }
        default return
            <b>not defined: {node-name($model("subitem"))}</b>

};
:)
declare function nav:edit($node as node(), $model as map(*)) {
let $new := request:get-parameter("new", "0")
return
    if (string($new) eq '0')
    then
        <div>
            <form class="form-horizontal" action="edit.html" method="GET">
                <textarea class="form-control" rows="10" name="new" />
                <button type="submit" class="btn btn-primary">Save</button>
            </form>
            <pre>{serialize(doc('/sade-projects/' || config:param-value($model, "project-id") || '/navigation.xml'))}</pre>
        </div>
    else 
        let $item := xmldb:login('/sade-projects/' || config:param-value($model, "project-id"), config:param-value($model, "sade.user"), config:param-value($model, "sade.password")),
            $egal := xmldb:store('/sade-projects/' || config:param-value($model, "project-id"), 'navigation.xml', $new, "text/xml")
        return
        <div><pre>{serialize(doc('/sade-projects/' || config:param-value($model, "project-id") || '/navigation.xml'))}</pre></div>
};

declare function nav:textgrid($node as node(), $model as map(*)) {
doc('/sade-projects/' || config:param-value($model, "project-id") || '/navigation-'|| config:param-value($model, "template") ||'.xml')
};
