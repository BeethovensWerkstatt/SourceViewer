xquery version "3.0";

(:
    queryElement.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'pathID' : id of an svg:path element that has been clicked in the SourceViewer app 
    
    This xQuery is used to identify the MEI element corresponding to an SVG shape that has been clicked
    in the SourceViewer app. The information found is then returned as JSON object string. 
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:START OF PROCESSING:)

let $source.id := request:get-parameter('sourceID','')
let $svg.id := request:get-parameter('pathID','')

(:
    get the MEI document and the base path for XSLTs (which is relative to the path of this xQuery)
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:mei[@xml:id = $source.id]
let $xslPath := '../xslt/'

(:
    generate a JSON object with information about the element to which the specified path belongs
:)
let $result := transform:transform($doc,
               doc(concat($xslPath,'queryElement.xsl')), <parameters><param name="svg.id" value="{$svg.id}"/></parameters>)

return
    $result