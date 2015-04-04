xquery version "3.0";

declare option exist:serialize "method=json media-type=application/json";

import module namespace dsk-view="http://semtonotes.github.io/SemToNotes/dsk-view"
  at '/db/apps/sem2notes/modules/dsk-view.xqm';

let $uri := request:get-parameter("uri", "/db/sade-projects/foobar/data/xml/tile/24hcn.0.xml")
let $tei := doc($uri)/*

return
dsk-view:annotations($tei)
