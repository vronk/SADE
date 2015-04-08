xquery version "3.0";

module namespace dsk-view="http://semtonotes.github.io/SemToNotes/dsk-view";

import module namespace dsk-t="http://semtonotes.github.io/SemToNotes/dsk-transcription"
    at "SemToNotes-transcription.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace ore="http://www.openarchives.org/ore/terms/";
declare namespace tg="http://textgrid.info/namespaces/metadata/core/2010";

declare function dsk-view:coordinatesPolygon($shape as element(svg:polygon), $tgl) as xs:string {

  let $image := $tgl//svg:image
  let $width := xs:integer($image/@width/string())
  let $height := xs:integer($image/@height/string())
  let $percentage := if($height > $width ) then
        1500 div $height
    else
        1500 div $width

  let $string := $shape/@points/string()
  let $pointss := tokenize($string, ' ')
  let $points :=
    for $point in $pointss
    let $coords := tokenize($point, ',')
    let $xs := substring-before($coords[1], '%')
    let $ys := substring-before($coords[2], '%')
    let $xp := if ($xs != '') then xs:double($xs) else 0
    let $yp := if ($ys != '') then xs:double($ys) else 0
    let $x := ($width * $xp) div 100 * $percentage
    let $y := ($height * $yp) div 100 * $percentage
    return
    concat($x, ',', $y)
  return
  string-join($points, ' ')
};

declare function dsk-view:coordinatesRect($shape as element(svg:rect), $tgl) as xs:string {

  let $image := $tgl//svg:image
  let $width := xs:integer($image/@width/string())
  let $height := xs:integer($image/@height/string())
  let $percentage := if($height > $width ) then
        1500 div $height
    else
        1500 div $width  

  let $xs := substring-before($shape/@x/string(), '%')
  let $ys := substring-before($shape/@y/string(), '%')
  let $ws := substring-before($shape/@width/string(), '%')
  let $hs := substring-before($shape/@height/string(), '%')

  let $xp := if ($xs != '') then xs:double($xs) else 0
  let $yp := if ($ys != '') then xs:double($ys) else 0
  let $wp := if ($ws != '') then xs:double($ws) else 0
  let $hp := if ($hs != '') then xs:double($hs) else 0

  let $x := ($width * $xp) div 100 * $percentage
  let $y := ($height * $yp) div 100 * $percentage
  let $w := ($width * $wp) div 100 * $percentage
  let $h := ($height * $hp) div 100 * $percentage

  let $p1 := concat($x, ',', $y)
  let $p2 := concat($x + $w, ',', $y)
  let $p3 := concat($x + $w, ',', $y + $h)
  let $p4 := concat($x, ',', $y + $h)

  return

  string-join(($p1, $p2, $p3, $p4), ' ')
};

declare function dsk-view:coordinates($shape as element(), $tgl) as xs:string {
  if (local-name($shape) = 'rect') then dsk-view:coordinatesRect($shape, $tgl)
  else dsk-view:coordinatesPolygon($shape, $tgl)
};

declare function dsk-view:annotations($tgl as element(tei:TEI)) {
  <annotations>
    {
    let $shapes := $tgl//(svg:rect|svg:polygon)
    let $links := $tgl//tei:link
    for $link at $pos in $links
    let $targets := tokenize($link/@targets/string(), ' ')
    let $anchor := substring-before(substring-after($targets[2], '#'), '_start')
    let $shape-id := substring-after($targets[1], '#')
    let $shape := $shapes[@id=$shape-id]
    return
      if ($anchor != '' and not(empty($shape))) then
        element { $anchor } {
          dsk-view:coordinates($shape, $tgl)
        }
      else ()
    }
  </annotations>
};

declare function dsk-view:navigation($tilepath as xs:string, $what as xs:string){
(:input:)
let $tile:= doc($tilepath)
(: collections :)
let $rdfcoll := collection(substring-before($tilepath, 'tile/') || 'agg')
let $tilecoll := collection(substring-before($tilepath, 'tile/') || 'tile')

(: get the first TEI doc from TILE object :)
let $teiuri:= $tile//tei:link[1]/substring-before(substring-after(@targets, 'textgrid:'), '#')
(: look up the previous base uri :)
let $newtei:= 
    if ($what = 'prev')
    then $rdfcoll//ore:aggregates[ends-with(@rdf:resource, $teiuri)]/preceding-sibling::ore:aggregates[1]/string(@rdf:resource)
    else $rdfcoll//ore:aggregates[ends-with(@rdf:resource, $teiuri)]/following-sibling::ore:aggregates[1]/string(@rdf:resource)
(: check for a TILE object with this textgrid uri :)
let $tileuri := $tilecoll//tei:link[contains(@targets, $newtei)][1]/base-uri()

return
substring-after($tileuri, 'data')
};

declare function dsk-view:render($tei as element(tei:TEI), $imguri as xs:string, $imgwidth as xs:float, $tilepath as xs:string) {
let $prev := dsk-view:navigation($tilepath, 'prev')
let $next := dsk-view:navigation($tilepath, 'next')

let $params :=
<parameters>
  <param name="image-url" value="{ util:document-name($tei) }"/>
</parameters>

let $toolbar := 
<div class="toolbar">
   <i class="fa fa-search-plus"></i> 	&#160;
   <i class="fa fa-search-minus"></i> 	&#160;
   <i class="fa fa-times"></i>
</div>

(:
let $pages :=
if ($tei/@n) then ($tei, $dsk-data:teis[@corresp=$tei/@n])
else if ($tei/@corresp) then
  let $name := $tei/@corresp/string()
  return
  ($dsk-data:teis[@n = $name], $dsk-data:teis[@corresp = $name])
else ()

let $pages-div :=
<div id="view-pages" xmlns="http://www.w3.org/1999/xhtml">
{
  for $page at $pos in $pages
  let $color := if ($page = $tei) then 'color:white' else ''
  return
  <a style="{ $color }" href="./{ dsk-textgrid:html-name($page) }">Seite {$pos} |</a>
}
</div>
:)

return

let $resizable := (
<div class="resize-n" xmlns="http://www.w3.org/1999/xhtml"></div>,
<div class="resize-e" xmlns="http://www.w3.org/1999/xhtml"></div>,
<div class="resize-s" xmlns="http://www.w3.org/1999/xhtml"></div>,
<div class="resize-w" xmlns="http://www.w3.org/1999/xhtml"></div>,
<div class="resizable" xmlns="http://www.w3.org/1999/xhtml"></div>
)

return

<html xmlns="http://www.w3.org/1999/xhtml">
<!-- { conf:html-head() } -->
<body>
<!-- following style refers to the generic SADE Template, redistributable in context of TextGrid projects -->
    
    <div class="section-header">
        <div class="container">
        <!-- Navigate to previous TEI/XML doc according to a rdf -->
         {if ($next = '') then '' else
            <div class="pull-left" style="position: absolute;left: 5;"><a href="?id={$prev}"><i class="fa fa-chevron-left" style="color: #00B4FF"></i></a></div>
         }
          <div class="row">
            <div class="col-sm-2">
              <!-- Remove the .animated class if you don't want things to move -->
              <h1 class="animated slideInLeft"><label><input type="checkbox" class="window-image" name="iwindow-image" checked="checked"/><span>Bild</span></label></h1>
            </div>
            <div class="col-sm-2">
              <!-- Remove the .animated class if you don't want things to move -->
              <h1 class="animated slideInLeft"><label><input type="checkbox" class="window-comment" name="iwindow-comment" checked="checked"/><span>Metadaten</span></label></h1>
            </div>
            <div class="col-sm-2">
              <!-- Remove the .animated class if you don't want things to move -->
              <h1 class="animated slideInLeft"><label><input type="checkbox" class="window-transcription1" name="iwindow-transcription1" checked="checked"/><span>Transkription</span></label></h1>
            </div>
            <div class="col-sm-2">
              <!-- Remove the .animated class if you don't want things to move -->
              <h1 class="animated slideInRight"><label><input type="checkbox" class="window-transcription2" name="iwindow-transcription2"/><span>Lesefassung</span></label></h1>
            </div>
            <div class="col-sm-2">
              <!-- Remove the .animated class if you don't want things to move -->
              <h1 class="animated slideInRight"><label><input type="checkbox" name="text-image-linking" checked="checked"/><span>Txt-Img-Links</span></label></h1>
            </div>
            {if ($tei//tei:title[1] = 'Bellifortis')
                then '' 
                else
                    
                <div class="col-sm-2">
                  <!-- Remove the .animated class if you don't want things to move -->
                  <h1 class="animated slideInRight"><label><input type="checkbox" name="hand-notes"/><span>Hände</span></label></h1>
                </div>
            }
          </div>
         <!-- Navigate to following TEI/XML doc according to a rdf -->
        {if ($next = '') then '' else
            <div class="pull-right" style="position: absolute;right: 5;"><a href="?id={$next}"><i class="fa fa-chevron-right" style="color: #00B4FF"></i></a></div>
         }
        </div>
    </div>
    
    
  <!-- div id="view-header">
    <div id="title">
      <h1><a href="./liste.html">&lt;</a> Digitale Schriftkunde</h1>
      <div id="options" class="noscript-invisible">
        <span>Bild </span>
        <input type="checkbox" class="window-image" name="iwindow-image" checked="checked"/>
        <span> | </span>
        <span>Kommentar </span>
        <input type="checkbox" class="window-comment" name="iwindow-comment" checked="checked"/>
        <span> | </span>
        <span>Entzifferung </span>
        <input type="checkbox" class="window-transcription1" name="iwindow-transcription1" checked="checked"/>
        <span> | </span>
        <span>Transkription </span>
        <input type="checkbox" class="window-transcription2" name="iwindow-transcription2"/>
        <span> | </span>
        <span>Text-Bild-Verknüpfung </span>
        <input type="checkbox" name="text-image-linking" checked="checked"/>
        <span> | </span>
        <span>Schreiberhände</span>
        <input type="checkbox" name="hand-notes"/>
      </div>
    </div>
  </div-->
  <div id="view-main">
    <!--div id="window-image" data-json="./json/{ dsk-textgrid:json-name($tei) }"-->
    <div id="window-image" data-json="/exist/rest/apps/SADE/modules/multiviewer/SemToNotes-json.xql?uri={$tilepath}">
      { () (:$pages-div:) }
      <div id="window-image-inner">
        <div class="h1">
          <span>{ $tei//tei:institution/text() || ', ' || $tei//tei:collection/text() || ' ' ||
      $tei//tei:idno/text() }</span>
          <div class="toolbar">
            <i class="fa fa-search-plus"></i> 	&#160;
            <i class="fa fa-search-minus"></i> 	&#160;
            <i class="fa fa-undo"></i> 	&#160;
            <i class="fa fa-repeat"></i> 	&#160;
            <i class="fa fa-search"></i> 	&#160;
            <i class="fa fa-times"></i>
          </div>
        </div>
        <div class="content">
          <img id="img" src="/exist/apps/textgrid-connect/digilib/{substring-after(substring-before($tilepath, '/data'), 'sade-projects/')}/{$imguri}?dh=1500&amp;dw=1500"/>
        </div>
      </div>
      { $resizable }
    </div>
    <div id="view-text">
      <div id="view-text-inner">
        <div id="window-comment">
          <div class="h1">
            <span>Metadaten</span>
            { $toolbar }
          </div>
          <div class="content">
            <div class="p">{ dsk-t:metadata($tei, substring-before($tilepath, '/data')) }</div>
          </div>
          { $resizable }
        </div>
        <div id="window-transcription1">
          <div class="h1">
            <span>Transkription</span>
            { $toolbar }
          </div>
          <div class="content">
            <div class="p">{ dsk-t:transcription($tei, 'orig', substring-before($tilepath, '/data')) }</div>
          </div>
          { $resizable }
        </div>
        
        <div id="window-transcription2">
          <div class="h1">
            <span>Lesefassung</span>
            { $toolbar }
          </div>
          <div class="content">
            <div class="p">{ dsk-t:transcription($tei, 'reg', substring-before($tilepath, '/data')) }</div>
          </div>
          { $resizable }
        </div>
      </div>
      </div>
      
  </div>
  <script type="text/javascript"><!--
    dsk.installView();
  --></script>
</body>
</html>
};
