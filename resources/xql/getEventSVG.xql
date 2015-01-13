xquery version "3.0";

(:
    getEventSVG.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'eventID' : xml:id of an MEI element, for which the corresponding SVG paths are sought
    
    This xQuery seeks out all SVG shapes for a specified MEI element, and returns information about 
    this element (xml:id and type, the page on which it manifests) and the according SVG shapes as JSON 
    object.
:)

(: todo: how to deal with MEI elements that may appear on more than one page, i.e. slurs??? :)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:START OF PROCESSING:)

let $source.id := request:get-parameter('sourceID','')
let $elem.id := request:get-parameter('eventID','')

(:
    get the MEI document, and in there the MEI element which is specified 
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:mei[@xml:id = $source.id]
let $elem := $doc/id($elem.id)

(:
    get an array of all referenced shapes for this element, be they mei:zone or svg:path. If the element itself
    has no references to shapes, take the references from its parent
:)
let $facs := if($elem/@facs) then(tokenize($elem/@facs,' ')) else(tokenize($elem/parent::mei:*/@facs,' '))

(:
    if the element is part of a chord, get all the shapes for the chord as well
:)
let $chordFacs := if($elem/parent::mei:chord)
                  then(tokenize($elem/parent::mei:chord/@facs,' '))
                  else()
                  
(:
    if the element is part of a beam, get all the shapes of the beam as well
:)                  
let $beamFacs := if($elem/ancestor::mei:beam and local-name($elem) = ('chord','note'))
                 then(tokenize($elem/ancestor::mei:beam/@facs,' '))
                 else()

(:
    if the element contains an accidental, get all the shapes of the accidental as well
:)
let $accidFacs := if($elem//mei:accid[@facs] and local-name($elem) = ('chord','note'))
                  then(tokenize(string-join($elem//mei:accid/@facs,' '),' '))
                  else()

(:
    get all referenced SVG shapes contained in the source MEI file
    get the (first) page, on which these shapes appear 
:)
let $shapes := $doc//*[concat('#',@id) = $facs]
let $page := ($shapes/ancestor::mei:surface)[1]

(:
    return everything as JSON object 
:)
return
    '{' ||
        '"eventID":"' || $elem.id || '",' ||
        '"eventType":"' || local-name($elem) || '",' ||
        '"facsIDs":[' || (if(count($facs) gt 0) then('"' || string-join(($facs,$chordFacs,$beamFacs,$accidFacs),'","') || '"') else('')) || '],' ||
        '"pageID":"' || $page/@xml:id || '",' ||
        '"pageN":"' || $page/@n || '"' ||
    '}'