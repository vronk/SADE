xquery version "3.0";

declare option exist:serialize "method=json media-type=application/json";

import module namespace dsk-view="http://semtonotes.github.io/SemToNotes/dsk-view"
  at './SemToNotes.xqm';

let $uri := request:get-parameter("uri", "/db/sade-projects/foobar/data/xml/tile/24hcn.0.xml")
let $tei := doc($uri)/*

return
dsk-view:annotations($tei)
